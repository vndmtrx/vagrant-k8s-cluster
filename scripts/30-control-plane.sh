#!/usr/bin/env bash

echo "####################################################################"
echo "#################### Instalação do Control Node ####################"
echo "####################################################################"

IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2}'`

HOST=`hostname -s`.cluster

echo "$IP $HOST" | sudo tee -a /etc/hosts | sudo tee /tmp/k8s/hosts-entry

sudo kubeadm init --control-plane-endpoint=$HOST:6443 --apiserver-advertise-address=$IP --apiserver-cert-extra-sans=$IP --pod-network-cidr=172.17.0.0/16 --service-cidr=172.16.0.0/16 --node-name=$HOST

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "alias k='kubectl'" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc