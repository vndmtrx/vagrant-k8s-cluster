#!/usr/bin/env bash

echo "##################################################################"
echo "#################### Instalação do Containerd ####################"
echo "##################################################################"

# Configuração para mitigar erro que aparece durante o processo do terminal do Vagrant
export DEBIAN_FRONTEND=noninteractive

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

# Instalação das dependências do Containerd (utils, certificado, repositório)
apt-get install -yq curl gnupg apt-transport-https software-properties-common ca-certificates lsb-release bash-completion
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalação do runtime do Containerd
apt-get update -yq
apt-get install -yq containerd.io

# Geração do arquivo de configuração inicial do Containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null

# Configuração do daemon do Containerd para usar o Systemd como driver de cgroup,
# pois na configuração padrão gerada acima, essa informação não é adicionada, e
# sem ela os pods ficam eternamente em CrashLoopBackoff
#sed -i 's/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options\]/&\n            SystemdCgroup = true/' /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Inicialização do serviço do Containerd
systemctl enable containerd
systemctl daemon-reload
systemctl restart containerd

exit 0