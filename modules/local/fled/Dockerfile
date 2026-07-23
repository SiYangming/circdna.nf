FROM python:3.8-slim

RUN apt-get update && apt-get install -y \
    git \
    gcc \
    g++ \
    make \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    pysam==0.19.1 \
    numpy==1.24.3 \
    scipy==1.10.1 \
    matplotlib==3.7.1

RUN git clone https://github.com/zhqingit/FLED.git /opt/fled \
    && cd /opt/fled \
    && python setup.py install

RUN apt-get purge -y gcc g++ make && apt-get autoremove -y

ENV PATH="/opt/fled/bin:${PATH}"

WORKDIR /workdir

CMD ["python", "-c", "import fled; print('FLED installed successfully')"]