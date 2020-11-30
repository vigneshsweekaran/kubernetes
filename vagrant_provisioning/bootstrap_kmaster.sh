#!/bin/bash

# Initialize Kubernetes
echo "[TASK 1] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=172.42.42.200 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

# Copy Kube admin config
echo "[TASK 2] Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Deploy Calico network
echo "[TASK 3] Deploy Calico network"
su - vagrant -c "kubectl create -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml"

# Generate Cluster join command
echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh

# Installing heketi in kubeworker1
cd /tmp
wget https://github.com/heketi/heketi/releases/download/v10.1.0/heketi-v10.1.0.linux.amd64.tar.gz
tar zxf heketi*
mv heketi/{heketi,heketi-cli} /usr/local/bin/

# Adding heketi user
groupadd -r heketi
useradd -r -s /sbin/nologin -g heketi heketi
mkdir {/var/lib,/etc,/var/log}/heketi

# Create ssh passwordless access to Gluster nodes
ssh-keygen -f /etc/heketi/heketi_key -t rsa -N ''
for node in kubeworker1 kubeworker2; do
    sshpass -p "admin" ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/heketi/heketi_key.pub root@$node
done

# Copying Heketi json
cp ./heketi.json /etc/heketi/

# Update permissions on heketi directories
chown -R heketi:heketi {/var/lib,/etc,/var/log}/heketi

# Create systemd unit file for heketi
cat <<EOF >/etc/systemd/system/heketi.service
[Unit]
Description=Heketi Server

[Service]
Type=simple
WorkingDirectory=/var/lib/heketi
EnvironmentFile=-/etc/heketi/heketi.env
User=heketi
ExecStart=/usr/local/bin/heketi --config=/etc/heketi/heketi.json
Restart=on-failure
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF

# Enable and start heketi service
systemctl daemon-reload
systemctl enable --now heketi
systemctl status heketi

# Quick verification that heketi is running
curl localhost:8080/hello; echo

# Export environment variables for heketi-cli
export HEKETI_CLI_USER=admin
export HEKETI_CLI_KEY=secretpassword

