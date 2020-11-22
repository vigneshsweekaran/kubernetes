# Craeting ceph cluster using Rook

**Github :** https://github.com/rook/rook

1. Create additional disk in each node
2. In cluster.yaml update the following parameters
```
mon
  allowMultiplePerNode: true # If we have small 3 node cluster
storage:
  useAllNodes: false
nodes:
- name: "kmaster.example.com" # kuberentes Node name
  devices: # specific devices to use for storage can be specified for each node
  - name: "sdb" # Newly added disk name in the node
- name: "kworker1.example.com"
  devices: # specific devices to use for storage can be specified for each node
  - name: "sdb"
```
3. Create ceph cluster using Rook
```
kubectl create -f crds.yaml -f common.yaml -f operator.yaml
kubectl create -f cluster-external.yaml
```
