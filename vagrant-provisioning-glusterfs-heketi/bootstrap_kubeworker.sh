#!/bin/bash

# Join worker nodes to the Kubernetes cluster
echo "[TASK 1] Join node to Kubernetes Cluster"
sshpass -p "admin" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kubemaster.example.com:/joincluster.sh /joincluster.sh 2>/dev/null
bash /joincluster.sh >/dev/null 2>&1

#Installing glusterfs
yum -y install centos-release-gluster
yum -y install glusterfs-server
systemctl enable --now glusterd
systemctl start glusterd