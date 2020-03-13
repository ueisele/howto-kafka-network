FROM debian:strech-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    # Install tools
    && apt-get -y install --no-install-recommends \
        curl wget httpie telnet dnsutils net-tools ca-certificates procps vim less expect jq git bash-completion \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog
