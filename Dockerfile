FROM ubuntu:24.04


# set build variables
ARG DEBIAN_FRONTEND="noninteractive"

# Install stuff
RUN \
  echo "**** run installation script ****" && \
  apt-get update && \
  apt-get install -y imagemagick python3 python3-pip python3-setuptools python3-wheel git gcc wget xz-utils net-tools zstd cron openssh-client 

# Configure S6 Overlay
ARG S6_OVERLAY_VERSION="3.2.0.2"
ARG S6_OVERLAY_ARCH="x86_64"

# add s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# Copy files
COPY root/ /

# Create non-privileged user
RUN groupadd -g 1234 nnlc && \
    useradd -m -u 1234 -g nnlc nnlc

# Set nnlc user permissions
RUN mkdir /input /output
RUN chown -R nnlc:nnlc /input /output /home/nnlc
RUN chmod u+x /home/nnlc/*.sh /home/nnlc/setup/*.sh /home/nnlc/nnlc/process.sh
# RUN usermod -a -G video,render nnlc

# Download required tools and repos to nnlc user home directory
USER nnlc
RUN /home/nnlc/setup/install-nnlc-dependencies.sh

# Add julia to PATH
USER root
RUN ln -sf /home/nnlc/nnlc/julia-1.11.5/bin/julia /usr/local/bin

# Install GPU drivers
RUN cd /home/nnlc/setup
# AMD
RUN wget https://repo.radeon.com/amdgpu-install/6.4/ubuntu/noble/amdgpu-install_6.4.60400-1_all.deb
RUN apt-get install -y ./amdgpu-install_6.4.60400-1_all.deb
RUN apt-get update
RUN apt-get install -y rocm amdgpu-dkms
# NVIDIA
RUN apt-get install -y gcc nvidia-driver-570 nvidia-cuda-toolkit nvidia-cudnn

# Install julia packages as nnlc user
USER nnlc
RUN /home/nnlc/install-julia-packages.sh

# volumes
VOLUME /input
VOLUME /output

# Run init scripts as nnlc user
USER nnlc
ENTRYPOINT ["/init"]