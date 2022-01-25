#!/usr/bin/env bash

echo "##################################################################"
echo "#################### Instalação do Containerd ####################"
echo "##################################################################"

# Configuração para mitigar erro que aparece durante o processo do terminal do Vagrant
export DEBIAN_FRONTEND=noninteractive

# Aqui é onde as coisas começam a ficar um pouco nebulosas. Apesar de os desenvolvedores do Kubernetes falarem que as coisas funcionam sem nenhum ajuste maior, isso só acontece quando você usa do Docker como backend de conteineres. O Docker faz um monte de coisas pra por trás dos panos, que quando você migra para o Containerd você precisa fazer essas configurações de forma manual.

# Configuração de carregamento dos módulos `overlay` e `br_netfilter`
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf > /dev/null
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# O Kubernetes usa uma configuração de bridge para o controlador de rede da máquina host, o que faz com que essa configuração seja necessária para permitir que o iptables faça o devido processamento das cadeias de regras
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes.conf > /dev/null
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF

# Reinicialização do serviço sysctl pois o comando `sysctl -p` dá erro quando roda, por conflito com o daemon do Systemd
systemctl daemon-reload
sudo systemctl restart systemd-sysctl

# Instalação das dependências do Containerd (utils, certificado, repositório)
sudo apt install -y curl gnupg apt-transport-https software-properties-common ca-certificates lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalação do runtime do Containerd
sudo apt update -y
sudo apt install -y containerd.io

# Geração do arquivo de configuração inicial do Containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Configuração do daemon do Containerd para usar o Systemd como driver de cgroup, pois na configuração padrão gerada acima, essa informação não é adicionada, e sem ela os pods ficam eternamente em CrashLoopBackoff
sudo sed -i 's/\[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options\]/&\n            SystemdCgroup = true/' /etc/containerd/config.toml

# Inicialização do serviço do Containerd
sudo systemctl enable containerd
sudo systemctl daemon-reload
sudo systemctl restart containerd
