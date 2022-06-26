#!/usr/bin/env bash

echo "###############################################################"
echo "#################### Instalação do MetalLB ####################"
echo "###############################################################"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml

cat <<EOF | tee metallb-config.yml > /dev/null
apiVersion: v1
kind: ConfigMap
metadata:
    namespace: metallb-system
    name: config
data:
    config: |
        address-pools:
        - name: metallb-ip-space
          protocol: layer2
          addresses:
            - 192.168.56.128-192.168.56.255
EOF

kubectl apply -f metallb-config.yml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

echo "Aguardando 30 segundos para o metallb inicializar."
sleep 30s