#!/usr/bin/env bash

echo "#################### Join do Worker ####################"
cat /tmp/k8s/hosts-entry | sudo tee -a /etc/hosts
chmod 0755 /tmp/k8s/control-node-join.sh
/tmp/k8s/control-node-join.sh
