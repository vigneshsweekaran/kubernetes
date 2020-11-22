# Creating ceph cluster using Rook

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
4. Create storageclass
```
kubectl create -f storageclass.yaml
```
5. (Optional) To execute the ceph commands, we need to install one more container toolbox
```
kubectl create -f toolbox.yaml
```
6. (Optional) Exec inside the tools container to execute the ceph commands
```
kubectl exec -it pod_name -n rook-ceph -- sh
ceph status
ceph osd status # To check storage space avilable/used
```
7. Create a peristent volume claim
```
kubectl create -f pvc.yaml
```
8. Create a pod and map that PVC
```
kubectl create -f pod.yaml
```
9. To add more OSDS, attcah new disks to the node and add the node name and disk name in nodes section in cluster.yaml, then update it
```
kubectl apply -f cluster.yaml # This will automatically add the new device/disk to the ceph cluster
```
