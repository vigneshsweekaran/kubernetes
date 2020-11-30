# Creating kubernetes cluster with glusterfs and heketi as storage solution

### Briging up the kubernetes cluster
```
vagrant up
```

### Create additional disk in virtualbox with size 32 GB and attach to each worker node (minimum 2 additional disk is required )
```
vagrant halt kubeworker1 kubeworker2
# Create amd attach the device to the worker nodes
vagrant up kubeworker1 kubeworker2
```

### Ssh into kubemaster and switch to root user
```
sudo su -
ssh-keygen -f /etc/heketi/heketi_key -t rsa -N ''
for node in kubeworker1 kubeworker2; do
    sshpass -p "admin" ssh-copy-id -i /etc/heketi/heketi_key.pub root@$node
done
```

### Creating Heketi cluster
```
heketi-cli cluster create
```

### Adding nodes to heketi cluster
```
heketi-cli node add --cluster=< cluster_id > --zone=1 --management-host-name=kubeworker1.example.com --storage-host-name=172.42.42.201
heketi-cli node add --cluster=< cluster_id > --zone=1 --management-host-name=kubeworker2.example.com --storage-host-name=172.42.42.202
```

### Adding device to heketi cluster
```
heketi-cli device add --name=< device_path > --node=< node1_id >
heketi-cli device add --name=< device_path > --node=< node2_id >
eg:
heketi-cli device add --name=/dev/sdb --node=< node1_id >
```

### Create storage class and use it in pod definitions
```
kubectl create -f storage-class-glusterfs.yaml
```

# Issues

### Error: Invalid JWT token: Token missing iss claim
Fix: username and password to be passed to heketi-cli or export the following environment variables.
```
echo "export HEKETI_CLI_USER=admin" >> /etc/bashrc
echo "export HEKETI_CLI_KEY=secretpassword" >> /etc/bashrc
source /etc/bashrc
```

### If not able to craete nodes, saying (gluserd not running in node)
Fix: check whether passwordless ssh connection is working from heketi node(master node) to glusterfs nodes (worker nodes)

### Created PVC are not bounding (ERROR, node IP is not a valid one)
Fix: While adding the node to heketi cluster pass ip-address in --storage-host-name parameter
eg: heketi-cli node add --cluster=< cluster_id > --zone=1 --management-host-name=kubeworker1.example.com --storage-host-name=172.42.42.201
