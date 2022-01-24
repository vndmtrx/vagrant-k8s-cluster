#!/usr/bin/env bash

echo "#####################################################"
echo "############### Instalação do Calico ################"
echo "#####################################################"

# Se o Calico não funcionar adequadamente com o range de IPs selecionado para os pods é necessário editar o arquivo de configuração do Calico, descomentar a opção `CALICO_IPV4POOL_CIDR` e alterar o IP para a rede configurada em `--pod-network-cidr` no comando `kubeadm init`
curl -fsSLo calico.yaml https://docs.projectcalico.org/manifests/calico.yaml
#sed -i '/CALICO_IPV4POOL_CIDR/s/# //g' calico.yaml
#sed -i '/value: "192.168.0.0\/16"/s/# //g' calico.yaml
#sed -i 's/value: "192.168.0.0\/16"/value: "172.17.0.0\/16"/g' calico.yaml

kubectl apply -f calico.yaml
