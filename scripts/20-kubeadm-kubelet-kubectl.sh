#!/usr/bin/env bash

echo "#########################################################################"
echo "############### Instalação do Kubelet, Kubeadm e Kubectl ################"
echo "#########################################################################"

# Configuração para mitigar erro que aparece durante o processo do terminal do Vagrant
export DEBIAN_FRONTEND=noninteractive

# Desativação do swap conforme orientação do kubeadm (https://github.com/kubernetes/kubeadm/issues/610)
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# Desativação do firewall do Ubuntu, para tratar de problemas ainda não verificados no cluster
ufw disable

# Instalação das dependências (certificado, repositório)
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# Instalação do Kubeadm, Kubelet e Kubectl
apt-get update -yq
apt-get install kubelet kubeadm kubectl -yq

# Travamento da versão do Kubeadm, Kubelet e Kubectl
apt-mark hold kubelet kubeadm kubectl
