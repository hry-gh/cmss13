#!/usr/bin/env bash
# profile-startup.sh
# Profiles DreamDaemon startup using byond-tracy + Tracy capture tools.
# Usage: ./profile-startup.sh [output.csv]
#
# Expects the following to be on PATH or in the working directory:
#   - tracy-capture   (from Tracy releases)
#   - tracy-csvexport (from Tracy releases)
#   - DreamDaemon     (from BYOND install, sourced via byondsetup)
#
# libprof.so (byond-tracy) must be present next to the DMB. The DM code calls
# its init() proc, which connects outward to tracy-capture on TRACY_PORT.
# tracy-capture must therefore be started first as the listening server.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

OUTPUT_CSV="${1:-startup.csv}"
OUTPUT_TRACY="startup.tracy"

TRACY_PORT="${TRACY_PORT:-8086}"
DD_TIMEOUT="${DD_TIMEOUT:-600}"  # Max seconds to wait for DreamDaemon exit
TRACY_SETTLE_SECONDS=2           # Grace period after DD exits before killing capture

# Locate the DMB — find the first .dmb in the repo root
DMB="${DMB_PATH:-$(find . -maxdepth 1 -name "*.dmb" | head -n1)}"
if [[ -z "$DMB" || ! -f "$DMB" ]]; then
    echo "ERROR: No .dmb found in working directory — set DMB_PATH explicitly if needed." >&2
    exit 1
fi
echo "==> Using DMB: $DMB"

# Resolve tool paths — prefer local directory, then PATH
_find_tool() {
    if [[ -x "./$1" ]]; then echo "./$1"; elif command -v "$1" &>/dev/null; then echo "$1"; else
        echo "ERROR: '$1' not found in working directory or PATH" >&2; exit 1
    fi
}
TRACY_CAPTURE="$(_find_tool tracy-capture)"
TRACY_CSVEXPORT="$(_find_tool tracy-csvexport)"
DREAM_DAEMON="$(_find_tool DreamDaemon)"

# libprof.so must sit next to the DMB so BYOND can find it when the DM code
# calls its init() proc.
BYOND_TRACY_LIB="${BYOND_TRACY_LIB:-./libprof.so}"
if [[ ! -f "$BYOND_TRACY_LIB" ]]; then
    echo "ERROR: byond-tracy library not found at '$BYOND_TRACY_LIB'" >&2
    echo "       Set BYOND_TRACY_LIB env var or place libprof.so in the working directory." >&2
    exit 1
fi
DMB_DIR="$(dirname "$(realpath "$DMB")")"
BYOND_TRACY_LIB="$(realpath "$BYOND_TRACY_LIB")"
if [[ "$(dirname "$BYOND_TRACY_LIB")" != "$DMB_DIR" ]]; then
    echo "==> Copying libprof.so next to DMB ($DMB_DIR)..."
    cp "$BYOND_TRACY_LIB" "$DMB_DIR/libprof.so"
    BYOND_TRACY_LIB="$DMB_DIR/libprof.so"
fi

# ---------------------------------------------------------------------------
# Cleanup trap — ensures no orphaned processes on exit/failure
# ---------------------------------------------------------------------------

TRACY_PID=""
DD_PID=""

