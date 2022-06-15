#!/usr/bin/env bash

echo "###################################################################"
echo "############### Geração do comando de Join do Node ################"
echo "###################################################################"


# Hack para fazer o comando `kubeadm token create` funcionar usando a interface de rede
# No entanto, esse hack é ineficiente, no que deverá ser alterado para usar um arquivo de
# config, conforme https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/
IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2}'`

sudo ip route add default via 192.168.56.1
kubeadm token create --print-join-command | tee /tmp/k8s/control-plane-join.sh
sudo ip route del default via 192.168.56.1

sudo cp -f /etc/kubernetes/admin.conf /tmp/k8s/cluster-admin.conf

sleep 60s

# Permitindo o agendamento de pods no control-plane
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

#kubectl get pods -n kube-system -o wide
#kubectl get nodes -o wide
