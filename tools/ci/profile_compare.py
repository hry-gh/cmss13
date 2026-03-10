#!/usr/bin/env python3
import csv
import math
import os
import statistics

BASELINE   = "tools/ci/baseline_profile.csv"
INPUTS     = [f"startup-{i}.csv" for i in range(1, 6)]
OUTPUT     = "pr-comment.md"
REPOSITORY = os.environ["GITHUB_REPOSITORY"]
RUN_ID     = os.environ["GITHUB_RUN_ID"]

REGRESSION_ABS_NS = 5_000_000
COMMENT_MARKER    = "<!-- tracy-profile-comment -->"

T_CRITICAL = {
    1: 6.314, 2: 2.920, 3: 2.353, 4: 2.132,
    5: 2.015, 6: 1.943, 7: 1.895, 8: 1.860,
    9: 1.833, 10: 1.812,
}


def remove_outliers(vals):
    if len(vals) < 4:
        return vals
    q1 = statistics.quantiles(vals, n=4)[0]
    q3 = statistics.quantiles(vals, n=4)[2]
    iqr = q3 - q1
    lo, hi = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    filtered = [v for v in vals if lo <= v <= hi]
    return filtered if filtered else vals


def one_sided_t_test(vals, baseline_val):
    n = len(vals)
    if n < 2:
        return False
    mean = statistics.mean(vals)
    sd = statistics.stdev(vals)
    if sd == 0:
        return mean > baseline_val
    t_stat = (mean - baseline_val) / (sd / math.sqrt(n))
    df = min(n - 1, max(T_CRITICAL.keys()))
    return t_stat > T_CRITICAL.get(df, 1.645)


baseline = {}
with open(BASELINE, newline="") as f:
    for row in csv.DictReader(f):
        baseline[row["name"]] = float(row["total_ns"])

values = {}
for path in INPUTS:
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            values.setdefault(row["name"], []).append(float(row["total_ns"]))

baseline_total = sum(baseline.values())
new_total = 0
regressions = []

for name, vals in values.items():
    clean = remove_outliers(vals)
    median = statistics.median(clean)
    new_total += median

    if name not in baseline:
        continue

    delta = median - baseline[name]
    pct = (delta / baseline[name]) * 100 if baseline[name] else 0

    if abs(delta) < REGRESSION_ABS_NS:
        continue

    if not one_sided_t_test(clean, baseline[name]):
        continue

    regressions.append((name, baseline[name], median, delta, pct))

regressions.sort(key=lambda r: r[3], reverse=True)

total_delta = new_total - baseline_total
total_pct = (total_delta / baseline_total) * 100 if baseline_total else 0

lines = [
    COMMENT_MARKER,
    "## Startup Profile",
    f"**Total startup delta: {total_delta/1e6:+.0f}ms ({total_pct:+.1f}% vs baseline)**\n",
]

if regressions:
    lines += [
        f"### Regressions (> {REGRESSION_ABS_NS // 1_000_000}ms, p < 0.05)",
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
