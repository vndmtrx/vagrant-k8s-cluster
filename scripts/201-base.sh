#!/usr/bin/env bash

echo "#################################################################"
echo "####################### Configuração Base #######################"
echo "#################################################################"

# Importação das variáveis comuns usadas por todo o projeto
source /vagrant/scripts/00-envvars.sh

# Instalação do jq e do yamllint para interagir com as saídas do kubectl
apt-get update -yq
apt-get install -yq jq yamllint

# Instalação das ferramentas de montagem do NFS
apt-get install -yq nfs-common

# Insatalação do yq
curl -fsSLo /usr/local/bin/yq $YQ_LINK
chmod 0755 /usr/local/bin/yq

# Instalação do Kustomize
cd /usr/local/bin/ && (curl -s "$KUSTOMIZE_LINK" | bash) && cd

sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0"/g' /etc/default/grub
update-grub2 2>&1

exit 0