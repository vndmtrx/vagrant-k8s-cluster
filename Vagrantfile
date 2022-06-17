# -*- mode: ruby -*-
# vi: set ft=ruby :
## https://kubernetes.io/blog/2019/03/15/kubernetes-setup-using-ansible-and-vagrant/

### vagrant plugin install vagrant-reload
### vagrant plugin install vagrant-hosts

IMAGEM = "ubuntu/jammy64"
WORKERS = 2
MEMORIA = 2048
CPUS = 2
OCI = "Containerd"
CNI = "Calico"

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  # Configuração da pasta de montagem dos arquivos gerados pelo control node
  config.vm.synced_folder "./data", "/tmp/k8s", create: true

  # Para funcionar, é necessário instalar o plugin vagrant-reload: vagrant plugin install vagrant-reload
  config.vm.provision "shell", path: "scripts/00-base.sh"
  config.vm.provision :reload

  # Seletor do script de instalação da engine de contêiner
  case OCI
  when "Containerd"
    config.vm.provision "shell", path: "scripts/10-oci-containerd.sh"
  when "CRI-O"
    config.vm.provision "shell", path: "scripts/10-oci-crio.sh"
  else #Docker
    config.vm.provision "shell", path: "scripts/10-oci-docker.sh"
  end

  # Script de instalação das ferramentas básicas do Kubernetes
  config.vm.provision "shell", path: "scripts/20-kubeadm-kubelet-kubectl.sh"

  # Configurações de instalação específicas do control node
  config.vm.define "control-plane" do |cn|
    cn.vm.box = IMAGEM
    cn.vm.hostname = "control-plane"
    cn.vm.network "private_network", :ip => "192.168.56.10", :adapter => 2
    cn.vm.provision :hosts, :sync_hosts => true
    cn.vm.network "forwarded_port", guest: 8001, host: 8001, auto_correct: true
    cn.vm.provider "virtualbox" do |v|
      v.memory = MEMORIA
      v.cpus = CPUS
      v.customize ["modifyvm", :id, "--natnet1", "169.254.0.0/16"]
    end

    cn.vm.provision "shell", path: "scripts/30-control-plane.sh", privileged: false

    case CNI
    when "Flannel"
      cn.vm.provision "shell", path: "scripts/31-cni-flannel.sh", privileged: false
    else #Calico
      cn.vm.provision "shell", path: "scripts/31-cni-calico.sh", privileged: false
    end

    cn.vm.provision "shell", path: "scripts/32-cluster-join.sh", privileged: false
    cn.vm.provision "shell", path: "scripts/33-metrics.sh", privileged: false
    cn.vm.provision "shell", path: "scripts/34-dashboard.sh", privileged: false
    cn.vm.provision "shell", path: "scripts/35-helm.sh", privileged: false
  end

  # Configurações específicas dos worker nodes
  (1..WORKERS).each do |i|
    config.vm.define "worker-#{i}" do |w|
      w.vm.box = IMAGEM
      w.vm.hostname = "worker-#{i}"
      w.vm.network "private_network", :ip => "192.168.56.#{i+10}", :adapter => 2
      w.vm.provision :hosts, :sync_hosts => true
      w.vm.provider "virtualbox" do |v|
        v.memory = MEMORIA
        v.cpus = CPUS
        v.customize ["modifyvm", :id, "--natnet1", "169.254.0.0/16"]
      end

      w.vm.provision "shell", path: "scripts/40-worker-node.sh", privileged: false
    end
  end
end
