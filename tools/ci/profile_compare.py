#!/usr/bin/env python3
import csv
import os
import statistics

BASELINE = "tools/ci/baseline_profile.csv"
INPUTS = [f"startup-{i}.csv" for i in range(1, 6)]
OUTPUT = "pr-comment.md"
REPOSITORY = os.environ["GITHUB_REPOSITORY"]
RUN_ID = os.environ["GITHUB_RUN_ID"]

REGRESSION_ABS_NS = 5_000_000
REGRESSION_PCT = 5.0
COMMENT_MARKER = "<!-- tracy-profile-comment -->"

baseline = {}
with open(BASELINE, newline="") as f:
    for row in csv.DictReader(f):
        baseline[row["name"]] = float(row["total_ns"])

values = {}
for path in INPUTS:
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            values.setdefault(row["name"], []).append(float(row["total_ns"]))

medians = {name: statistics.median(vals) for name, vals in values.items()}

baseline_total = sum(baseline.values())
new_total = sum(medians.values())
total_delta = new_total - baseline_total
total_pct = (total_delta / baseline_total) * 100 if baseline_total else 0

regressions = []
for name, median in medians.items():
    if name not in baseline:
        continue
    delta = median - baseline[name]
    pct = (delta / baseline[name]) * 100 if baseline[name] else 0
    if abs(delta) >= REGRESSION_ABS_NS and pct >= REGRESSION_PCT:
        regressions.append((name, baseline[name], median, delta, pct))

regressions.sort(key=lambda r: r[3], reverse=True)

lines = [
    COMMENT_MARKER,
    "## Startup Profile",
    f"**Total startup delta: {total_delta/1e6:+.0f}ms ({total_pct:+.1f}% vs baseline)**\n",
]

if regressions:
    lines += [
        f"### Regressions (> {REGRESSION_ABS_NS // 1_000_000}ms and > {REGRESSION_PCT:.0f}%)",
        "| Zone | Baseline | New | Delta | Change |",
        "|------|----------|-----|-------|--------|",
    ]
    for name, base, new, delta, pct in regressions:
        lines.append(
            f"| `{name}` | {base/1e6:.1f}ms | {new/1e6:.1f}ms"
            f" | {delta/1e6:+.1f}ms | {pct:+.1f}% |"
        )
else:
    lines.append(":white_check_mark: No significant regressions detected.")

artifact_url = f"https://github.com/{REPOSITORY}/actions/runs/{RUN_ID}"
lines.append(f"\n_Full breakdown available in the [workflow artifact]({artifact_url})._")

with open(OUTPUT, "w") as f:
    f.write("\n".join(lines) + "\n")
