#!/usr/bin/env bash

if [[ $GPU == 'nvidia' ]]; then
  echo "Installing Nvidia packages"
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
else
  echo "No supported GPU specified."
fi