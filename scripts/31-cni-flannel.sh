#!/usr/bin/env bash

echo "######################################################"
echo "############### Instalação do Flannel ################"
echo "######################################################"

#kubectl patch node $HOST -p '{"spec":{"podCIDR":"172.16.0.0/16"}}'
#kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
#Qdo fizer para Flannel, atentar a isso aqui: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/#default-nic-when-using-flannel-as-the-pod-network-in-vagrant

exit -1
