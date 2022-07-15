#!/usr/bin/env bash

echo "#######################################################"
echo "######################### NFS #########################"
echo "#######################################################"

# Importação das variáveis comuns usadas por todo o projeto
source /vagrant/scripts/00-envvars.sh

ufw disable

apt-get install -yq nfs-kernel-server

mkdir -p /mnt/nfs/nfs{1,2}
chown nobody:nogroup /mnt/nfs/nfs1{1,2}
chmod 0777 /mnt/nfs/nfs{1,2}

cat <<EOF | tee -a /etc/exports > /dev/null
/mnt/nfs/nfs1 192.168.56.0/24(rw,sync,no_subtree_check)
/mnt/nfs/nfs2 192.168.56.0/24(rw,sync,no_subtree_check)
EOF

exportfs -ra
systemctl restart nfs-kernel-server