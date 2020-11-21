#!/bin/bash

# Installing Helm version 3
if [[ "$*" == *helm* ]]; then
    export VERIFY_CHECKSUM=false
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
fi

# Configuring git username and mail
if [[ "$*" == *git* ]]; then
    git config user.email "play-with-kubernetes@gmail.com"
    git config user.name "play-with-kubernetes"
fi

#Creating kubernetes cluster using kubeadm
output=`kubectl cluster-info`
echo $output
if [[ ! $output == *Kubernetes*master*is*running*at*https://*:6443* ]]; then
    # Initializes cluster master node:
    kubeadm init --apiserver-advertise-address $(hostname -i) --pod-network-cidr 10.5.0.0/16

    # Initialize cluster networking:
    kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
fi

# Untaint master node to deploy pods in master node
if [[ "$*" == *untaint* ]]; then
    kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
fi
