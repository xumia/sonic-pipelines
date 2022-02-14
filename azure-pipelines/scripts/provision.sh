#!/bin/bash

set -ex

arch=$(dpkg --print-architecture)
[ -n "$ARCH" ] && arch=$ARCH

source /etc/os-release

apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=$arch] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

if [ "$arch" == "armhf" ]; then
    mkdir -p /etc/systemd/system/docker.service.d
    echo '[Service]' > /etc/systemd/system/docker.service.d/override.conf
    echo 'ExecStart=' >> /etc/systemd/system/docker.service.d/override.conf
    echo 'ExecStart=/usr/bin/setarch linux32 -B /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock' >> /etc/systemd/system/docker.service.d/override.conf

    mkdir -p /etc/systemd/system/containerd.service.d
    echo '[Service]' > /etc/systemd/system/containerd.service.d/override.conf
    echo 'ExecStart=' >> /etc/systemd/system/containerd.service.d/override.conf
    echo 'ExecStart=/usr/bin/setarch linux32 -B /usr/bin/containerd' >> /etc/systemd/system/containerd.service.d/override.conf

    sed -i 's#ExecStart=/usr/bin/dockerd#ExecStart=/usr/bin/setarch linux32 -B /usr/bin/dockerd#' /lib/systemd/system/docker.service
    systemctl daemon-reload
    service docker restart
    service containerd restart
fi

# install qemu for multi-arch docker
apt-get install -y qemu binfmt-support qemu-user-static

# Setup qemu for multiarch, see https://github.com/multiarch/qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes


# install utilities for image build
apt-get install -y make
if [ x$VERSION_CODENAME == x"bionic" ]; then
    apt-get install -y python-pip
    python2 -m pip install -U pip==9.0.3
    pip install --force-reinstall --upgrade jinja2==2.10
    pip install j2cli==0.3.10
else
    apt-get install -y python3-pip
    pip3 install --force-reinstall --upgrade jinja2==2.10
    pip3 install j2cli==0.3.10
    # for team services agent
    apt-get install -y python-is-python2
    # install setfacl for arm build
    apt-get install -y acl
fi

# install git lfs
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get install -y git-lfs
