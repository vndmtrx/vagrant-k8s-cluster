#!/usr/bin/env bash

echo "######################################################"
echo "############### Instalação do Flannel ################"
echo "######################################################"

# Importação das variáveis comuns usadas por todo o projeto
source /vagrant/scripts/00-envvars.sh

#kubectl patch node $HOST -p '{"spec":{"podCIDR":"172.17.0.0/16"}}'

curl -fsSLo kube-flannel.yaml $FLANNEL_LINK

# Internamente o Flannel está tentando pegar a primeira interface de rede, ligada
# ao NAT do vagrant, e portanto não acessível externamente.
sed -i 's/kube-subnet-mgr/&\n        - --iface=enp0s8/' kube-flannel.yaml

# O Flannel por padrão vêm com a rede `10.244.0.0/16` configurada para o parâmetro
# `FLANNEL_NETWORK`, que pode ser visto no arquivo `/run/flannel/subnet.env`.
# Para manter o mesmo padrão de rede usado no projeto, mudamos o valor no ConfigMap
# para o valor que está definido para a nossa rede de pods.
# Explicação: https://blog.laputa.io/kubernetes-flannel-networking-6a1cb1f8ec7c
sed -i 's/10.244.0.0\/16/172.17.0.0\/16/g' kube-flannel.yaml

kubectl apply -f kube-flannel.yaml
#Qdo fizer para Flannel, atentar a isso aqui: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/#default-nic-when-using-flannel-as-the-pod-network-in-vagrant

echo "Aguardando 30 segundos para o CNI inicializar."
sleep 30s

exit 0