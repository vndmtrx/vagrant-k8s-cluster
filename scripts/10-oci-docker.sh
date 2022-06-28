#!/usr/bin/env bash

echo "##############################################################"
echo "#################### Instalação do Docker ####################"
echo "##############################################################"

# Configuração para mitigar erro que aparece durante o processo do terminal do Vagrant
export DEBIAN_FRONTEND=noninteractive

# Instalação das dependências do Docker (utils, certificado, repositório)
apt-get install -yq curl gnupg apt-transport-https software-properties-common ca-certificates lsb-release bash-completion
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalação do runtime do Docker
apt-get update -yq
apt-get install docker-ce docker-ce-cli containerd.io -yq

# Configuração do daemon do Docker para usar o Systemd como driver de cgroup
cat <<EOF | tee /etc/docker/daemon.json  > /dev/null
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
systemctl enable docker
systemctl daemon-reload
systemctl restart docker

exit 0