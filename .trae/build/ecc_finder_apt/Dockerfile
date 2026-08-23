# ---- builder: 编译 Genrich ----
FROM python:3.9-slim-bullseye AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ca-certificates libhts-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch v0.6.1 https://github.com/jsh58/Genrich.git \
 && cd Genrich && make \
 && cp Genrich /usr/local/bin/

# ---- runtime: apt 最小化 ----
FROM python:3.9-slim-bullseye
RUN apt-get update && apt-get install -y --no-install-recommends \
    bwa samtools bedtools seqtk cd-hit fastp g++ python3.9-dev \
 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/bin/Genrich /usr/local/bin/
# TideHunter 预编译二进制（bioconda 1.5.6，避免 simde 子模块克隆失败）
COPY bin/TideHunter /usr/local/bin/TideHunter
RUN chmod +x /usr/local/bin/TideHunter
# 原版脚本依赖 pandas 1.x positional access；py3.9 有 pandas 1.5.3 wheel（numpy 固定 <2 兼容）
RUN pip install --no-cache-dir cython \
 && pip install --no-cache-dir \
    numpy==1.26.4 pandas==1.5.3 matplotlib scipy biopython pybedtools
COPY ecc_finder/ /app/
RUN chmod +x /app/*.py
ENV PATH="/app:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
WORKDIR /data
