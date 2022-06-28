#!/usr/bin/env bash

echo "#####################################################"
echo "############### Instalação do Calico ################"
echo "#####################################################"

curl -fsSLo calico.yaml https://docs.projectcalico.org/manifests/calico.yaml

# Para remover o warning do `PodDisruptionBudget` durante a instalação do CNI, pois
# este foi movido da versão `v1beta1` para a versão `v1` da API.
sed -i '/apiVersion: policy\/v1beta1/s/v1beta1/v1/' calico.yaml

# Se o Calico não funcionar adequadamente com o range de IPs selecionado para os
# pods é necessário editar o arquivo de configuração do Calico, descomentar a opção
# `CALICO_IPV4POOL_CIDR` e alterar o IP para a rede configurada em `--pod-network-cidr`
# no comando `kubeadm init`
#sed -i '/CALICO_IPV4POOL_CIDR/s/# //g' calico.yaml
#sed -i '/value: "192.168.0.0\/16"/s/# //g' calico.yaml
#sed -i 's/value: "192.168.0.0\/16"/value: "172.17.0.0\/16"/g' calico.yaml

kubectl apply -f calico.yaml

echo "Aguardando 30 segundos para o CNI inicializar."
sleep 30s

exit 0