#!/usr/bin/env bash
set -euo pipefail

CONTAINER="$1"
OUTFILE="$2"
INTERVAL="${3:-0.25}"  # seconds

# Poll docker stats until K6 exits (we detect by parent PID env pass), or until container stops.
# For simplicity, we run this alongside the k6 process and kill it after k6 exits.
echo "timestamp,mem_used_bytes" > "$OUTFILE"
while true; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    break
  fi
  line="$(docker stats --no-stream --format '{{.MemUsage}}' "$CONTAINER" || true)"
  # Ex: "84.5MiB / 7.716GiB"
  used="$(echo "$line" | awk -F'/' '{print $1}' | xargs)"
  if [ -n "$used" ]; then
    # normalize
    used_bytes=$(bash "$(dirname "$0")/_utils.sh" h2b "$used")
    echo "$(date +%s),$used_bytes" >> "$OUTFILE"
  fi
  sleep "$INTERVAL"
done
