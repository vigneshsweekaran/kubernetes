#!/bin/bash

# Install Docker
sudo yum update -y
sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# Installing docker dependencies in oracle 
sudo yum install -y http://mirror.centos.org/altarch/7/extras/aarch64/Packages/slirp4netns-0.4.3-4.el7_8.aarch64.rpm
sudo yum install -y http://mirror.centos.org/altarch/7/extras/aarch64/Packages/fuse3-libs-3.6.1-4.el7.aarch64.rpm
sudo yum install -y http://mirror.centos.org/altarch/7/extras/aarch64/Packages/fuse-overlayfs-0.7.2-6.el7_8.aarch64.rpm

sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker

sudo usermod -aG docker opc
newgrp docker

# Install kubeadm, kubelet, kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet

# open some ports
sudo firewall-cmd --add-port=6443/tcp --permanent
sudo firewall-cmd --add-port=2379-2380/tcp --permanent
sudo firewall-cmd --add-port=10250/tcp --permanent
sudo firewall-cmd --add-port=10251/tcp --permanent
sudo firewall-cmd --add-port=10252/tcp --permanent
sudo firewall-cmd --reload

# swap off
sudo swapoff -a

# Initializes cluster master node:
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Initialize cluster networking:
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Untaint master node to deploy pods in master node
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-

# Installing Helm version 3
export VERIFY_CHECKSUM=false
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash