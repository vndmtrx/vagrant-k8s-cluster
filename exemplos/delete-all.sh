#!/usr/bin/env bash

find /vagrant/exemplos/ -type f -name "*.yaml" -print0 | sort -rz | xargs -0 -L 1 kubectl delete -f