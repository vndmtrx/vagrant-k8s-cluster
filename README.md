# Vagrant K8s Cluster

This is the first of a series of repositories about deploying devops solutions for study, on the local machine.

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

# Work in progress...

## To connect to the dashboard

```
vagrant ssh control-node -c "kubectl -n kube-system get secret --template='{{.data.token}}' \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}') | base64 --decode ; echo"
vagrant ssh control-node -c "kubectl proxy"

```

You can access the dashboard on the URL: http://localhost:9001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

```
vagrant destroy -f
```
