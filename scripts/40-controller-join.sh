#!/usr/bin/env bash

echo "#####################################################################"
echo "############### Geração do comando de Join dos Nodes ################"
echo "#####################################################################"

IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2}'`
HOST=`hostname -s`

chmod 0755 /tmp/k8s/control-node-join.sh

sudo /tmp/k8s/control-node-join.sh

echo "Aguardando 30 segundos para o control node inicializar."
sleep 30s

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "alias k='kubectl'" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

# Permitindo o agendamento de pods no control-plane
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

exit 0