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

# Create volume mounts
RUN mkdir /input /output

# Set nnlc user permissions
RUN chown -R nnlc:nnlc /input /output /home/nnlc
RUN chmod u+x /home/nnlc/*.sh /home/nnlc/setup/*.sh /home/nnlc/nnlc/process.sh
# RUN usermod -a -G video,render nnlc

VOLUME /input
VOLUME /output

# Download required tools and repos to nnlc user home directory
USER nnlc
RUN \
  /home/nnlc/setup/install-nnlc-dependencies.sh && \
  . /home/nnlc/.bashrc && \
  /home/nnlc/setup/install-julia-packages.sh

# Install GPU drivers
USER root
# AMD
# RUN wget https://repo.radeon.com/amdgpu-install/6.4/ubuntu/noble/amdgpu-install_6.4.60400-1_all.deb
# RUN apt-get install -y ./amdgpu-install_6.4.60400-1_all.deb
# RUN apt-get update
# RUN apt-get install -y rocm amdgpu-dkms

# NVIDIA
RUN \
  cd /tmp && \
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin && \
  mv cuda-ubuntu2404.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
  wget https://developer.download.nvidia.com/compute/cuda/12.9.0/local_installers/cuda-repo-ubuntu2404-12-9-local_12.9.0-575.51.03-1_amd64.deb && \
  dpkg -i cuda-repo-ubuntu2404-12-9-local_12.9.0-575.51.03-1_amd64.deb && \
  cp /var/cuda-repo-ubuntu2404-12-9-local/cuda-*-keyring.gpg /usr/share/keyrings/ && \
  wget https://developer.download.nvidia.com/compute/cudnn/9.10.1/local_installers/cudnn-local-repo-ubuntu2404-9.10.1_1.0-1_amd64.deb && \
  dpkg -i cudnn-local-repo-ubuntu2404-9.10.1_1.0-1_amd64.deb && \
  cp /var/cudnn-local-repo-ubuntu2404-9.10.1/cudnn-*-keyring.gpg /usr/share/keyrings/ && \
  apt-get update && \
  apt-get -y install cuda-libraries-12-9 cudnn-cuda-12 && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf \
    /var/lib/apt/lists/* \
    /tmp/*

# Run init scripts as nnlc user
USER nnlc
ENTRYPOINT ["/init"]