FROM ubuntu:24.04

# set build variables
ARG DEBIAN_FRONTEND="noninteractive"
ARG GPU="nvidia"

# Install stuff
RUN \
  echo "**** run installation script ****" && \
  apt-get update && \
  apt-get install -y \
  cron \
  git \
  imagemagick \
  nano \
  openssh-client \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  wget \
  xz-utils \
  zstd && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Configure S6 Overlay
ARG S6_OVERLAY_VERSION="3.2.0.2"
ARG S6_OVERLAY_ARCH="x86_64"
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# Copy files
COPY root/ /

# Create non-privileged user
RUN groupadd -g 1234 nnlc && \
    useradd -m -u 1234 -g nnlc nnlc

# Create data volume filetree
RUN mkdir /data \
  /data/config \
  /data/logs \
  /data/output \
  /data/rlogs

# Set nnlc user permissions
RUN chown -R nnlc:nnlc /data /home/nnlc
RUN chmod u+x /home/nnlc/setup/*.sh /home/nnlc/nnlc/*.sh

# Download NNLC tools and install dependencies
USER nnlc
RUN \
  /home/nnlc/setup/install-nnlc-dependencies.sh && \
  . /home/nnlc/.bashrc && \
  /home/nnlc/setup/install-julia-packages.sh

# Make cronjobs executable and add script shortcuts
USER root
RUN chmod u+s $(which cron) && \
  ln -sf /home/nnlc/nnlc/nnlc-process-log.sh /usr/local/bin/nnlc-process && \
  ln -sf /home/nnlc/nnlc/rlog-import-log.sh /usr/local/bin/rlog-import

# Install GPU required packages
WORKDIR /tmp
RUN /home/nnlc/setup/install-gpu-packages.sh

# Container initialization
USER nnlc
VOLUME /data
WORKDIR /
ENTRYPOINT ["/init"]