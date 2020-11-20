#!/bin/bash

# 1. Initializes cluster master node:
kubeadm init --apiserver-advertise-address $(hostname -i) --pod-network-cidr 10.5.0.0/16

# 2. Initialize cluster networking:
kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml

# 3. Untaint master node to deploy pods in master node
kubectl taint nodes node1 node-role.kubernetes.io/master:NoSchedule-

# 4. Installing Helm version 3
export VERIFY_CHECKSUM=false
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
