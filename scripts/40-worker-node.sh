#!/usr/bin/env bash

echo "####################################################"
echo "############### Join do Worker node ################"
echo "####################################################"

IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2}'`
HOST=`hostname -s`

#echo "$IP $HOST" | sudo tee -a /etc/hosts
#cat /tmp/k8s/control-plane-hosts-entry | sudo tee -a /etc/hosts

chmod 0755 /tmp/k8s/control-plane-join.sh

# Hack para fazer o comando `kubeadm join` funcionar usando a interface de rede host-only
sudo ip route add default via 192.168.56.1
sudo /tmp/k8s/control-plane-join.sh
sudo ip route del default via 192.168.56.1

kubectl label node $HOST node-role.kubernetes.io/worker=worker --kubeconfig /tmp/k8s/cluster-admin.conf