cleanup() {
    local exit_code=$?
    echo "--- cleanup (exit $exit_code) ---"
    if [[ -n "$DD_PID" ]] && kill -0 "$DD_PID" 2>/dev/null; then
        echo "Killing DreamDaemon (pid $DD_PID)..."
        kill "$DD_PID" 2>/dev/null || true
    fi
    if [[ -n "$TRACY_PID" ]] && kill -0 "$TRACY_PID" 2>/dev/null; then
        echo "Killing tracy-capture (pid $TRACY_PID)..."
        kill "$TRACY_PID" 2>/dev/null || true
    fi
    exit "$exit_code"
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# Step 1: Start tracy-capture first
#
# tracy-capture listens on TRACY_PORT. byond-tracy (loaded by BYOND via the
# DM code's init() call) acts as the client and connects outward to it.
# ---------------------------------------------------------------------------

echo "==> Starting tracy-capture loop (output: $OUTPUT_TRACY)..."
# byond-tracy is the server; tracy-capture is the client. It will exit and
# reconnect until it captures the full session once byond-tracy is ready.
(
    "$TRACY_CAPTURE" -o "$OUTPUT_TRACY" -f -a 127.0.0.1 -p "$TRACY_PORT" 2>/dev/null || true
    "$TRACY_CAPTURE" -o "$OUTPUT_TRACY" -f -a 127.0.0.1 -p "$TRACY_PORT" 2>/dev/null || true
) &
TRACY_PID=$!
echo "    tracy-capture loop pid: $TRACY_PID"

# ---------------------------------------------------------------------------
# Step 2: Start DreamDaemon
#
# When DM code calls byond-tracy's init(), it connects to tracy-capture.
#
# -trusted    — required for proc/process access in many codebases
# -invisible  — no window; safe for headless CI
# ---------------------------------------------------------------------------

echo "==> Starting DreamDaemon ($DMB)..."
"$DREAM_DAEMON" "$DMB" \
    -trusted \
    -invisible \
    &
DD_PID=$!
echo "    DreamDaemon pid: $DD_PID"

# ---------------------------------------------------------------------------
# Step 3: Wait for DreamDaemon to exit
# -DTRACY_PROFILE_AND_EXIT causes the gamecode to call del(world) once
# initialisation completes, so this should be a clean, prompt exit.
# ---------------------------------------------------------------------------

echo "==> Waiting for DreamDaemon to exit (timeout: ${DD_TIMEOUT}s)..."

elapsed=0
while kill -0 "$DD_PID" 2>/dev/null; do
    sleep 1
    elapsed=$((elapsed + 1))
    if (( elapsed >= DD_TIMEOUT )); then
        echo "ERROR: DreamDaemon did not exit within ${DD_TIMEOUT}s — killing." >&2
        kill "$DD_PID"
        exit 1
    fi
done

wait "$DD_PID" || true
DD_EXIT=$?
DD_PID=""

if [[ $DD_EXIT -eq 139 ]]; then
    echo "    DreamDaemon exited with segfault (expected when byond-tracy is attached)."
elif [[ $DD_EXIT -ne 0 ]]; then
    echo "    DreamDaemon exited with code $DD_EXIT."
fi
echo "    DreamDaemon exited (code $DD_EXIT) after ${elapsed}s."

# ---------------------------------------------------------------------------
# Step 4: Allow tracy-capture to finish flushing, then stop it
# ---------------------------------------------------------------------------

echo "==> Waiting ${TRACY_SETTLE_SECONDS}s for tracy-capture to flush..."
sleep "$TRACY_SETTLE_SECONDS"

if kill -0 "$TRACY_PID" 2>/dev/null; then
    echo "    Signalling tracy-capture to stop..."
    kill -TERM "$TRACY_PID" 2>/dev/null || true
fi

wait "$TRACY_PID" 2>/dev/null || true
TRACY_PID=""

if [[ ! -f "$OUTPUT_TRACY" ]]; then
    echo "ERROR: Expected Tracy capture file '$OUTPUT_TRACY' was not created." >&2
    exit 1
fi

echo "    Capture file: $OUTPUT_TRACY ($(du -sh "$OUTPUT_TRACY" | cut -f1))"

# ---------------------------------------------------------------------------
# Step 5: Export CSV
# ---------------------------------------------------------------------------

echo "==> Exporting CSV..."
"$TRACY_CSVEXPORT" "$OUTPUT_TRACY" > "$OUTPUT_CSV"

echo "==> Done. CSV written to: $OUTPUT_CSV"
echo ""

# Print a brief summary to stdout for easy CI log scanning
echo "--- Zone timing summary (top 20 by total time) ---"
# CSV columns: Name, src_file, src_line, total_ns, count, mean_ns, min_ns, max_ns, std_ns
# Sort by total_ns descending, skip header, take top 20
if command -v awk &>/dev/null; then
    awk -F',' 'NR==1 { print; next } { print | "sort -t, -k4 -rn" }' "$OUTPUT_CSV" \
        | head -n 21 \
        | awk -F',' 'NR==1 { printf "%-60s %12s %8s %12s\n", "Zone", "Total(ms)", "Count", "Mean(µs)" }
                     NR>1  { printf "%-60s %12.3f %8s %12.3f\n", $1, $4/1e6, $5, $6/1e3 }'
fi
