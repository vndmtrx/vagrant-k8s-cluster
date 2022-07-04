#!/usr/bin/env bash

# Variáveis usadas por vários scripts
export DEBIAN_FRONTEND=noninteractive
export IP=`ip addr show enp0s8 | grep 'inet ' | cut -d/ -f1 | awk '{ print $2 }'`
export HOST=`hostname -s`

# Links usados no projeto (e suas versões)

export YQ_LINK="https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
export KUSTOMIZE_LINK="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"

## CRI-O

export CRIO_OS_VERSION=xUbuntu_22.04
export CRIO_VERSION=1.24
export CRIO_LINK_KR1="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$CRIO_OS_VERSION/Release.key"
export CRIO_LINK_KR2="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$CRIO_OS_VERSION/Release.key"
export CRIO_LINK_REPO1="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$CRIO_OS_VERSION/"
export CRIO_LINK_REPO2="https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$CRIO_OS_VERSION/"

## CALICO CNI

export CALICO_LINK="https://docs.projectcalico.org/manifests/calico.yaml"

## Flannel CNI

export FLANNEL_LINK="https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml"

## MetalLB

export METALLB_MANIFEST="https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml"
export METALLB_DEPLOYMENT="https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml"

## Metrics

export METRICS_DEPLOYMENT="https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml"

## Dashboard

export DASHBOARD_DEPLOYMENT="https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.0/aio/deploy/recommended.yaml"

