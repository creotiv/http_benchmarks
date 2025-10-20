FROM python:3.14-alpine

# Smaller image, no cache
RUN pip install --no-cache-dir fastapi uvicorn

WORKDIR /app
COPY app.py /app/app.py

EXPOSE 8000
# Single worker to keep things apples-to-apples; you can tweak if you want
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4", "--no-access-log"]
