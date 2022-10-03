#!/bin/bash

set -ex

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release
dpkg --add-architecture armhf

 
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=armhf signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce:armhf docker-ce-cli:armhf containerd.io:armhf docker-compose-plugin:armhf

# Configure docker service
mkdir -p /data
mkdir -p /etc/systemd/system/docker.service.d
echo "[Service]" > /etc/systemd/system/docker.service.d/override.conf
echo "ExecStart=" >> /etc/systemd/system/docker.service.d/override.conf
echo "ExecStart=/usr/bin/setarch linux32 -B /usr/bin/dockerd -H unix:// --data-root /data/docker --storage-driver overlay2 --ipv6 --fixed-cidr-v6=2603:10a0:100:830::0/64 --experimental" >> /etc/systemd/system/docker.service.d/override.conf

# Configure container service
mkdir -p /etc/systemd/system/containerd.service.d
echo "[Service]" > /etc/systemd/system/containerd.service.d/override.conf
echo "ExecStart=" >> /etc/systemd/system/containerd.service.d/override.conf
echo "ExecStart=/usr/bin/setarch linux32 -B /usr/bin/containerd" >> /etc/systemd/system/containerd.service.d/override.conf

# reload docker container service
systemctl daemon-reload
service docker restart
service containerd restart

# Install build tools (and waiting docker ready)
apt-get install -y build-essential nfs-common python3-pip python3-setuptools
pip3 install jinja2==2.10 j2cli==0.3.10

# Check docker armhf ready
machine=$(docker run --rm debian:bullseye uname -m)
if [ "$machine" != "armv7l" ] && [ "$machine" != "armv8l" ]; then
  echo "The machine=$machine is not correct, provision failed" 1>&2
  exit 1
fi
