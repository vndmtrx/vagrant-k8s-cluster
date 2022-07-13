#!/usr/bin/env bash

echo "##################################################################"
echo "############### Instalação do plugin de dashboard ################"
echo "##################################################################"

# Importação das variáveis comuns usadas por todo o projeto
source /vagrant/scripts/00-envvars.sh

# Configuração do kernel para permitir o roteamento de tráfego entre interfaces
# de rede locais
cat <<EOF | sudo tee /etc/sysctl.d/99-local-routing.conf > /dev/null
net.ipv4.conf.enp0s3.route_localnet=1
EOF

# Reinicialização do serviço sysctl pois o comando `sysctl -p` dá erro quando roda,
# por conflito com o daemon do Systemd
sudo systemctl daemon-reload
sudo systemctl restart systemd-sysctl

# Criação de regra no iptables que redireciona o tráfego de rede que chegar na
# interface NAT do control node diretamente para a interface lo, permitindo assim
# o acesso ao dashboard usando a forwarded port configurada no `Vagrantfile`
sudo iptables -t nat -I PREROUTING -p tcp -d 169.254.0.15/32 --dport 8001 -j DNAT --to-destination 127.0.0.1:8001

kubectl apply -f $DASHBOARD_DEPLOYMENT

cat <<EOF | tee dashboard-adminuser.yml > /dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f dashboard-adminuser.yml

cat <<EOF | tee admin-role-binding.yml > /dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f admin-role-binding.yml

cat <<EOF | tee dashboard-nodeport.yml > /dev/null
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-np
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 32000
  selector:
    k8s-app: kubernetes-dashboard
  type: NodePort
EOF

kubectl apply -f dashboard-nodeport.yml

cat <<EOF | tee dashboard-loadbalancer.yml > /dev/null
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-lb
  namespace: kubernetes-dashboard
spec:
  ports:
    - port: 443
      protocol: TCP
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
  type: LoadBalancer
EOF

kubectl apply -f dashboard-loadbalancer.yml

kubectl config set-credentials kubernetes-admin --token="$(openssl rand -hex 64)"
kubectl config view --raw > /tmp/k8s/kubeconfig-dashboard.yaml

sleep 10s

echo "Dashboard acessível no endereço https://$IP:32000"
echo "Dashboard também estará acessível no endereço https://$(kubectl get services --namespace kubernetes-dashboard kubernetes-dashboard-lb --output jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "Para gerar o token, use kubectl -n kubernetes-dashboard create token admin-user"
echo "Também é possível usar o arquivo kubeconfig-dashboard.yaml presente na subpasta data/ dentro da pasta do Vagrant."

#Não usar mais: kubectl -n kube-system get secret --template='{{.data.token}}' $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') | base64 --decode ; echo
# kubectl -n kubernetes-dashboard create token admin-user
#kubectl proxy --accept-hosts='.*'
#http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

exit 0