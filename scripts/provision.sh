#!/bin/bash

set -ex

ARCH=$1
DEFAULT_ARCH=$(dpkg --print-architecture)
[ -z "$ARCH" ] && [ -f /etc/docker-arch ] && ARCH=$(cat /etc/docker-arch)
[ -z "$ARCH" ] && ARCH=$DEFAULT_ARCH


apt_get_cmd()
{
  local retry=12
  local sleep=10
  set -o pipefail
  for ((i=1; i<=$retry; i++)); do
    if apt-get "$@" | tee /tmp/dpkg.log; then
      break
    fi

    if ! grep -q "Could not get lock" /tmp/dpkg.log; then
      echo "Failed install $@"
      break
    fi

    echo "Retry for dpkg lock"
    sleep 10
  done
  set +o pipefail
} 

apt_get_cmd update
apt_get_cmd install -y ca-certificates curl gnupg lsb-release

# Install build tools (and waiting docker ready)
apt_get_cmd install -y make nfs-common python3-pip python3-setuptools
pip3 install jinja2==2.10 j2cli==0.3.10

if [ "$ARCH" == "armhf" ] && [ "$ARCH" != "$DEFAULT_ARCH" ]; then
  dpkg --add-architecture armhf
fi
 
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --batch --yes
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt_get_cmd update
apt_get_cmd install -y docker-ce:$ARCH docker-ce-cli:$ARCH containerd.io:$ARCH docker-compose-plugin:$ARCH

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
