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

### 
# Issues

### Error: Invalid JWT token: Token missing iss claim
Fix: username and password to be passed to heketi-cli or export the following environment variables.
```
echo "export HEKETI_CLI_USER=admin" >> /etc/bashrc
echo "export HEKETI_CLI_KEY=secretpassword" >> /etc/bashrc
source /etc/bashrc
```
