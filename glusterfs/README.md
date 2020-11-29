# Glusterfs and Heketi on Kuberenetes worker node

### Add additional device to worker node

### Install Glusterfs
  ```
  sudo yum install centos-release-gluster
  sudo yum -y install glusterfs-server
  sudo systemctl enable --now glusterd
  sudo systemctl start glusterd
  ```
  
### Download Heketi binaries
  ```
  cd /tmp
  wget https://github.com/heketi/heketi/releases/download/v10.1.0/heketi-v10.1.0.linux.amd64.tar.gz
  tar zxf heketi*
  mv heketi/{heketi,heketi-cli} /usr/local/bin/
  ```
  
### Set up user account for heketi
  ```
  groupadd -r heketi
  useradd -r -s /sbin/nologin -g heketi heketi
  mkdir {/var/lib,/etc,/var/log}/heketi
  ```
