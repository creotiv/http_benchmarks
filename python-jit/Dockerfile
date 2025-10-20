FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y \
    build-essential curl ca-certificates git wget \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev xz-utils tk-dev uuid-runtime python3 gnupg && \
    rm -rf /var/lib/apt/lists/*

ENV RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo \
    PATH="/opt/rust/cargo/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --profile minimal --default-toolchain stable && \
    rustup target add aarch64-unknown-linux-gnu

RUN mkdir -p /usr/share/keyrings && \
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor | tee /usr/share/keyrings/llvm-archive-keyring.gpg >/dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-19 main" > /etc/apt/sources.list.d/llvm-toolchain.list && \
    apt-get update && apt-get install -y clang-19 lld-19 && \
    rm -rf /var/lib/apt/lists/*

ARG PYVER=3.14.0
WORKDIR /src
RUN curl -fsSLO https://www.python.org/ftp/python/${PYVER}/Python-${PYVER}.tgz && \
    tar -xzf Python-${PYVER}.tgz && cd Python-${PYVER} && \
    ./configure --prefix=/opt/python \
                --enable-experimental-jit \
                --enable-optimizations --with-lto && \
    make -j$(nproc) && make install

FROM debian:bookworm-slim
ENV RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo \
    PATH="/opt/python/bin:/opt/rust/cargo/bin:${PATH}"
COPY --from=build /opt/python /opt/python
COPY --from=build /opt/rust /opt/rust

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libssl3 build-essential && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY app.py /app/app.py
RUN pip3 install --no-cache-dir "fastapi[standard]"
EXPOSE 8000
# Enable the JIT at runtime:
ENV PYTHON_JIT=1
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4", "--no-access-log"]
