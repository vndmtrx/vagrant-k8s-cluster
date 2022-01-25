#!/usr/bin/env bash

echo "##############################################################"
echo "#################### Instalação do Docker ####################"
echo "##############################################################"

# Configuração para mitigar erro que aparece durante o processo do terminal do Vagrant
export DEBIAN_FRONTEND=noninteractive

# Instalação das dependências do Docker (utils, certificado, repositório)
sudo apt install -y curl gnupg apt-transport-https software-properties-common ca-certificates lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalação do runtime do Docker
sudo apt update -y
sudo apt install docker-ce docker-ce-cli containerd.io -y

# Configuração do daemon do Docker para usar o Systemd como driver de cgroup
cat <<EOF | sudo tee /etc/docker/daemon.json  > /dev/null
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Inicialização do serviço do Docker
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
