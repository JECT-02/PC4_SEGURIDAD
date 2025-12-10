FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Update and install tools. 
# Note: hashpump might not be in standard 22.04 repo by default or package name varies.
# Adding universe just in case, or we rely on the prompt's assumption "apt install hashpump".
# If it fails, instructions suggest pip install hashpumpy.
RUN apt-get update && apt-get install -y \
    python3 python3-pip curl jq ca-certificates hashpump \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /attack
COPY attack.sh .
RUN chmod +x attack.sh

ENTRYPOINT ["./attack.sh"]
