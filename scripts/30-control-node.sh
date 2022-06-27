#!/usr/bin/env bash

echo "####################################################################"
echo "#################### Instalação do Control Node ####################"
echo "####################################################################"

IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2 }'`
HOST=`hostname -s`

# Limpeza da pasta temporária do projeto
find /tmp/k8s/ -mindepth 1 ! -name .gitkeep -delete

cat <<EOF | tee /tmp/k8s/kubeadm-init.yml > /dev/null
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
    advertiseAddress: "$IP"
    bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
controlPlaneEndpoint: "lb.k8s.cluster:6443"
networking:
    serviceSubnet: "172.16.0.0/16"
    podSubnet: "172.17.0.0/16"
    dnsDomain: "k8s.cluster"
apiServer:
    certSANs:
        - "$HOST"
        - "$IP"
etcd:
    local:
        serverCertSANs:
            - "$HOST"
            - "$IP"
        peerCertSANs:
            - "$HOST"
            - "$IP"
certificatesDir: "/etc/kubernetes/pki"
clusterName: "vagrant-kubernetes-cluster"
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
    strictARP: true
EOF

sudo kubeadm config images pull --config /tmp/k8s/kubeadm-init.yml --v=3

sudo kubeadm init --config /tmp/k8s/kubeadm-init.yml --upload-certs --v=3

#sudo kubeadm init --control-plane-endpoint=$HOST:6443 \
#                  --apiserver-advertise-address=$IP \
#                  --apiserver-cert-extra-sans=$IP \
#                  --pod-network-cidr=172.17.0.0/16 \
#                  --service-cidr=172.16.0.0/16 \
#                  --node-name=$HOST

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Aguardando 60 segundos para o control node inicializar."
sleep 60s

sudo cp -R /etc/kubernetes/pki /tmp/k8s/

# Criando o comando de join dos worker nodes
echo "IP=\$(ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print \$2 }')" > /tmp/k8s/worker-node-join.sh
echo "$(sudo kubeadm token create --print-join-command --config /tmp/k8s/kubeadm-init.yml) --v=3 --apiserver-advertise-address \$IP" >> /tmp/k8s/worker-node-join.sh

# Criando o comando de join dos control nodes
KEY=$(openssl rand -hex 32)
sudo kubeadm init phase upload-certs --upload-certs --certificate-key $KEY
echo "IP=\$(ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print \$2 }')" > /tmp/k8s/control-node-join.sh
echo "$(sudo kubeadm token create --print-join-command --config /tmp/k8s/kubeadm-init.yml) --control-plane --certificate-key $KEY --v=3 --apiserver-advertise-address \$IP" >> /tmp/k8s/control-node-join.sh

sudo cp -f /etc/kubernetes/admin.conf /tmp/k8s/cluster-admin.conf

# Permitindo o agendamento de pods nos control nodes
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "alias k='kubectl'" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc