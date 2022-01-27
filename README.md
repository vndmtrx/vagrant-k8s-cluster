# Vagrant K8s Cluster

Instalar um cluster Kubernetes não é mais tão difícil quanto era antes do surgimento de ferramentas como Minikube, k3s e kubeadm, no entanto ainda existem várias pequenas coisas que precisam ser feitas em uma instalação do cluster, que só vamos descobrindo durante o processo de instalação e depuração dos erros que vão aparecendo.

## Configurações da instalação

Esta instalação do Kubernetes usando o Vagrant assume algumas configurações que podem ser facilmente alteradas no arquivo `Vagrantfile`(linhas [5 a 10](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/Vagrantfile#L5-L10)), que são as seguintes:

* **IMAGEM**: Sistema operacional a ser usado no sistema convidado;
* **WORKERS**: Quantidade de nós não-controladores a serem usados no cluster;
* **MEMORIA**: Memória alocada para cada máquina virtual;
* **CPUS**: Quantidade de núcleos alocados para cada máquina virtual;
* **OCI**: driver de conteiner a ser usado no cluster (no momento somente Containerd e Docker);
* **CNI**: driver de rede a ser usado no cluster (no momento somente Calico).

### Opiniões assumidas sobre algumas configurações

Uma coisa para qual esse repositório foi pensado foi a de ser possível customizar a instalação do cluster de algumas maneiras bem simples, e mantendo-se o restante da instalação o mais automatizado possível. Desta forma, algumas decisões pessoais foram tomadas. As mais importantes são:

1. Foi decidido usar o Vagrant em conjunto com o VirtualBox. Poderia ser usado outro Virtualizador (até o Virt Manager) mas esta foi uma decisão tomada unicamente por questão de prática com o uso do VirtualBox.

2. As redes locais das interfaces NAT das máquinas virtuais (linhas [43](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/Vagrantfile#L43) e [68](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/Vagrantfile#L68)) do arquivo `Vagrantfile`) foram alteradas para `169.254.0.0/16`, assim, evitando conflitos com as diversas configurações de rede local que possam existir por aí;

3. Foi criada uma interface de rede pública na máquina virtual, no modo bridge, para permitir acesso do cluster da rede local do usuário e não só via comandos do Vagrant. Desta forma, se a máquina onde estiver rodando o script possuir mais de uma placa de rede, será necessário escolher uma das disponíveis para fazer a vinculação;

4. No control node (linha [13](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/30-control-plane.sh#L13) do arquivo `scripts/30-control-plane.sh`) foi decidido usar as redes `172.16.0.0/16` e `172.17.0.0/16` para a alocação de IPs dos serviços (`--service-cidr`) e dos pods (`--pod-network-cidr`), respectivamente. Isso pode gerar um conflito de roteamento e também possíveis problemas com os serviços CoreDNS e Calico dentro do Kubernetes caso a rede local da máquina host seja neste range de IPs;

5. Ainda no control node, o endereço de anúncio do Kubernetes (`--apiserver-advertise-address` e `--apiserver-cert-extra-sans`) foi vinculado à interface pública criada no `Vagrantfile`. Da mesma forma, o endpoint (`--control-plane-endpoint`) faz referência à entrada criada dentro do `/etc/hosts` (linhas [9](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/30-control-plane.sh#L9) e [11](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/30-control-plane.sh#L11)).

6. Na imagem do Ubuntu 21.10 (usada neste repositório) a interface de rede criada vêm com o nome `enp0s8` (linha [7](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/30-control-plane.sh#L7)). Se a imagem for alterada, é importante atentar para este detalhe, pois a nomenclatura da interface pode mudar entre distribuições. No entanto, devido à forma como o VirtualBox cria as interfaces, a interface pública é sempre a segunda placa de rede, sendo a primeira do NAT usado pelo Vagrant.

### Docker e/ou Containerd

Primeiramente, para a montagem deste tutorial foi feita a instalação do cluster com o Docker, seguindo as configurações de instalação da [Documentação do Docker](https://docs.docker.com/engine/install/) e resumidas no script de instalação `scripts/10-oci-docker.sh` e posteriormente foi adicionada a possibilidade de usar o Containerd como engine OCI, que está disponível no script `scripts/10-oci-containerd.sh`. A opção sobre qual engine OCI usar pode ser configurada na variável OCI dentro do arquivo `Vagrantfile`.

Para a instalação do Docker, não foi feita nenhuma alteração na forma como é feita a instalação, sendo o mesmo do tutorial apresentado na documentação [Container Runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker).

Para a instalação do Containerd, são necessárias algumas etapas já que o Docker faz muita coisa "magicamente" por nós. Aqui é onde as coisas começam a ficar um pouco nebulosas. Apesar de os desenvolvedores do Kubernetes falarem que as coisas funcionam sem nenhum ajuste maior, isso só acontece quando você usa do Docker como backend de conteineres. O Docker faz um monte de coisas pra por trás dos panos, que quando você migra para o Containerd você precisa fazer essas configurações de forma manual. As instruções de instalação do Containerd estão detalhadas nos comentários do arquivo `scripts/10-oci-containerd.sh`.

### Calico e/ou Flannel

Para a configuração do plugin de rede que o Kubernetes irá usar, primeiramente usamos o Calico, pela simplicidade de configuração, já que na versão atual ele importa as configurações de pods e serviços direto do Kubernetes, não sendo necessário nenhum ajuste na configuração. No entanto, caso seja necessário usar uma configuração personalizada (especificamente de rede), eu deixei comentado alterações no arquivo `calico.yaml` que é baixado para a implantação da rede. As alterações são no pool de IPs que o Calico pode usar. Como disse, o Calico atualmente é inteligente o suficiente para encontrar essas informações, considerando que elas tenham sido passadas para o comando `kubeadm init` pelos parâmetros `--service-cidr` e `--pod-network-cidr`.

Ainda não foi feita a configuração do plugin de redes usando o Flannel, mas já deixei o arquivo ali disponível para estudo futuro do deploy automatizado do mesmo.

Em breve pretendo colocar a instalação do plugin de redes usando o Cillium, para tirar proveito das facilidades do eBPF em relação ao iptables.

### Plugins instalados

#### Metrics

No plugin de métricas, somente uma alteração foi feita no manifest, para que não fosse necessário o uso de um certificado TLS de autoridade certificadora, permitindo o uso do certificado gerado pelo `kubeadm init`, através da inserção da opção `--kubelet-insecure-tls`.

#### Dashboard

Já o plugin de dashboard, entregue pelo comando `kubectl proxy`, só permite o acesso à URL através do endereço localhost da máquina guest, desta forma inviabilizando o seu acesso pelo usuário. Desta forma, foi feita uma configuração de rota no iptables (linha [16](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/34-dashboard.sh#L21)) para que os acessos que chegassem através do port forward do vagrant (linha [39](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/Vagrantfile#L39)) (e que são entregues pela rede NAT) fossem redirecionados via regra DNAT para o localhost, assim permitindo o acesso do dashboard neste nosso exemplo. Esta não é a forma correta de se fazer, mas para questões de estudo, esta forma é a que menos impacta em alteração das configurações de instalação do plugin.

Ainda sobre o dashboard, ao acessar o mesmo usando o arquivo `cluster-admin.conf` gerado pelo comando `kubeadm init`, o dashboard nos retornava um erro de *Not enough data to create auth info structure*. Este problema é bem explicado neste [issue](https://github.com/kubernetes/dashboard/issues/2474) no repo do kubernetes. Para resolver esse problema, nós criamos uma conta admin usando `ServiceAccount` e em seguida aplicamos uma `ClusterRoleBinding` no usuário. Com isso, é só exportar o token gerado pelo manifest do `ServiceAccount` e usar ele durante o login no dashboard.

# Executando o projeto

Dadas as instruções acima, para carregar o ambiente é só usar o comando abaixo, que irá criar 3 instâncias de Ubuntu 21.10, instalar todas as dependências, instalar o kubeadm e startar o cluster, adicionando os plugins citados acima.

```bash
vagrant up
```

## Checando o status do cluster e dos pods iniciais do Kubernetes

Para a operação do cluster, você pode logar no control node com o comando `vagrant ssh control-plane` ou se não quiser entrar na instância, pode usar conforme listado abaixo, por exemplo, para pegar as informações dos pods.

```bash
vagrant ssh control-plane -c "kubectl get pods -n kube-system"
vagrant ssh control-plane -c "kubectl get nodes"
```

Com a instalação do plugin de métricas, você pode checar o uso de memória e CPU dos nós e pods com os comandos abaixo:

```bash
vagrant ssh control-plane -c "kubectl top pod -n kube-system"
vagrant ssh control-plane -c "kubectl top nodes"
```

## Conectando-se ao Dashboard

Primeiramente, você precisa buscar o token criado no script `scripts/34-dashboard.sh` com o seguinte comando:

```bash
vagrant ssh control-plane -c "kubectl -n kube-system get secret --template='{{.data.token}}' \$(kubectl -n kube-system get secret | grep admin-user | awk '{print \$1}') | base64 --decode ; echo"
```

Após receber esse token, é necessário rodar o comando abaixo para disponibilizar o endpoint do dashboard:

```bash
vagrant ssh control-plane -c "kubectl proxy"

```

Feito isso, você pode acessar o dashboard, usando o token retornado na instrução anterior, através da URL http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

## Destruindo o ambiente de estudos e liberando os recursos alocados

Para apagar o cluster e todos os recursos criados, é só usar o comando abaixo. Também pode ser usado caso você queira recriar o ambiente do zero.

```
vagrant destroy -f
```

# Considerações finais

Como dito mais acima, este repositório é um esforço de estudo de como fazer deploy de um cluster Kubernetes usando o comando `kubeadm`, e todas as situações passadas por mim neste processo eu documentei ou neste README ou através de comentários nos arquivos dos scripts, que são separados segundo as fases que estão sendo efetuadas no momento, para deixar mais claro e organizado.

Em tempo, esse deploy não foi testado em um ambiente Windows, somente em um ambiente Linux (Linux Mint 20.2 Uma). Caso vocês encontrem algum problema com a execução deste repositório em outros ambientes, sintam-se à vontade de enviar contribuições e/ou até PRs com correções ou adições ao script.
