from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

ITERATIONS = 20
MODULUS = 1_000_003

app = FastAPI()


def cpu_work(iterations: int = ITERATIONS) -> int:
    acc = 0
    for i in range(iterations):
        value = i
        for j in range(iterations):
            value = (value * 31 + j) % MODULUS
        acc = (acc + value) % MODULUS
    return acc


@app.get("/")
async def hello():
    result = cpu_work()
    return PlainTextResponse(f"Hello, world {result}")
