#!/usr/bin/env bash

cat <<EOF | sudo tee /etc/sysctl.d/99-local-routing.conf > /dev/null
net.ipv4.conf.enp0s3.route_localnet=1
EOF

sudo systemctl restart systemd-sysctl

sudo iptables -t nat -I PREROUTING -p tcp -d 169.254.0.15/32 --dport 8001 -j DNAT --to-destination 127.0.0.1:8001

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml

cat <<EOF | tee dashboard-adminuser.yml > /dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
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
  namespace: kube-system
EOF

kubectl apply -f admin-role-binding.yml
