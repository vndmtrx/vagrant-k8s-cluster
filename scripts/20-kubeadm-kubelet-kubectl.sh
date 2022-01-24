#!/usr/bin/env bash

echo "#########################################################################"
echo "############### Instalação do Kubelet, Kubeadm e Kubectl ################"
echo "#########################################################################"

# Configuração para mitigar erro que aparece durante o processo do terminal do Vagrant
export DEBIAN_FRONTEND=noninteractive

# Desativação do swap conforme orientação do kubeadm (https://github.com/kubernetes/kubeadm/issues/610)
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

# Desativação do firewall do Ubuntu, para tratar de problemas ainda não verificados no cluster
sudo ufw disable

# Instalação das dependências (certificado, repositório)
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

# Instalação do Kubeadm, Kubelet e Kubectl
sudo apt update -y
sudo apt install kubelet kubeadm kubectl -y

# Travamento da versão do Kubeadm, Kubelet e Kubectl
sudo apt-mark hold kubelet kubeadm kubectl
