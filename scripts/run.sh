#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K6_SUMMARY_DIR="$ROOT/results"
MEM_DIR="$ROOT/results/memory"
IMG_DIR="$ROOT/results/images"

mkdir -p "$K6_SUMMARY_DIR" "$MEM_DIR" "$IMG_DIR"

wait_for_http() {
  local name="$1" url="$2" attempts="${3:-60}" delay="${4:-1}" required="${5:-3}"
  local consecutive=0
  echo "==> Waiting for ${name} at ${url}"
  for ((i = 1; i <= attempts; i++)); do
    if curl -sSf -o /dev/null --connect-timeout 2 --max-time 2 "$url"; then
      consecutive=$((consecutive + 1))
      if (( consecutive >= required )); then
        echo "==> ${name} ready (attempt ${i})"
        return 0
      fi
    else
      consecutive=0
    fi
    sleep "$delay"
  done
  echo "!! ${name} did not become ready after $((attempts * delay))s" >&2
  return 1
}

# 1) Build images
echo "==> Building images"
docker build -t bench-python:latest "$ROOT/python"
docker build -t bench-python-jit:latest "$ROOT/python-jit"
docker build -t bench-php-openswoole:latest "$ROOT/php"
docker build -t bench-php-fpm:latest "$ROOT/php-fpm"
docker build -t bench-go:latest "$ROOT/go"
docker build -t bench-node:latest "$ROOT/node"

# 2) Run containers (detached)
echo "==> Starting containers"
# Python -> localhost:18081
docker rm -f bench-python >/dev/null 2>&1 || true
docker run -d --cpuset-cpus="0-3" --name bench-python -p 18081:8000 bench-python:latest

# PHP OpenSwoole -> localhost:18082
docker rm -f bench-php >/dev/null 2>&1 || true
docker run -d --cpuset-cpus="0-3" --name bench-php -p 18082:9501 bench-php-openswoole:latest

# PHP FPM + Nginx -> localhost:18085
docker rm -f bench-php-fpm >/dev/null 2>&1 || true
docker run -d --cpuset-cpus="0-3" --name bench-php-fpm -p 18085:8080 bench-php-fpm:latest

# Go -> localhost:18083
docker rm -f bench-go >/dev/null 2>&1 || true
docker run -d --cpuset-cpus="0-3" --name bench-go -p 18083:8080 bench-go:latest

# Node -> 18084
docker rm -f bench-node >/dev/null 2>&1 || true
docker run -d --cpuset-cpus="0-3" -e WORKERS=4 --name bench-node -p 18084:3000 bench-node:latest

# Python -> localhost:18086
docker rm -f bench-python-jit >/dev/null 2>&1 || true
docker run -d --cpuset-cpus="0-3" --name bench-python-jit -p 18086:8000 bench-python-jit:latest

# 3) Image sizes
echo "==> Capturing image sizes"
docker image inspect bench-python:latest --format='{{.Size}}' > "$IMG_DIR/python.bytes"
docker image inspect bench-python-jit:latest --format='{{.Size}}' > "$IMG_DIR/python-jit.bytes"
docker image inspect bench-php-openswoole:latest --format='{{.Size}}' > "$IMG_DIR/php.bytes"
docker image inspect bench-php-fpm:latest --format='{{.Size}}' > "$IMG_DIR/php-fpm.bytes"
docker image inspect bench-go:latest --format='{{.Size}}' > "$IMG_DIR/go.bytes"
docker image inspect bench-node:latest --format='{{.Size}}' > "$IMG_DIR/node.bytes"

# 4) Run K6 for each target. Requires k6 installed locally.
#    We export a summary to JSON and concurrently monitor memory usage.
run_one() {
  local name="$1" port="$2"
  local url="http://localhost:${port}/"
  local memfile="$MEM_DIR/${name}.csv"
  local summary="$K6_SUMMARY_DIR/${name}.json"

  echo "==> Testing ${name} at ${url}"
  wait_for_http "bench-${name}" "$url"
  for warm in {1..5}; do
    if ! curl -sSf -o /dev/null --connect-timeout 2 --max-time 2 "$url"; then
      echo "!! Warm-up request ${warm} to ${url} failed" >&2
    fi
    sleep 0.2
  done
  sleep 1
  # start memory monitor
  bash "$ROOT/scripts/_memory_monitor.sh" "bench-${name}" "$memfile" 0.25 &
  local mon_pid=$!

  # run k6
  BASE_URL="$url" k6 run \
    --summary-export "$summary" \
    "$ROOT/tests/multi-req.js"

  # stop monitor
  kill "$mon_pid" 2>/dev/null || true
  wait "$mon_pid" 2>/dev/null || true
}

run_one "python"       "18081"
run_one "php"          "18082"
run_one "php-fpm"      "18085"
run_one "go"           "18083"
run_one "node"         "18084"
run_one "python-jit"   "18086"

echo "==> Done. Results in: $K6_SUMMARY_DIR and $MEM_DIR and $IMG_DIR"
echo "==> Next: python3 analysis/parse_and_plot.py"
