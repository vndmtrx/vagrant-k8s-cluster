#!/usr/bin/env bash

echo "####################################################"
echo "############### Join do Worker node ################"
echo "####################################################"

# Importação das variáveis comuns usadas por todo o projeto
source /vagrant/scripts/00-envvars.sh

sudo cp -rv /tmp/k8s/certs/registry.crt /usr/local/share/ca-certificates/registry.crt
sudo update-ca-certificates

chmod 0755 /tmp/k8s/worker-node-join.sh

sudo /tmp/k8s/worker-node-join.sh

kubectl label node $HOST node-role.kubernetes.io/worker=worker --kubeconfig /tmp/k8s/cluster-admin.conf

exit 0