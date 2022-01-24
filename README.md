# Vagrant K8s Cluster

Instalar um cluster Kubernetes não é mais tão difícil quanto era antes do surgimento de ferramentas como Minikube, k3s e kubeadm, no entanto ainda existem várias pequenas coisas que precisam ser feitas em uma instalação do cluster, que só vamos descobrindo durante o processo de instalação e depuração dos erros que vão aparecendo.

## Instalação das dependências

### Docker e/ou Containerd

Primeiramente, para a montagem deste tutorial foi feita a instalação do cluster com o Docker, seguindo as configurações de instalação da [Documentação do Docker](https://docs.docker.com/engine/install/) e resumidas no script de instalação `scripts/base-containerd.sh`

# Getting started

```
vagrant up
```

## To check the cluster status

```
vagrant ssh control-node -c "kubectl get pods -n kube-system"
vagrant ssh control-node -c "kubectl get nodes"
```

## To check the cluster memory and CPU usage

```
vagrant ssh control-node -c "kubectl top pod -n kube-system"
vagrant ssh control-node -c "kubectl top nodes"
```

## To connect to the dashboard

First, you have to get the admin token created on kubernetes secret

```
vagrant ssh control-node -c "kubectl -n kube-system get secret --template='{{.data.token}}' \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}') | base64 --decode ; echo"
```

After that, you run kubectl proxy on the console to output the dashboard endpoint

```
vagrant ssh control-node -c "kubectl proxy"

```

After this, you can access the dashboard on the URL: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ using the token retrieved before.

# Destroying everything and freeing resources


```
vagrant destroy -f
```
