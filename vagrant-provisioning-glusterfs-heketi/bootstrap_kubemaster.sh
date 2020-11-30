#!/bin/bash

# Initialize Kubernetes
echo "[TASK 1] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=172.42.42.200 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

# Copy Kube admin config
echo "[TASK 2] Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Deploy Calico network
echo "[TASK 3] Deploy Calico network"
su - vagrant -c "kubectl create -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml"

# Generate Cluster join command
echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh

# Installing heketi in kubeworker1
cd /tmp
wget https://github.com/heketi/heketi/releases/download/v10.1.0/heketi-v10.1.0.linux.amd64.tar.gz
tar zxf heketi*
mv heketi/{heketi,heketi-cli} /usr/local/bin/

# Adding heketi user
groupadd -r heketi
useradd -r -s /sbin/nologin -g heketi heketi
mkdir {/var/lib,/etc,/var/log}/heketi

# Create ssh passwordless access to Gluster nodes
ssh-keygen -f /etc/heketi/heketi_key -t rsa -N ''
for node in kubeworker1 kubeworker2; do
    sshpass -p "admin" ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/heketi/heketi_key.pub root@$node
done

# Copying Heketi json
cat <<EOF >/etc/heketi/heketi.json
{
  "_port_comment": "Heketi Server Port Number",
  "port": "8080",

	"_enable_tls_comment": "Enable TLS in Heketi Server",
	"enable_tls": false,

	"_cert_file_comment": "Path to a valid certificate file",
	"cert_file": "",

	"_key_file_comment": "Path to a valid private key file",
	"key_file": "",


  "_use_auth": "Enable JWT authorization. Please enable for deployment",
  "use_auth": true,

  "_jwt": "Private keys for access",
  "jwt": {
    "_admin": "Admin has access to all APIs",
    "admin": {
      "_key_comment": "Set the admin key in the next line",
      "key": "secretpassword"
    },
    "_user": "User only has access to /volumes endpoint",
    "user": {
      "_key_comment": "Set the user key in the next line",
      "key": "secretpassword"
    }
  },

  "_backup_db_to_kube_secret": "Backup the heketi database to a Kubernetes secret when running in Kubernetes. Default is off.",
  "backup_db_to_kube_secret": false,

  "_profiling": "Enable go/pprof profiling on the /debug/pprof endpoints.",
  "profiling": false,

  "_glusterfs_comment": "GlusterFS Configuration",
  "glusterfs": {
    "_executor_comment": [
      "Execute plugin. Possible choices: mock, ssh",
      "mock: This setting is used for testing and development.",
      "      It will not send commands to any node.",
      "ssh:  This setting will notify Heketi to ssh to the nodes.",
      "      It will need the values in sshexec to be configured.",
      "kubernetes: Communicate with GlusterFS containers over",
      "            Kubernetes exec api."
    ],
    "executor": "ssh",

    "_sshexec_comment": "SSH username and private key file information",
    "sshexec": {
      "keyfile": "/etc/heketi/heketi_key",
      "user": "root",
      "port": "22",
      "fstab": "/etc/fstab"
    },

    "_db_comment": "Database file name",
    "db": "/var/lib/heketi/heketi.db",

     "_refresh_time_monitor_gluster_nodes": "Refresh time in seconds to monitor Gluster nodes",
    "refresh_time_monitor_gluster_nodes": 120,

    "_start_time_monitor_gluster_nodes": "Start time in seconds to monitor Gluster nodes when the heketi comes up",
    "start_time_monitor_gluster_nodes": 10,

    "_loglevel_comment": [
      "Set log level. Choices are:",
      "  none, critical, error, warning, info, debug",
      "Default is warning"
    ],
    "loglevel" : "debug",

    "_auto_create_block_hosting_volume": "Creates Block Hosting volumes automatically if not found or exsisting volume exhausted",
    "auto_create_block_hosting_volume": true,

    "_block_hosting_volume_size": "New block hosting volume will be created in size mentioned, This is considered only if auto-create is enabled.",
    "block_hosting_volume_size": 500,

    "_block_hosting_volume_options": "New block hosting volume will be created with the following set of options. Removing the group gluster-block option is NOT recommended. Additional options can be added next to it separated by a comma.",
    "block_hosting_volume_options": "group gluster-block",

    "_pre_request_volume_options": "Volume options that will be applied for all volumes created. Can be overridden by volume options in volume create request.",
    "pre_request_volume_options": "",

    "_post_request_volume_options": "Volume options that will be applied for all volumes created. To be used to override volume options in volume create request.",
    "post_request_volume_options": ""
  }
}
EOF

# Update permissions on heketi directories
chown -R heketi:heketi {/var/lib,/etc,/var/log}/heketi

# Create systemd unit file for heketi
cat <<EOF >/etc/systemd/system/heketi.service
[Unit]
Description=Heketi Server

[Service]
Type=simple
WorkingDirectory=/var/lib/heketi
EnvironmentFile=-/etc/heketi/heketi.env
User=heketi
ExecStart=/usr/local/bin/heketi --config=/etc/heketi/heketi.json
Restart=on-failure
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF

# Enable and start heketi service
systemctl daemon-reload
systemctl enable --now heketi
systemctl status heketi

# Quick verification that heketi is running
curl localhost:8080/hello; echo

# Export environment variables for heketi-cli
echo "export HEKETI_CLI_USER=admin" >> /etc/bashrc
echo "export HEKETI_CLI_KEY=secretpassword" >> /etc/bashrc

# Generating script for creating heketi cluster
cat <<EOF >/home/vagrant/setup.sh
# Creating Heketi cluster
heketi-cli cluster create

# Adding nodes to heketi cluster
heketi-cli node add --cluster=< cluster_id > --zone=1 --management-host-name=kubeworker1.example.com --storage-host-name=172.42.42.201
heketi-cli node add --cluster=< cluster_id > --zone=1 --management-host-name=kubeworker2.example.com --storage-host-name=172.42.42.202
# Adding device to heketi cluster
heketi-cli device add --name=< device_path > --node=< node1_id >
heketi-cli device add --name= --node=< node2_id >

EOF