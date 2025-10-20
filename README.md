# Small Benchmark Between PHP, Python, NodeJs, Go

Results:

![](imgs/throughput_1.png)

![](imgs/latency_p95_1.png)

![](imgs/memory_peak_1.png)

![](imgs/image_size_1.png)


## Install
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r scripts/requirements.txt
```

## Run
```bash
bash scripts/run.sh
python3 analysis/parse_and_plot.py
```

## Stacks
- Python (FastAPI + Uvicorn)
- PHP (OpenSwoole)
- PHP (FPM + Nginx)
- Go (net/http)
- Node.js (HTTP cluster)

## Results
Go in ./results/ dir
