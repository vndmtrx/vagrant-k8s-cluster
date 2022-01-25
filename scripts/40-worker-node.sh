#!/usr/bin/env bash

echo "####################################################"
echo "############### Join do Worker node ################"
echo "####################################################"

cat /tmp/k8s/hosts-entry | sudo tee -a /etc/hosts
chmod 0755 /tmp/k8s/control-node-join.sh
sudo /tmp/k8s/control-node-join.sh
