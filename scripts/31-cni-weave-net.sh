#!/usr/bin/env bash

echo "########################################################"
echo "############### Instalação do Weave Net ################"
echo "########################################################"


kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=172.17.0.0/16"