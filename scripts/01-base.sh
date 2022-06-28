#!/usr/bin/env bash

echo "#################################################################"
echo "####################### Configuração Base #######################"
echo "#################################################################"

# Configuração para mitigar erro que aparece durante o processo do terminal do Vagrant
export DEBIAN_FRONTEND=noninteractive

# Instalação do jq e do yamllint para interagir com as saídas do kubectl
apt-get update -yq
apt-get install -yq jq yamllint

# Insatalação do yq
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
chmod 0755 /usr/local/bin/yq

# Instalação do Kustomize
cd /usr/local/bin/ && (curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash) && cd

sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0"/g' /etc/default/grub
update-grub2

exit 0