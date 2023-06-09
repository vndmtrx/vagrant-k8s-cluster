#!/usr/bin/env bash

echo "#######################################################"
echo "######################### NFS #########################"
echo "#######################################################"

# Importação das variáveis comuns usadas por todo o projeto
source /vagrant/scripts/00-envvars.sh

# Atualização do timezone das máquinas
timedatectl set-timezone America/Sao_Paulo

ufw disable

apt-get install -yq nfs-kernel-server

mkdir -p /mnt/nfs/nfs{1,2}
chown nobody:nogroup /mnt/nfs/nfs{1,2}
chmod 0777 /mnt/nfs/nfs{1,2}

mkdir -p /mnt/nfs/registry
chown nobody:nogroup /mnt/nfs/registry
chmod 0777 /mnt/nfs/registry

cat <<EOF | tee -a /etc/exports > /dev/null
/mnt/nfs/nfs1 192.168.56.0/24(rw,sync,no_subtree_check)
/mnt/nfs/nfs2 192.168.56.0/24(rw,sync,no_subtree_check)
/mnt/nfs/registry 192.168.56.0/24(rw,sync,no_subtree_check)
EOF

exportfs -ra
systemctl restart nfs-kernel-server

exit 0