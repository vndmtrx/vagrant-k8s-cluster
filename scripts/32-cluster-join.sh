#!/usr/bin/env bash

echo "###################################################################"
echo "############### Geração do comando de Join do Node ################"
echo "###################################################################"

IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2}'`
HOST=`hostname -s`

kubeadm token create --print-join-command --config /tmp/k8s/kubeadm-init.yml | tee /tmp/k8s/control-plane-join.sh

sudo cp -f /etc/kubernetes/admin.conf /tmp/k8s/cluster-admin.conf

sleep 60s

# Permitindo o agendamento de pods no control-plane
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

#kubectl get pods -n kube-system -o wide
#kubectl get nodes -o wide
