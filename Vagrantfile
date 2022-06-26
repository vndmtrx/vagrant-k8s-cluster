# -*- mode: ruby -*-
# vi: set ft=ruby :
## https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/

### vagrant plugin install vagrant-reload
### vagrant plugin install vagrant-hosts

IMAGEM = "ubuntu/jammy64"
WORKERS = 2
CONTROLLERS = 2
MEMORIA = 2048
CPUS = 2
OCI = "Containerd"
CNI = "WeaveNet"

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  # Configuração da pasta de montagem dos arquivos gerados pelo control node
  config.vm.synced_folder "./data", "/tmp/k8s", create: true

  config.vm.define "haproxy" do |cn|
    cn.vm.box = IMAGEM
    cn.vm.hostname = "lb.k8s.cluster"
    cn.vm.network "private_network", :ip => "192.168.56.10", :adapter => 2
    cn.vm.provision :hosts, :sync_hosts => true
    cn.vm.provider "virtualbox" do |v|
      v.memory = 512
      v.cpus = 1
      v.default_nic_type = "virtio"
      v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
    end

    cn.vm.provision "shell", path: "scripts/00-haproxy.sh"
  end

  # Configurações de instalação específicas do control node
  config.vm.define "cn-1", primary: true do |cn|
    cn.vm.box = IMAGEM
    cn.vm.hostname = "control-node-1.k8s.cluster"
    cn.vm.network "private_network", :ip => "192.168.56.11", :adapter => 2
    cn.vm.provision :hosts, :sync_hosts => true
    cn.vm.network "forwarded_port", guest: 8001, host: 8001, auto_correct: true
    cn.vm.provider "virtualbox" do |v|
      v.memory = MEMORIA
      v.cpus = CPUS
      v.default_nic_type = "virtio"
      v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
    end

    cn.vm.provision "shell", path: "scripts/01-base.sh"
    cn.vm.provision :reload

    # Seletor do script de instalação da engine de contêiner
    case OCI
    when "Containerd"
      cn.vm.provision "shell", path: "scripts/10-oci-containerd.sh"
    when "CRI-O"
      cn.vm.provision "shell", path: "scripts/10-oci-crio.sh"
    else #Docker
      config.vm.provision "shell", path: "scripts/10-oci-docker.sh"
    end

    # Script de instalação das ferramentas básicas do Kubernetes
    cn.vm.provision "shell", path: "scripts/20-kubeadm-kubelet-kubectl.sh"

    # Script de criação do primeiro control node
    cn.vm.provision "shell", path: "scripts/30-control-node.sh", privileged: false

    # Seletor do script de instalação do plugin de CNI
    case CNI
    when "Flannel"
      cn.vm.provision "shell", path: "scripts/31-cni-flannel.sh", privileged: false
    when "WeaveNet"
      cn.vm.provision "shell", path: "scripts/31-cni-weave-net.sh", privileged: false
    else #Calico
      cn.vm.provision "shell", path: "scripts/31-cni-calico.sh", privileged: false
    end

    # Instalação de vários plugins úteis para o cluster
    cn.vm.provision "shell", path: "scripts/32-metallb.sh", privileged: false
    cn.vm.provision "shell", path: "scripts/33-metrics.sh", privileged: false
    cn.vm.provision "shell", path: "scripts/34-dashboard.sh", privileged: false
    cn.vm.provision "shell", path: "scripts/35-helm.sh", privileged: false
  end

  # Configurações específicas dos outros control nodes
  (2..CONTROLLERS+1).each do |i|
    config.vm.define "cn-#{i}" do |cn|
      cn.vm.box = IMAGEM
      cn.vm.hostname = "control-node-#{i}.k8s.cluster"
      cn.vm.network "private_network", :ip => "192.168.56.#{i+10}", :adapter => 2
      cn.vm.provision :hosts, :sync_hosts => true
      cn.vm.network "forwarded_port", guest: 8001, host: 8001, auto_correct: true
      cn.vm.provider "virtualbox" do |v|
        v.memory = MEMORIA
        v.cpus = CPUS
        v.default_nic_type = "virtio"
        v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
      end

      cn.vm.provision "shell", path: "scripts/01-base.sh"
      cn.vm.provision :reload

      # Seletor do script de instalação da engine de contêiner
      case OCI
      when "Containerd"
        cn.vm.provision "shell", path: "scripts/10-oci-containerd.sh"
      when "CRI-O"
        cn.vm.provision "shell", path: "scripts/10-oci-crio.sh"
      else #Docker
        config.vm.provision "shell", path: "scripts/10-oci-docker.sh"
      end

      # Script de instalação das ferramentas básicas do Kubernetes
      cn.vm.provision "shell", path: "scripts/20-kubeadm-kubelet-kubectl.sh"

      # Criação dos scripts de join para control e worker nodes
      cn.vm.provision "shell", path: "scripts/40-controller-join.sh", privileged: false
    end
  end

  # Configurações específicas dos worker nodes
  (1..WORKERS).each do |i|
    config.vm.define "w-#{i}" do |w|
      w.vm.box = IMAGEM
      w.vm.hostname = "worker-#{i}.k8s.cluster"
      w.vm.network "private_network", :ip => "192.168.56.#{i+20}", :adapter => 2
      w.vm.provision :hosts, :sync_hosts => true
      w.vm.provider "virtualbox" do |v|
        v.memory = MEMORIA
        v.cpus = CPUS
        v.default_nic_type = "virtio"
        v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
      end

      w.vm.provision "shell", path: "scripts/01-base.sh"
      w.vm.provision :reload

      # Seletor do script de instalação da engine de contêiner
      case OCI
      when "Containerd"
        w.vm.provision "shell", path: "scripts/10-oci-containerd.sh"
      when "CRI-O"
        w.vm.provision "shell", path: "scripts/10-oci-crio.sh"
      else #Docker
        w.vm.provision "shell", path: "scripts/10-oci-docker.sh"
      end

      # Script de instalação das ferramentas básicas do Kubernetes
      w.vm.provision "shell", path: "scripts/20-kubeadm-kubelet-kubectl.sh"

      # Script de instalação do worker node e conexão no cluster
      w.vm.provision "shell", path: "scripts/50-worker-join.sh", privileged: false
    end
  end
end
