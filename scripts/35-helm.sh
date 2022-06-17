#!/usr/bin/env bash

echo "#######################################################################"
echo "############### Instalação gerenciador de pacotes Helm ################"
echo "#######################################################################"

curl -fsSLo helm.tar.gz https://get.helm.sh/helm-v3.8.0-linux-amd64.tar.gz

tar -xvzf helm.tar.gz
sudo cp -Rv linux-amd64/helm /usr/local/bin/helm
