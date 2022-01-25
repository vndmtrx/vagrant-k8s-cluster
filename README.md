# Vagrant K8s Cluster

Instalar um cluster Kubernetes não é mais tão difícil quanto era antes do surgimento de ferramentas como Minikube, k3s e kubeadm, no entanto ainda existem várias pequenas coisas que precisam ser feitas em uma instalação do cluster, que só vamos descobrindo durante o processo de instalação e depuração dos erros que vão aparecendo.

## Configurações da instalação

### Opiniões assumidas sobre algumas configurações

Uma coisa para qual esse repositório foi pensado foi a de ser possível customizar a instalação do cluster de algumas maneiras bem simples, e mantendo-se o restante da instalação o mais automatizado possível. Desta forma, algumas decisões foram tomadas. As mais importantes são:

- Foi decidido usar o Vagrant em conjunto com o VirtualBox. Poderia ser usado outro Virtualizador (até o Virt Manager) mas esta foi uma decisão tomada unicamente por questão de prática com o uso do VirtualBox.

- A rede local da interface NAT das máquinas virtuais (linhas [43](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/Vagrantfile#L43) e [68](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/Vagrantfile#L68)) do arquivo `Vagrantfile`) foram alteradas para `169.254.0.0/16`, assim, evitando conflitos com as diversas configurações de rede local que possam existir por aí;

- Foi criada uma interface de rede pública na máquina virtual, no modo bridge, para permitir acesso do cluster da rede local do usuário e não só via comandos do Vagrant. Desta forma, se a máquina onde estiver rodando o script possuir mais de uma placa de rede, será necessário escolher uma das disponíveis para fazer a vinculação;

- No control node (linha [13](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/30-control-node.sh#L13)) do arquivo `scripts/30-control-node.sh`) foi decidido usar as redes `172.16.0.0/16` e `172.17.0.0/16` para a alocação de IPs dos serviços (--service-cidr) e dos pods (--pod-network-cidr), respectivamente. Isso pode gerar um conflito de roteamento caso a rede local da máquina host seja neste range de IPs;

- Ainda no control node, o endereço de anúncio do Kubernetes (--apiserver-advertise-address e --apiserver-cert-extra-sans) foi vinculado à interface pública criada no `Vagrantfile`. Da mesma forma, o endpoint (--control-plane-endpoint) referencia à entrada criada dentro do `/etc/hosts` (linhas [9](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/30-control-node.sh#L9) e [11](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/30-control-node.sh#L11)). Na imagem do Ubuntu 21.10 usada neste repositório, a interface de rede criada vêm com o nome `enp0s8` (linha [7](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/30-control-node.sh#L7)). Se a imagem for alterada, é importante atentar para este detalhe, pois a nomenclatura da interface pode mudar entre distribuições. No entanto, devido à forma como o VirtualBox cria as interfaces, a interface pública é sempre a segunda placa de rede, sendo a primeira do NAT usado pelo Vagrant.

Em tempo, esse deploy não foi testado em um ambiente Windows, somente em um ambiente Linux (Linux Mint 20.2 Uma). Caso vocês tenham algum problema com a execução deste repositório em outros ambientes, sintam-se à vontade de enviar contribuições e/ou até PRs com correções ou adições ao script.

### Docker e/ou Containerd

Primeiramente, para a montagem deste tutorial foi feita a instalação do cluster com o Docker, seguindo as configurações de instalação da [Documentação do Docker](https://docs.docker.com/engine/install/) e resumidas no script de instalação `scripts/10-oci-docker.sh` e posteriormente foi adicionada a possibilidade de usar o Containerd como engine OCI, que está disponível no script `scripts/10-oci-containerd.sh`. A opção sobre qual engine OCI usar pode ser configurada na variável OCI dentro do arquivo `Vagrantfile`.

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

## To connect to the dashboard

First, you have to get the admin token created on kubernetes secret

```
vagrant ssh control-node -c "kubectl -n kube-system get secret --template='{{.data.token}}' \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}') | base64 --decode ; echo"
```

After that, you run kubectl proxy on the console to output the dashboard endpoint

```
vagrant ssh control-node -c "kubectl proxy"

```

After this, you can access the dashboard on the URL: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ using the token retrieved before.

# Destroying everything and freeing resources


```
vagrant destroy -f
```
