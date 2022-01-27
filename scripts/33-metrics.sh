#!/usr/bin/env bash

echo "#################################################################"
echo "############### Instalação do plugin de métricas ################"
echo "#################################################################"

curl -fsSLo kubernetes-metrics.yaml https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.4/components.yaml
sed -i 's/secure-port=4443/&\n        - --kubelet-insecure-tls/' kubernetes-metrics.yaml

kubectl apply -f kubernetes-metrics.yaml

cat <<EOF | tee metrics-patch.yml > /dev/null
spec:
  template:
    spec:
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
        - key: "node-role.kubernetes.io/master"
          operator: "Exists"
          effect: "NoSchedule"
EOF

kubectl patch deployment metrics-server -n kube-system --patch-file metrics-patch.yml

#kubectl top pods -n kube-system
#kubectl top nodes
