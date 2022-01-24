#!/usr/bin/env bash

echo "#################################################################"
echo "############### Instalação do plugin de métricas ################"
echo "#################################################################"

curl -fsSLo kubernetes-metrics.yaml https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.4/components.yaml
sed -i 's/secure-port=4443/&\n        - --kubelet-insecure-tls/' kubernetes-metrics.yaml

kubectl apply -f kubernetes-metrics.yaml

#kubectl top pods -n kube-system
#kubectl top nodes
