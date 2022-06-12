#!/usr/bin/env bash

echo "###################################################################"
echo "############### Geração do comando de Join do Node ################"
echo "###################################################################"

kubeadm token create --print-join-command | tee /tmp/k8s/control-plane-join.sh
sudo cp -f /etc/kubernetes/admin.conf /tmp/k8s/cluster-admin.conf

sleep 30s

# Permitindo o agendamento de pods no control-plane
kubectl taint nodes --all node-role.kubernetes.io/master-

#kubectl get pods -n kube-system -o wide
#kubectl get nodes -o wide
