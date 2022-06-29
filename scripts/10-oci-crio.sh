#!/usr/bin/env bash

echo "##############################################################"
echo "#################### Instalação do CRI-O ####################"
echo "##############################################################"

# Configuração para mitigar erro que aparece durante o processo do terminal do Vagrant
export DEBIAN_FRONTEND=noninteractive

export OS_VERSION=xUbuntu_22.04
export CRIO_VERSION=1.24

# Configuração de carregamento dos módulos `overlay` e `br_netfilter`
cat <<EOF | tee /etc/modules-load.d/containerd.conf > /dev/null
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# O Kubernetes usa uma configuração de bridge para o controlador de rede da máquina
# host, o que faz com que essa configuração seja necessária para permitir que o
# iptables faça o devido processamento das cadeias de regras
cat <<EOF | tee /etc/sysctl.d/99-kubernetes.conf > /dev/null
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF

# Reinicialização do serviço sysctl pois o comando `sysctl --system` dá erro quando
# roda, por conflito com o daemon do Systemd
systemctl daemon-reload
systemctl restart systemd-sysctl

# Instalação das dependências do CRI-O (utils, certificado, repositório)
apt-get install -yq curl gnupg apt-transport-https software-properties-common ca-certificates lsb-release bash-completion
curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS_VERSION/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
curl -fsSL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS_VERSION/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS_VERSION/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS_VERSION/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list

# Instalação do runtime do CRI-O
apt-get update -yq
apt-get install cri-o cri-o-runc -yq

# Inicialização do serviço do CRI-O
sudo systemctl daemon-reload
sudo systemctl enable crio
sudo systemctl start crio

exit 0