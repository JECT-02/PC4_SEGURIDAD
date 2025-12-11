FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools and build dependencies for hashpump
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-requests curl jq ca-certificates \
    git g++ make libssl-dev python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Compile hashpump from 2H-K/hashpumpy_changed repo
RUN git clone https://github.com/2H-K/hashpumpy_changed.git /tmp/hashpumpy \
    && cd /tmp/hashpumpy \
    && make \
    && make install \
    && ldconfig \
    && pip install . \
    && rm -rf /tmp/hashpumpy

WORKDIR /attack
COPY attack.sh .
RUN chmod +x attack.sh

ENTRYPOINT ["./attack.sh"]
