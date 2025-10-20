import json
import os
import re
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / "results"
K6_DIR = RESULTS
MEM_DIR = RESULTS / "memory"
IMG_DIR = RESULTS / "images"
OUT_DIR = ROOT / "results" / "plots"
OUT_DIR.mkdir(parents=True, exist_ok=True)

STACKS = ["python", "php", "go", "node"]


def read_k6_summary(name):
    p = K6_DIR / f"{name}.json"
    with open(p, "r") as f:
        data = json.load(f)
    return data


def get_metric(data, key):
    # Try multiple shapes because k6 summary-export formats can vary slightly by version
    m = data.get("metrics", {})
    v = m.get(key, {})
    if isinstance(v, dict):
        # direct helpers
        if "rate" in v:
            return v["rate"]
        for k in ("p(95)", "p(99)", "p95", "p99"):
            if k in v:
                # value in ms
                return v[k]
        # sometimes under "percentiles"
        if "percentiles" in v:
            for k in ("p(95)", "p(99)", "p95", "p99"):
                if k in v["percentiles"]:
                    return v["percentiles"][k]
        # or "values"
        if "values" in v:
            for k in ("p(95)", "p(99)", "p95", "p99"):
                if k in v["values"]:
                    return v["values"][k]
        # avg as fallback
        if "avg" in v:
            return v["avg"]
        if "count" in v:
            return v["count"]
    return None


def compute_rps(data):
    # Prefer http_reqs.rate if available
    rate = get_metric(data, "http_reqs")
    if isinstance(rate, (int, float)) and rate > 0 and rate < 1e6:
        # Often this "rate" is already reqs/s
        return rate
    # Otherwise derive from test duration
    reqs = get_metric(data, "http_reqs")
    if isinstance(reqs, dict) and "count" in reqs:
        count = reqs["count"]
    elif isinstance(reqs, (int, float)):
        count = reqs
    else:
        count = data.get("metrics", {}).get("http_reqs", {}).get("count", 0)
    # duration_ms may be in "duration" metric or from "vus_max" start/stop times, but simpler:
    # We can take scenario "iterations" & total time; k6 summary has "state" sometimes. Fallback to http_req_duration.avg
    dur_ms = get_metric(data, "http_req_duration")
    # dur_ms is avg per request; RPS ~= count / (avg_ms * count / 1000) = 1000/avg_ms
    if isinstance(dur_ms, (int, float)) and dur_ms > 0:
        return 1000.0 / dur_ms
    return None


def read_mem_peak_bytes(name):
    p = MEM_DIR / f"{name}.csv"
    if not p.exists():
        return None
    df = pd.read_csv(p)
    if "mem_used_bytes" not in df.columns:
        return None
    series = pd.to_numeric(df["mem_used_bytes"], errors="coerce")
    if series.empty:
        return None
    peak = series.max(skipna=True)
    if pd.isna(peak):
        return None
    return int(peak)


def read_image_bytes(name):
    p = IMG_DIR / f"{name}.bytes"
    if not p.exists():
        return None
    return int(Path(p).read_text().strip())


def main():
    rows = []
    for name in STACKS:
        k6 = read_k6_summary(name)
        rps = compute_rps(k6)
        p95 = get_metric(k6, "http_req_duration")
        # If get_metric returns a dict or avg, try to pull percentiles explicitly
        if not isinstance(p95, (int, float)):
            p95 = (
                k6.get("metrics", {})
                .get("http_req_duration", {})
                .get("percentiles", {})
                .get("p(95)", None)
            )
        p99 = (
            k6.get("metrics", {})
            .get("http_req_duration", {})
            .get("percentiles", {})
            .get("p(99)", None)
        )

        mem_peak = read_mem_peak_bytes(name)
        img_bytes = read_image_bytes(name)

        rows.append(
            {
                "stack": name,
                "rps": rps,
                "p95_ms": p95,
                "p99_ms": p99,
                "mem_peak_mb": (mem_peak / (1024**2)) if mem_peak is not None else None,
                "image_mb": (img_bytes / (1024**2)) if img_bytes is not None else None,
            }
        )

    df = pd.DataFrame(rows)
    print(df)

    # Plots
    def bar(metric, title, ylabel, filename):
        fig = plt.figure()
        s = df.dropna(subset=[metric]).sort_values(metric, ascending=False)
        if s.empty:
            print(f"Skipping plot {filename}; no values for {metric}")
            plt.close(fig)
            return
        plt.bar(s["stack"], s[metric])
        plt.title(title)
        plt.ylabel(ylabel)
        plt.xlabel("stack")
        for i, v in enumerate(s[metric]):
            if pd.notna(v):
                plt.text(i, v, f"{v:.2f}", ha="center", va="bottom", fontsize=9)
        plt.tight_layout()
        out = OUT_DIR / filename
        fig.savefig(out, dpi=200)
        print(f"Saved {out}")

    bar("rps", "Throughput (requests / second)", "req/s", "throughput.png")
    bar("p95_ms", "Latency P95 (ms)", "ms", "latency_p95.png")
    bar("p99_ms", "Latency P99 (ms)", "ms", "latency_p99.png")
    bar("mem_peak_mb", "Container Memory Peak (MB)", "MB", "memory_peak.png")
    bar("image_mb", "Docker Image Size (MB)", "MB", "image_size.png")


if __name__ == "__main__":
    main()
