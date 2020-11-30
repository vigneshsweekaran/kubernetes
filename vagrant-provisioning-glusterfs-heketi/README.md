# Creating kubernetes cluster with glusterfs and heketi as storage solution

### Briging up the kubernetes cluster
```
vagrant up
```

### Create additional disk in virtualbox with size 32 GB to each worker node
```
vagrant halt kubeworker1 kubeworker2
# Create amd attach the device to the worker nodes
vagrant up kubeworker1 kubeworker2
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
heketi-cli device add --name= --node=< node2_id >
```
 
# Issues

### Error: Invalid JWT token: Token missing iss claim
Fix: username and password to be passed to heketi-cli or export the following environment variables.
```
echo "export HEKETI_CLI_USER=admin" >> /etc/bashrc
echo "export HEKETI_CLI_KEY=secretpassword" >> /etc/bashrc
source /etc/bashrc
```
