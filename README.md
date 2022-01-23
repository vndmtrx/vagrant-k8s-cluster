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

# Destroying everything and freeing resources


```
vagrant destroy -f
```
