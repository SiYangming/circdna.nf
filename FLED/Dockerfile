# FLED - a full-length eccDNA detector for long-reads sequencing data
# Build as linux/amd64 (x86_64). On Apple Silicon hosts, build with:
#   docker buildx build --platform linux/amd64 -t quay.io/bioinfortools/fled:1.7.0 .
#
# ========== Stage 1: Builder ==========
# Python 3.8 slim (FLED pins scipy==1.5.3 / biopython==1.76 / pysam==0.22 which
# require python <3.10). Pulled via a CN mirror for faster builds in China.
FROM --platform=linux/amd64 docker.1ms.run/library/python:3.8-slim-bookworm AS builder

# Install FLED Python dependencies into an isolated prefix (all ship manylinux
# wheels, no compilation needed). Use the Tsinghua PyPI mirror for CN networks.
RUN pip install --no-cache-dir --prefix=/install \
        --index-url https://pypi.tuna.tsinghua.edu.cn/simple \
        pysam==0.22 \
        networkx==2.5 \
        progressbar2 \
        biopython==1.76 \
        numpy==1.19.5 \
        pyspoa==0.0.6 \
        scipy==1.5.3 \
        tqdm

# ========== Stage 2: Final runtime ==========
FROM --platform=linux/amd64 docker.1ms.run/library/python:3.8-slim-bookworm

# FLED needs minimap2 / samtools / bedtools / seqtk plus shared libs.
# Use the aliyun Debian mirror for faster apt in CN.
RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g; s|security.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        minimap2 \
        samtools \
        bedtools \
        seqtk \
        procps \
        libcurl4 \
        libssl3 \
        zlib1g \
        libbz2-1.0 \
        liblzma5 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy the Python packages installed in the builder stage
COPY --from=builder /install /usr/local

# Install FLED from local source
WORKDIR /opt/FLED
COPY . .
RUN pip install --no-cache-dir --no-deps --index-url https://pypi.tuna.tsinghua.edu.cn/simple .

ENV PATH="/usr/local/bin:${PATH}" \
    LC_ALL=C

# Verify FLED CLI and required tools (kept as a separate layer so the final
# image can still be built if a smoke test fails during development)
RUN FLED 2>&1 | head -6; \
    minimap2 --version | head -1; \
    samtools --version | head -1; \
    bedtools --version; \
    seqtk 2>&1 | head -1

LABEL org.opencontainers.image.source="https://github.com/FuyuLi/FLED" \
      org.opencontainers.image.version="1.7.0" \
      org.opencontainers.image.title="FLED" \
      org.opencontainers.image.description="Full-Length eccDNA Detection (apt minimal multi-stage)"

WORKDIR /opt/data
