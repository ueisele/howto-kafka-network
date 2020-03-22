ARG DEBIAN_RELEASE=bullseye
ARG WIRESHARK_VERSION=3.2.2

## Build Wireshark ##
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
	&& dpkg-buildpackage -us -uc -rfakeroot \
	&& git clean -Xdf


## Create Base Image ##
FROM debian:${DEBIAN_RELEASE}-slim as net-tools

# Install tools
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install gnupg apt-utils ca-certificates locales -y \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get -y install procps vim neovim less expect jq net-tools iproute2 nftables iputils-ping iputils-tracepath iputils-arping \
		telnet dnsutils netcat socat tcpdump curl wget httpie \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
ARG LOCALE=de_DE
RUN sed -i -e "s/# *${LOCALE}.UTF-8 UTF-8/${LOCALE}.UTF-8 UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=${LOCALE}.UTF-8
ENV LANG ${LOCALE}.UTF-8
ENV DEBIAN_FRONTEND=dialog

# Install pid1 init daemon
ARG PID1_VERSION=0.1.2.0
RUN curl -L https://github.com/fpco/pid1/releases/download/v${PID1_VERSION}/pid1-${PID1_VERSION}-linux-x86_64.tar.gz | tar xz -C /usr/local

# Set up pid1 entrypoint and default command
COPY entrypoint.sh /entrypoint.sh
ENV ENTRYPOINT_EXEC_CMD /usr/local/sbin/pid1
ENTRYPOINT ["/entrypoint.sh"]
ENV ENTRYPOINT_DEFAULT_CMD /bin/bash
CMD ["/bin/bash"]

# Add permissions to run network tools as non root user
RUN setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/sbin/tcpdump
RUN setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/sbin/nft
RUN setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /sbin/tc

# Add user
RUN useradd -m -s /bin/bash -d /home/debian -u 1000 -U debian
USER debian

# Set workdir
WORKDIR /home/debian

# Set tools related labels
ARG DEBIAN_RELEASE
LABEL debian.release=${DEBIAN_RELEASE}


## Create Tshark Image ##
FROM net-tools as tshark

# Switch to root user for installation
USER root

# Copy Tshark deb files
ARG WIRESHARK_VERSION
COPY --from=wireshark-build \
	/root/libwsutil11_${WIRESHARK_VERSION}_amd64.deb \
	/root/libwiretap10_${WIRESHARK_VERSION}_amd64.deb \
	/root/libwireshark-data_${WIRESHARK_VERSION}_all.deb \
	/root/libwireshark13_${WIRESHARK_VERSION}_amd64.deb \
	/root/wireshark-common_${WIRESHARK_VERSION}_amd64.deb \
	/root/tshark_${WIRESHARK_VERSION}_amd64.deb \
	/root/

# Install TShark
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

# Add permissions to run tshark as non root user
RUN setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap

# Switch to non root user
USER debian

# Set tools related labels
ARG WIRESHARK_VERSION
LABEL wireshark.version=${WIRESHARK_VERSION}

# Set default cmd
ENV ENTRYPOINT_DEFAULT_CMD /usr/bin/tshark
CMD ["/usr/bin/tshark"]


## Create Termshark image ##
FROM tshark as termshark

# Switch to root user for installation
USER root

# Install Termshark
ARG TERMSHARK_VERSION=2.1.1
RUN curl -L https://github.com/gcla/termshark/releases/download/v${TERMSHARK_VERSION}/termshark_${TERMSHARK_VERSION}_linux_x64.tar.gz | tar -xz --strip-components=1 -C /usr/bin
LABEL termshark.version=${TERMSHARK_VERSION}

# Switch to non root user
USER debian

# Set default cmd
ENV ENTRYPOINT_DEFAULT_CMD /usr/bin/termshark
CMD ["/usr/bin/termshark"]


## Create wireshark image ##
FROM tshark as wireshark

# Switch to root user for installation
USER root

# Copy Wireshark deb files
ARG WIRESHARK_VERSION
COPY --from=wireshark-build \
	/root/wireshark-qt_${WIRESHARK_VERSION}_amd64.deb \
	/root/wireshark_${WIRESHARK_VERSION}_amd64.deb \
	/root/

# Install Wireshark
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

# Install xpra
RUN curl http://xpra.org/gpg.asc | apt-key add -
ARG DEBIAN_RELEASE
RUN echo "deb http://xpra.org/ ${DEBIAN_RELEASE} main" >> /etc/apt/sources.list.d/xpra.list;

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install -y xpra xpra-html5 python3-xpra python3-uinput xauth websockify \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
ENV DEBIAN_FRONTEND=dialog

# copy xpra config file
COPY ./xpra.conf /etc/xpra/xpra.conf

# ensure that wireshark is using text mode for best display quality in HTML5 client
RUN echo -e "\nclass-instance:wireshark=text" >> /usr/share/xpra/content-type/50_class.conf

# create run directory for xpra socket and set correct permissions
RUN mkdir -p /run/user/$(id -u debian)/xpra
RUN chown -R debian:debian /run/user/$(id -u debian)

# allow wireshark user to read default certificate
RUN chmod 644 /etc/xpra/ssl-cert.pem

# Switch to non root user
RUN usermod -a -G xpra debian
USER debian

# set default password to access wireshark via xpra
ENV XPRA_PW wireshark

# expose xpra default port
EXPOSE 14500

# run xpra, options --daemon and --no-printing only work if specified as parameters to xpra start
ENV ENTRYPOINT_DEFAULT_CMD "/usr/bin/xpra start --daemon=no"
CMD ["/usr/bin/xpra","start","--daemon=no"]