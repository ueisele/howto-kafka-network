FROM debian:stretch-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    # Install tools
    && apt-get -y install --no-install-recommends \
        curl wget netcat httpie telnet dnsutils net-tools ca-certificates procps vim less expect jq \
    && apt-get install tshark \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Install Termshark
ARG TERMSHARK_VERSION=2.1.1
RUN curl -L https://github.com/gcla/termshark/releases/download/v${TERMSHARK_VERSION}/termshark_${TERMSHARK_VERSION}_linux_x64.tar.gz | tar -xz --strip-components=1 -C /usr/local/bin

# Install pid1 init daemon
ARG PID1_VERSION=0.1.2.0
RUN curl -L https://github.com/fpco/pid1/releases/download/v${PID1_VERSION}/pid1-${PID1_VERSION}-linux-x86_64.tar.gz | tar xz -C /usr/local

# Set up pid1 entrypoint and default command
ENTRYPOINT ["/usr/local/sbin/pid1"]
CMD ["/bin/bash"]

# Set workdir
WORKDIR /root