#!/usr/bin/env bash

echo "####################################################################"
echo "#################### Instalação do Control Node ####################"
echo "####################################################################"

IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2}'`
HOST=`hostname -s`

#echo "$IP $HOST" | sudo tee -a /etc/hosts | sudo tee /tmp/k8s/control-plane-hosts-entry

cat <<EOF | tee /tmp/k8s/kubeadm-init.yml > /dev/null
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
    advertiseAddress: "$IP"
    bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.24.1
controlPlaneEndpoint: "$HOST:6443"
networking:
    serviceSubnet: "172.16.0.0/16"
    podSubnet: "172.17.0.0/16"
    dnsDomain: "k8s.local"
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

sudo kubeadm init --config /tmp/k8s/kubeadm-init.yml --v=3

#sudo kubeadm init --control-plane-endpoint=$HOST:6443 \
#                  --apiserver-advertise-address=$IP \
#                  --apiserver-cert-extra-sans=$IP \
#                  --pod-network-cidr=172.17.0.0/16 \
#                  --service-cidr=172.16.0.0/16 \
#                  --node-name=$HOST

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "alias k='kubectl'" >> ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc