#!/bin/bash

set -ex

ARCH=$1
DEFAULT_ARCH=$(dpkg --print-architecture)
[ -z "$ARCH" ] && [ -f /etc/docker-arch ] && ARCH=$(cat /etc/docker-arch)
[ -z "$ARCH" ] && ARCH=$DEFAULT_ARCH

# A workaroud to build image by azure image builder, if the build failed with lock issue, simply wait for a while and retry.
apt_get_cmd()
{
  local retry=12
  local sleep=10
  local tmp=$(tempfile)
  set -o pipefail
  for ((i=1; i<=$retry; i++)); do
    if /usr/bin/apt-get "$@" | tee $tmp; then
      break
    fi

    if ! grep -q "Could not get lock" $tmp; then
      echo "Failed install $@"
      break
    fi

    echo "Retry for dpkg lock"
    sleep 10
  done
  set +o pipefail
}

alias apt-get=apt_get_cmd
alias apt=apt_get_cmd

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

# Install build tools (and waiting docker ready)
apt-get install -y make nfs-common python3-pip python3-setuptools
pip3 install jinja2==2.10 j2cli==0.3.10

# install git lfs
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get install -y git-lfs

# echo creating sonic tmp account
tmpuser=AzDevOps
useradd -m $tmpuser
usermod -a -G docker $tmpuser
usermod -a -G adm $tmpuser
usermod -a -G sudo $tmpuser
echo "$tmpuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/100-$tmpuser
chmod 440 /etc/sudoers.d/100-$tmpuser

if [ "$ARCH" == "armhf" ] && [ "$ARCH" != "$DEFAULT_ARCH" ]; then
  dpkg --add-architecture armhf
fi
 
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --batch --yes
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce:$ARCH docker-ce-cli:$ARCH containerd.io:$ARCH docker-compose-plugin:$ARCH

mkdir -p /data /work

# Customize for armhf
if [ "$ARCH" == "armhf" ] && [ "$ARCH" != "$DEFAULT_ARCH" ]; then
  # Configure docker service
  mkdir -p /etc/systemd/system/docker.service.d
  echo "[Service]" > /etc/systemd/system/docker.service.d/override.conf
  echo "ExecStart=" >> /etc/systemd/system/docker.service.d/override.conf
  echo "ExecStart=/usr/bin/setarch linux32 -B /usr/bin/dockerd -H unix:// --storage-driver overlay2 --ipv6 --fixed-cidr-v6=2603:10a0:100:830::0/64 --experimental" >> /etc/systemd/system/docker.service.d/override.conf

  # Configure container service
  mkdir -p /etc/systemd/system/containerd.service.d
  echo "[Service]" > /etc/systemd/system/containerd.service.d/override.conf
  echo "ExecStart=" >> /etc/systemd/system/containerd.service.d/override.conf
  echo "ExecStart=/usr/bin/setarch linux32 -B /usr/bin/containerd" >> /etc/systemd/system/containerd.service.d/override.conf

  # reload docker container service
  systemctl daemon-reload
  service docker restart
  service containerd restart

  # Verify docker armhf is ready
  sleep 30
  machine=$(docker run --rm debian:bullseye uname -m)
  if [ "$machine" != "armv7l" ] && [ "$machine" != "armv8l" ]; then
    echo "The machine=$machine is not correct, provision failed" 1>&2
    exit 1
  fi
fi
