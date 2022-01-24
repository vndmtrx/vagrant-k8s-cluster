#!/usr/bin/env bash

echo "#################### Instalação do Control Node ####################"
IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2}'`

HOST=`hostname -s`.cluster

echo "$IP $HOST" | sudo tee -a /etc/hosts | sudo tee /tmp/k8s/hosts-entry

sudo kubeadm init --control-plane-endpoint="$HOST:6443" --apiserver-advertise-address=$IP --apiserver-cert-extra-sans=$IP --pod-network-cidr=172.16.0.0/16 --service-cidr=172.17.0.0/16 --node-name=$HOST

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

#kubectl patch node $HOST -p '{"spec":{"podCIDR":"172.16.0.0/16"}}'
#kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
#Qdo fizer para Flannel, atentar a isso aqui: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/#default-nic-when-using-flannel-as-the-pod-network-in-vagrant

kubeadm token create --print-join-command | tee /tmp/k8s/control-node-join.sh
sudo cp -f /etc/kubernetes/admin.conf /tmp/k8s/cluster-admin.conf

curl -fsSLo kubernetes-metrics.yaml https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.4/components.yaml
sed -i 's/secure-port=4443/&\n        - --kubelet-insecure-tls/' kubernetes-metrics.yaml
kubectl apply -f kubernetes-metrics.yaml

#kubectl get po -n kube-system
#kubectl get nodes

#kubectl top node
#kubectl top pod -n kube-system
