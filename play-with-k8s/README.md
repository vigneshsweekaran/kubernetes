# Script to create a kuberentes cluster using kubeadm

**USAGE:**
By default if we run the shell script it will create the kuberenetes cluster using kbueadm
./setup.sh

To install helm version 3 along with kubernetes
./setup.sh helm

To Configure user name and mail for git
./setup.sh git

To untaint master node if using the single node cluster
./setup.sh untaint

To pass multiple parametrs to script
./setup.sh git helm untaint

**PARAMETERS :**
|Parameter|Description| 
|----|-----|
|git|To configure user name and mail for git|
|helm|To install helm|
|untaint|To create pods in single node cluster (By default we cannot create pods(any resources) in master node)|
