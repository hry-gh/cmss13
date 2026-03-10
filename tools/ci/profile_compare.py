#!/usr/bin/env python3
import csv
import math
import os
import statistics

BASE_INPUTS = [f"base-{i}.csv" for i in range(1, 6)]
PR_INPUTS   = [f"pr-{i}.csv"   for i in range(1, 6)]
OUTPUT      = "pr-comment.md"
REPOSITORY  = os.environ["GITHUB_REPOSITORY"]
RUN_ID      = os.environ["GITHUB_RUN_ID"]

REGRESSION_ABS_NS = 5_000_000
COMMENT_MARKER    = "<!-- tracy-profile-comment -->"

# One-tailed paired t critical values for p=0.05, indexed by degrees of freedom
T_CRITICAL = {
    1: 6.314, 2: 2.920, 3: 2.353, 4: 2.132,
    5: 2.015, 6: 1.943, 7: 1.895, 8: 1.860,
    9: 1.833, 10: 1.812,
}


def read_csv(path):
    with open(path, newline="") as f:
        return {row["name"]: float(row["total_ns"]) for row in csv.DictReader(f)}


def paired_t_test(base_vals, pr_vals):
    """One-tailed paired t-test: is PR significantly slower than base at p=0.05?"""
    diffs = [p - b for b, p in zip(base_vals, pr_vals)]
    n = len(diffs)
    if n < 2:
        return False
    mean_diff = statistics.mean(diffs)
    sd_diff = statistics.stdev(diffs)
    if sd_diff == 0:
        return mean_diff > 0
    t_stat = mean_diff / (sd_diff / math.sqrt(n))
    df = min(n - 1, max(T_CRITICAL.keys()))
    return t_stat > T_CRITICAL.get(df, 1.645)


base_runs = [read_csv(p) for p in BASE_INPUTS]
pr_runs   = [read_csv(p) for p in PR_INPUTS]

all_zones = set().union(*[r.keys() for r in pr_runs])

base_total = sum(statistics.median(r.get(z, 0) for r in base_runs) for z in all_zones)
pr_total   = sum(statistics.median(r.get(z, 0) for r in pr_runs)   for z in all_zones)
total_delta = pr_total - base_total
total_pct   = (total_delta / base_total) * 100 if base_total else 0

regressions = []

for zone in all_zones:
    base_vals = [r.get(zone, 0) for r in base_runs]
    pr_vals   = [r.get(zone, 0) for r in pr_runs]

    base_median = statistics.median(base_vals)
    pr_median   = statistics.median(pr_vals)
    delta       = pr_median - base_median
    pct         = (delta / base_median) * 100 if base_median else 0

    if abs(delta) < REGRESSION_ABS_NS:
        continue

    if not paired_t_test(base_vals, pr_vals):
        continue

    regressions.append((zone, base_median, pr_median, delta, pct))

regressions.sort(key=lambda r: r[3], reverse=True)

lines = [
    COMMENT_MARKER,
    "## Startup Profile",
    f"**Total startup delta: {total_delta/1e6:+.0f}ms ({total_pct:+.1f}% vs base)**\n",
]

if regressions:
    lines += [
        f"### Regressions (> {REGRESSION_ABS_NS // 1_000_000}ms, paired t-test p < 0.05)",
        "| Zone | Base | PR | Delta | Change |",
        "|------|------|----|-------|--------|",
    ]
    for zone, base, pr, delta, pct in regressions:
        lines.append(
            f"| `{zone}` | {base/1e6:.1f}ms | {pr/1e6:.1f}ms"
            f" | {delta/1e6:+.1f}ms | {pct:+.1f}% |"
        )
else:
    lines.append(":white_check_mark: No significant regressions detected.")

artifact_url = f"https://github.com/{REPOSITORY}/actions/runs/{RUN_ID}"
lines.append(f"\n_Full breakdown available in the [workflow artifact]({artifact_url})._")

with open(OUTPUT, "w") as f:
    f.write("\n".join(lines) + "\n")
