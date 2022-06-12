#!/usr/bin/env bash

echo "#################################################################"
echo "####################### Configuração Base #######################"
echo "#################################################################"

apt-get install -yq jq
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64

sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0"/g' /etc/default/grub
update-grub2
