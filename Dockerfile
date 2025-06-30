FROM ubuntu:24.04

# set build variables
ARG DEBIAN_FRONTEND="noninteractive"

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
  rsync \
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

# Create non-privileged user
RUN groupadd -g 1234 nnlc && \
    useradd -m -u 1234 -g nnlc nnlc

# Create data volume filetree
RUN mkdir -p \
  /data/config \
  /data/logs \
  /data/output \
  /data/rlogs \
  /home/nnlc/setup/ \
  /home/nnlc/nnlc/

# Copy setup files
COPY root/etc /etc
COPY root/home/nnlc/setup /home/nnlc/setup

# Set nnlc user permissions
RUN chown -R nnlc:nnlc /data /home/nnlc
RUN chmod -R u+rw /home/nnlc
RUN chmod u+x /home/nnlc/setup/*.sh

# Install NNLC tools
USER nnlc
RUN /home/nnlc/setup/install-nnlc-dependencies.sh
RUN . /home/nnlc/.bash_functions && /home/nnlc/setup/install-julia-packages.sh
RUN /home/nnlc/setup/install-nnlc-tools.sh

# Copy NNLC utility scripts
COPY root/home/nnlc/nnlc /home/nnlc/nnlc

# Make cronjobs executable and add script shortcuts
USER root
RUN chmod u+s $(which cron) && \
  chown -R nnlc:nnlc /etc/s6-overlay/s6-rc.d/init-rlog-import && \
  chmod u+x /etc/s6-overlay/s6-rc.d/init-rlog-import/run && \
  chmod u+rwx -R /data && \
  chmod u+x /home/nnlc/nnlc/*.sh && \
  ln -sf /home/nnlc/nnlc/nnlc-clean-log.sh /usr/local/bin/nnlc-clean && \
  ln -sf /home/nnlc/nnlc/nnlc-process-log.sh /usr/local/bin/nnlc-process && \
  ln -sf /home/nnlc/nnlc/nnlc-review-log.sh /usr/local/bin/nnlc-review && \
  ln -sf /home/nnlc/nnlc/rlog-import-log.sh /usr/local/bin/rlog-import && \
  ln -sf /home/nnlc/nnlc/rlog-rename-log.sh /usr/local/bin/rlog-rename

# Container initialization
USER nnlc
VOLUME /data
WORKDIR /
ENTRYPOINT ["/init"]