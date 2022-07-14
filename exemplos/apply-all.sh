#!/usr/bin/env bash

find /vagrant/exemplos/ -type f -name "*.yaml" -print0 | sort -z | xargs -0 -L 1 kubectl apply -f