#!/usr/bin/env bash

echo "#####################################################################"
echo "############### Instalação de um serviço de registry ################"
echo "#####################################################################"

# Importação das variáveis comuns usadas por todo o projeto
source /vagrant/scripts/00-envvars.sh

mkdir -p /tmp/k8s/certs
openssl req \
    -newkey rsa:4096 -nodes -sha256 \
    -addext "subjectAltName = IP:192.168.56.250" -x509 -days 3650 \
    -subj "/C=BR/ST=Parana/L=Curitiba" \
    -keyout "/tmp/k8s/certs/registry.key" \
    -out "/tmp/k8s/certs/registry.crt"

sudo cp -rv /tmp/k8s/certs/registry.crt /usr/local/share/ca-certificates/registry.crt
sudo update-ca-certificates

cat <<EOF | tee registry-namespace.yml > /dev/null
kind: Namespace
apiVersion: v1
metadata:
    name: registry
EOF

kubectl apply -f registry-namespace.yml

#kubectl -n registry create secret tls registry-cert \
#    --cert=/tmp/k8s/certs/registry.crt \
#    --key=/tmp/k8s/certs/registry.key

cat <<EOF | tee registry-cert.yml > /dev/null
type: kubernetes.io/tls
kind: Secret
apiVersion: v1
metadata:
    name: registry-cert
    namespace: registry
data:
    tls.crt: $(cat /tmp/k8s/certs/registry.crt | base64 -w 0)
    tls.key: $(cat /tmp/k8s/certs/registry.key | base64 -w 0)
EOF

kubectl apply -f registry-cert.yml

cat <<EOF | tee registry-pv.yml > /dev/null
apiVersion: v1
kind: PersistentVolume
metadata:
  name: registry-data-pv
  namespace: registry
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: nfs-registry
  nfs:
    server: nfs.k8s.cluster
    path: "/mnt/nfs/registry"
  mountOptions:
    - hard
    - nfsvers=4.2
EOF

kubectl apply -f registry-pv.yml

cat <<EOF | tee registry-pvc.yml > /dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-data-pvc
  namespace: registry
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-registry
  resources:
    requests:
      storage: 20Gi
EOF

kubectl apply -f registry-pvc.yml

cat <<EOF | tee registry-deployment.yml > /dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: registry
  labels:
    run: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      run: registry
  template:
    metadata:
      labels:
        run: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
          env:
            - name: REGISTRY_HTTP_TLS_CERTIFICATE
              value: "/certs/tls.crt"
            - name: REGISTRY_HTTP_TLS_KEY
              value: "/certs/tls.key"
          volumeMounts:
            - name: registry-certs
              mountPath: "/certs"
              readOnly: true
            - name: registry-data
              mountPath: /var/lib/registry
              subPath: registry
      volumes:
        - name: registry-certs
          secret:
            secretName: registry-cert
        - name: registry-data
          persistentVolumeClaim:
            claimName: registry-data-pvc
EOF

kubectl apply -f registry-deployment.yml

cat <<EOF | tee registry-pvc.yml > /dev/null
apiVersion: v1
kind: Service
metadata:
  name: registry-service
  namespace: registry
spec:
  type: LoadBalancer
  selector:
    run: registry
  ports:
    - name: registry-tcp
      protocol: TCP
      port: 5000
      targetPort: 5000
  loadBalancerIP: 192.168.56.250
EOF

kubectl apply -f registry-pvc.yml

# Solução para o problema do docker push no cliente: https://stackoverflow.com/questions/50768317/docker-pull-certificate-signed-by-unknown-authority/60009334#60009334

exit 0