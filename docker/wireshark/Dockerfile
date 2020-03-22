ARG DEBIAN_RELEASE=bullseye
ARG WIRESHARK_VERSION=3.2.2

# Build Wireshark
FROM debian:${DEBIAN_RELEASE} as wireshark-build

ADD https://raw.githubusercontent.com/wireshark/wireshark/master/tools/debian-setup.sh /
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install gnupg apt-utils ca-certificates -y \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& chmod +x debian-setup.sh \
	&& ./debian-setup.sh -y --install-optional --install-deb-deps --install-test-deps \
		python3-pytest-xdist doxygen locales \
        gcc-9 g++-9 clang-9 \
    && apt-get autoremove -y \
    && apt-get clean -y \
	&& rm -rf /var/lib/apt/lists/
ENV DEBIAN_FRONTEND=dialog

RUN cd /root && git clone https://github.com/wireshark/wireshark.git
ARG WIRESHARK_VERSION
RUN cd /root/wireshark \
	&& git pull \
	&& git checkout wireshark-${WIRESHARK_VERSION}
RUN cd /root/wireshark \
	&& dpkg-buildpackage -us -uc -rfakeroot

# Create Base Image
FROM debian:${DEBIAN_RELEASE}-slim as base

# Install tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install gnupg apt-utils ca-certificates -y \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get -y install procps vim less expect jq net-tools dnsutils telnet netcat curl wget httpie \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Install pid1 init daemon
ARG PID1_VERSION=0.1.2.0
RUN curl -L https://github.com/fpco/pid1/releases/download/v${PID1_VERSION}/pid1-${PID1_VERSION}-linux-x86_64.tar.gz | tar xz -C /usr/local

# Set up pid1 entrypoint and default command
ENTRYPOINT ["/usr/local/sbin/pid1"]
CMD ["/bin/bash"]

# Set workdir
WORKDIR /root

# Create wireshark base image
FROM base as wireshark-base

# Set Git related labels
ARG SOURCE_GIT_REPOSITORY
ARG SOURCE_GIT_COMMIT
ARG README_URL
LABEL source.git.repository=${SOURCE_GIT_REPOSITORY} \
      source.git.commit=${SOURCE_GIT_COMMIT} \
      readme.url=${README_URL}

# Set tools related labels
ARG DEBIAN_RELEASE
ARG WIRESHARK_VERSION
LABEL debian.release=${DEBIAN_RELEASE} \
	  wireshark.version=${WIRESHARK_VERSION}

# Set Docker image version labes
LABEL docker.image.version=${WIRESHARK_VERSION}-${DEBIAN_RELEASE}

# Create tshark image
FROM wireshark-base as tshark

ARG WIRESHARK_VERSION
COPY --from=wireshark-build \
	/root/libwsutil11_${WIRESHARK_VERSION}_amd64.deb \
	/root/libwiretap10_${WIRESHARK_VERSION}_amd64.deb \
	/root/libwireshark-data_${WIRESHARK_VERSION}_all.deb \
	/root/libwireshark13_${WIRESHARK_VERSION}_amd64.deb \
	/root/wireshark-common_${WIRESHARK_VERSION}_amd64.deb \
	/root/tshark_${WIRESHARK_VERSION}_amd64.deb \
	/root/

# Install tshark
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y libglib2.0-0 libpcap0.8 \
		libc-ares2 liblua5.2-0 libsmi2ldbl libsnappy1v5 \
		libcap2 libnl-3-200 libnl-genl-3-200 libssh-gcrypt-4 libcap2-bin \
	&& dpkg -i /root/libwsutil11_${WIRESHARK_VERSION}_amd64.deb \
	&& dpkg -i /root/libwiretap10_${WIRESHARK_VERSION}_amd64.deb \
	&& dpkg -i /root/libwireshark-data_${WIRESHARK_VERSION}_all.deb \
	&& dpkg -i /root/libwireshark13_${WIRESHARK_VERSION}_amd64.deb \
	&& dpkg -i /root/wireshark-common_${WIRESHARK_VERSION}_amd64.deb \
	&& dpkg -i /root/tshark_${WIRESHARK_VERSION}_amd64.deb \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
	&& rm -f /root/*.deb
ENV DEBIAN_FRONTEND=dialog

# Create wireshark image
FROM tshark as wireshark

ARG WIRESHARK_VERSION
COPY --from=wireshark-build \
	/root/wireshark-qt_${WIRESHARK_VERSION}_amd64.deb \
	/root/wireshark_${WIRESHARK_VERSION}_amd64.deb \
	/root/

# Install wireshark
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y libminizip1 libnl-route-3-200 libqt5core5a libqt5gui5 libqt5multimedia5 libqt5printsupport5 libqt5widgets5 libspeexdsp1 \
	&& dpkg -i /root/wireshark-qt_${WIRESHARK_VERSION}_amd64.deb \
	&& dpkg -i /root/wireshark_${WIRESHARK_VERSION}_amd64.deb \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
	&& rm -f /root/*.deb
ENV DEBIAN_FRONTEND=dialog