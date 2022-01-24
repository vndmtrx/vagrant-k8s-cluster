# -*- mode: ruby -*-
# vi: set ft=ruby :
## https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/

IMAGE_NAME = "ubuntu/impish64"
N = 2
OCI = "Containerd"
CNI = "Calico"

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  config.vm.network "public_network"

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.synced_folder "./data", "/tmp/k8s", create: true

  config.vm.define "control-node" do |cn|
    cn.vm.box = IMAGE_NAME
    cn.vm.hostname = "control-node"
    cn.vm.network "forwarded_port", guest: 8001, host: 8001, auto_correct: true
    cn.vm.provider "virtualbox" do |v|
      v.memory = 3072
      v.cpus = 3
      v.customize ["modifyvm", :id, "--natnet1", "169.254.0.0/16"]
    end

    cn.vm.provision "shell", path: "scripts/30-control-node.sh", privileged: false

    case CNI
    when "Flannel"
      cn.vm.provision "shell", path: "scripts/31-cni-flannel.sh", privileged: false
    else #Calico
      cn.vm.provision "shell", path: "scripts/31-cni-calico.sh", privileged: false
    end

    cn.vm.provision "shell", path: "scripts/32-cluster-join.sh", privileged: false
    cn.vm.provision "shell", path: "scripts/33-metrics.sh", privileged: false
    cn.vm.provision "shell", path: "scripts/34-dashboard.sh", privileged: false
  end

  (1..N).each do |i|
    config.vm.define "worker-#{i}" do |w|
      w.vm.box = IMAGE_NAME
      w.vm.hostname = "worker-#{i}"
      w.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 2
        v.customize ["modifyvm", :id, "--natnet1", "169.254.0.0/16"]
      end

      w.vm.provision "shell", path: "scripts/40-worker-node.sh"
    end
  end

  case OCI
  when "Containerd"
    config.vm.provision "shell", path: "scripts/10-oci-containerd.sh"
  else #Docker
    config.vm.provision "shell", path: "scripts/10-oci-docker.sh"
  end

  config.vm.provision "shell", path: "scripts/20-kubeadm-kubelet-kubectl.sh"
end
