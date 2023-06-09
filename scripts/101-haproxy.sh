#!/usr/bin/env bash

echo "#######################################################"
echo "####################### HAProxy #######################"
echo "#######################################################"

# Importação das variáveis comuns usadas por todo o projeto
source /vagrant/scripts/00-envvars.sh

# Atualização do timezone das máquinas
timedatectl set-timezone America/Sao_Paulo

apt-get install -yq haproxy

cat <<EOF | tee -a /etc/haproxy/haproxy.cfg > /dev/null
frontend stats
    bind *:8081
    stats enable
    stats uri /apiserver-stats
    stats refresh 10s
    stats show-node
    stats admin if TRUE     
    stats auth admin:admin

frontend kube-apiserver
    bind *:6443
    mode tcp
    option tcplog
    default_backend kube-apiserver
   
backend kube-apiserver
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server kube-apiserver-1 192.168.56.11:6443 check
    server kube-apiserver-2 192.168.56.12:6443 check
    server kube-apiserver-3 192.168.56.13:6443 check
EOF

systemctl restart haproxy

exit 0