# Work that needs to be done...

## To connect to the dashboard

```
vagrant ssh control-node -c "kubectl -n kube-system get secret --template='{{.data.token}}' \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}') | base64 --decode ; echo"
vagrant ssh control-node -c "kubectl proxy"

```

You can access the dashboard on the URL: http://localhost:9001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
