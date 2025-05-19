FROM ubuntu:24.04


# set build variables
ARG DEBIAN_FRONTEND="noninteractive"

# Install stuff
RUN \
  echo "**** run installation script ****" && \
  apt-get update && \
  apt-get install -y imagemagick python3 git gcc wget xz-utils net-tools zstd cron openssh-client

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
RUN chmod u+x /home/nnlc/*.sh /home/nnlc/nnlc/process.sh

# volumes
VOLUME /input
VOLUME /output

# Switch to the custom user
USER nnlc
RUN /home/nnlc/install-nnlc-dependencies.sh

# Add julia to PATH
USER root
RUN ln -sf /home/nnlc/nnlc/julia-1.11.5/bin/julia /usr/local/bin
# RUN chown -R nnlc:nnlc /usr/local/bin/julia

# Switch to the custom user
USER nnlc
RUN /home/nnlc/install-julia-packages.sh

# Run init scripts as nnlc user
USER nnlc
ENTRYPOINT ["/init"]