#!/usr/bin/env bash

echo "####################################################"
echo "############### Join do Worker node ################"
echo "####################################################"

cat /tmp/k8s/hosts-entry | sudo tee -a /etc/hosts
chmod 0755 /tmp/k8s/control-plane-join.sh
sudo /tmp/k8s/control-plane-join.sh
kubectl label node `hostname -s` node-role.kubernetes.io/worker=worker --kubeconfig /tmp/k8s/cluster-admin.conf
