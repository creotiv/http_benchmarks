from fastapi import FastAPI
from fastapi.responses import PlainTextResponse

app = FastAPI()


@app.get("/")
async def hello():
    return PlainTextResponse("Hello, world")
