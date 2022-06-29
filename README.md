# Vagrant K8s Cluster

Instalar um cluster Kubernetes não é mais tão difícil quanto era antes do surgimento de ferramentas como Minikube, k3s e kubeadm, no entanto ainda existem várias pequenas coisas que precisam ser feitas em uma instalação do cluster, que só vamos descobrindo durante o processo de instalação e depuração dos erros que vão aparecendo.

## Configurações da instalação

Esta instalação do Kubernetes usando o Vagrant assume algumas configurações que podem ser facilmente alteradas no arquivo `Vagrantfile`, que são as seguintes:

* **IMAGEM**: Sistema operacional a ser usado no sistema convidado;
* **WORKERS**: Quantidade de nós não-controladores a serem usados no cluster;
* **CONTROLLERS**: Quantidade de nós controladores extras a serem usados no cluster;
* **MEMORIA**: Memória alocada para cada máquina virtual;
* **CPUS**: Quantidade de núcleos alocados para cada máquina virtual;
* **OCI**: driver de conteiner a ser usado no cluster (no momento somente Containerd e Docker);
* **CNI**: driver de rede a ser usado no cluster (no momento somente Calico).

### Opiniões assumidas sobre algumas configurações

Uma coisa para qual esse repositório foi pensado foi a de ser possível customizar a instalação do cluster de algumas maneiras bem simples, e mantendo-se o restante da instalação o mais automatizado possível. Desta forma, algumas decisões pessoais foram tomadas. As mais importantes são:

1. Foi decidido usar o Vagrant em conjunto com o VirtualBox. Poderia ser usado outro Virtualizador (até o Virt Manager) mas esta foi uma decisão tomada unicamente por questão de prática com o uso do VirtualBox.

2. As redes locais das interfaces NAT das máquinas virtuais do arquivo `Vagrantfile` foram alteradas para `10.254.0.0/16`, assim, evitando conflitos com as diversas configurações de rede local que possam existir por aí e evitando também que os comportamentos padrões do `kubeadm` sejam afetados (dão erros estranhos se a rede está setada com `127.0.0.0/8` ou `169.254.0.0/16`);

3. Foi criada uma interface de rede do tipo _host only_ no range `192.168.56.0/24` para permitir que as máquinas conversem entre si sem precisar sair do VirtualBox. Adicionalmente, é possível acessar os nós do cluster e os serviços disponibilizados via LoadBalancer do cluster;

4. No control node foi decidido usar as redes `172.16.0.0/16` e `172.17.0.0/16` para a alocação de IPs dos serviços (`--service-cidr`) e dos pods (`--pod-network-cidr`), respectivamente. Isso pode gerar um conflito de roteamento e também possíveis problemas com os serviços CoreDNS e plugin de CNI dentro do Kubernetes caso a rede local da máquina host seja neste range de IPs;

5. Ainda no control node, o endereço de anúncio do Kubernetes (`--apiserver-advertise-address` e `--apiserver-cert-extra-sans`) foi vinculado à interface _host only_ criada no `Vagrantfile`. Da mesma forma, o endpoint (`--control-plane-endpoint`) faz referência à entrada criada dentro do `/etc/hosts`.

6. Continuando no control node, foi feito o untaint do nó para permitir que pods sejam agendados no mesmo, assim aumentando a disponibilidade deste cluster de testes.

6. Na imagem do Ubuntu 22.04 (usada neste repositório) a interface de rede criada vêm com o nome `enp0s8`. Se a imagem for alterada, é importante atentar para este detalhe, pois a nomenclatura da interface pode mudar entre distribuições. No entanto, devido à forma como o VirtualBox cria as interfaces e o kernel aloca os mesmos, a interface pública é sempre a segunda placa de rede, sendo a primeira do NAT usado pelo Vagrant.

7. Ainda sobre a imagem do Ubuntu, devido ao fato de a imagem não vir com o agendamento de CGroups habilitada no kernel, foi necessário fazer a customização da string de inicialização do kernel no Grub. Devido a este fato, é necessária a instalação do plugin vagrant-reload para que a instância seja reinicializada após a alteração do grub da instância. A instalação pode ser feita através do comando `vagrant plugin install vagrant-reload`.

8. Como o cluster Kubernetes depende muito dos nomes dos hosts para orquestrar as ações dentro do cluster (principalmente em relação à geração dos certificados e do CA), é necessário fazer um gerenciamento do arquivo de hosts das máquinas. Anteriormente, isso era feito usando um arquivo compartilhado e um script cron, mas é possível simplificar isso usando o plugin vagrant-hosts. A instalação pode ser feita com o comando `vagrant plugin install vagrant-hosts`.

### Containerd e/ou CRI-O

Para a instalação do Containerd, são necessárias algumas etapas já que o Docker faz muita coisa "magicamente" por nós. Aqui é onde as coisas começam a ficar um pouco nebulosas. Apesar de os desenvolvedores do Kubernetes falarem que as coisas funcionam sem nenhum ajuste maior, isso só acontece quando você usa do Docker como backend de conteineres. O Docker faz um monte de coisas pra por trás dos panos que, quando você migra para o Containerd, você precisa fazer essas configurações de forma manual. As instruções de instalação do Containerd estão detalhadas nos comentários do arquivo `scripts/10-oci-containerd.sh`.

Para a instalação do CRI-O foi utilizado um repositório APT do OpenSUSE que já vêm com as ferramentas do CRI-O disponíveis para instalação no Ubuntu. No entanto, elas ainda não estão disponíveis para o Ubuntu 22.04, mas as da versão 20.04 ainda são compatíveis. As instruções de instalação do CRI-O estão detalhadas nos comentários do arquivo `scripts/10-oci-crio.sh`.

A instalação do Docker foi removida pois não conseguimos fazer a mesma funcionar após a atualização. No entanto, o script ainda encontra-se disponível em `scripts/10-oci-docker.sh`.

Por padrão o projeto vêm com o Containerd configurado como engine de conteineres padrão.

### Calico e/ou Flannel

Para a configuração do plugin de rede que o Kubernetes precisa, deixamos disponível a opção de usar o Calico pela simplicidade de configuração, já que na versão atual ele importa as configurações de pods e serviços direto do Kubernetes, não sendo necessário nenhum ajuste na configuração. No entanto, caso seja necessário usar uma configuração personalizada (especificamente de rede), eu deixei comentado alterações no arquivo `calico.yaml` que é baixado para a implantação da rede. As alterações são no pool de IPs que o Calico pode usar. Como disse, o Calico atualmente é inteligente o suficiente para encontrar essas informações, considerando que elas tenham sido passadas para o comando `kubeadm init` pelos parâmetros `--service-cidr` e `--pod-network-cidr`. Em tempo, um warning foi removido da instalação do Calico, devido a versão da API que foi trocada de `apiVersion: policy/v1beta1` para `apiVersion: policy/v1`, segundo a [documentação](https://kubernetes.io/docs/tasks/run-application/configure-pdb/). Adicionalmente, usando o Calico, o `MetalLB` não irá funcionar pois não foi feita nenhuma configuração para fazer os dois conversarem (pois ambos usam BGP para fazer o roteamento do tráfego).

Para a configuração do plugin de rede do Flannel, foram feitas algumas alterações no arquivo de instalação do CNI. A primeira delas é referente à interface de rede que o Flannel irá usar para construir o overlay (linha [13](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/31-cni-flannel.sh#L13)). Adicionalmente, foi feita a alteração da rede de pods para uso do Flannel. O Flannel por padrão vêm com a rede `10.244.0.0/16` configurada para o parâmetro `FLANNEL_NETWORK`, que pode ser visto no arquivo `/run/flannel/subnet.env`. Para manter o mesmo padrão de rede usado no projeto, mudamos o valor no ConfigMap (linha [20](https://gitlab.com/devops-in-a-jar/vagrant-k8s-cluster/-/blob/main/scripts/31-cni-flannel.sh#L20)) para o valor que está definido para a nossa rede de pods, conforme explicado no post [Kubernetes: Flannel networking](https://blog.laputa.io/kubernetes-flannel-networking-6a1cb1f8ec7c).

Por padrão, o projeto vêm com o Flannel setado como plugin de rede.

### Plugins instalados

#### MetalLB

Para a instalação do plugin do MetalLB faz-se necessário configurá-lo com as opções que ele irá utilizar para fazer o loadbalancer funcionar com o cluster. Desta forma, foi criado um `ConfigMap` no arquivo `scripts/32-metallb.sh` onde foram adicionados o range de IPs que o loadbalancer poderá usar (`192.168.56.128` até `192.168.56.255`) e ao modo que ele irá atuar.

No modo `layer 2` o metallb usa ARP para apontar para um IP e de lá o kube-proxy distribui para todos os serviços (dica dada no post [Configure MetalLB in layer 2 mode](https://docs.bitnami.com/kubernetes/infrastructure/metallb/administration/configure-layer2-mode/)).

Importante lembrar, se estiver usando o Calico como CNI, o MetalLB não irá funcionar na configuração atual.

#### Metrics

No plugin de métricas, foi feita uma alteração no manifest, para que não fosse necessário o uso de um certificado TLS de autoridade certificadora, permitindo o uso do certificado gerado pelo `kubeadm init`, através da inserção da opção `--kubelet-insecure-tls`.

Adicionalmente, foi feita a adição de um patch no deployment do plugin para permitir que os pods do plugin de métricas pudessem ser executados no control-plane, pois este somente aceita pods cuja tolerância esteja setada para `node-role.kubernetes.io/master`, o que não é o caso do plugin de métricas, no ato da instalação (dica dada no issue [#1402](https://github.com/k3s-io/k3s/issues/1402) do projeto [k3s](https://github.com/k3s-io/k3s/)).

#### Dashboard

Já o plugin de dashboard, entregue pelo comando `kubectl proxy`, só permite o acesso à URL através do endereço localhost da máquina guest, desta forma inviabilizando o seu acesso pelo usuário. Assim sendo, foi feita uma configuração de rota no iptables para que os acessos que chegassem através do port forward do vagrant (e que são entregues pela rede NAT) fossem redirecionados via regra DNAT para o localhost, assim permitindo o acesso do dashboard neste nosso exemplo. Esta não é a forma correta de se fazer, mas para questões de estudo, esta forma é a que menos impacta em alteração das configurações de instalação do plugin.

Ainda sobre o dashboard, ao acessar o mesmo usando o arquivo `cluster-admin.conf` gerado pelo comando `kubeadm init`, o dashboard nos retornava um erro de *Not enough data to create auth info structure*. Este problema é bem explicado neste [issue](https://github.com/kubernetes/dashboard/issues/2474) no repo do kubernetes. Para resolver esse problema, nós criamos uma conta admin usando `ServiceAccount` e em seguida aplicamos uma `ClusterRoleBinding` no usuário. Com isso, é só exportar o token gerado pelo manifest do `ServiceAccount` e usar ele durante o login no dashboard.

Ainda sobre o Dashboard, inicialmente é possível acessá-lo através do comando `kubectl proxy` e a URL [http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/).

No entanto, para simplificar um pouco mais o acesso, implantamos um serviço NodePort que aponta para a porta do Dashboard e nos permite acessar o mesmo através do IP dos nós, na porta 32000. Assim, não é necessário chamar o `kubectl proxy` todas as vezes, permitindo inclusive acesso de outros locais que não aqueles de onde estamos executando o `kubectl`.

Adicionalmente, por questões de estudo, também foi configurado um serviço do tipo LoadBalancer que aponta para o Dashboard, assim nem sendo necessário indicar a porta do serviço, somente o IP que o serviço estiver anunciando (que você pode pegar com o comando `kubectl get service --namespace kubernetes-dashboard kubernetes-dashboard-lb`).

#### Helm

Foi instalado o executável do Helm na máquina, para a instalação de charts que porventura possam ser usados durante as experimentações e estudos com o Kubernetes. O arquivo é o `scripts/35-helm.sh`.

# Instalação das dependências do Vagrant

Para executar o projeto, algumas coisas são necessárias. Primeiramente, é necessário instalar o VirtualBox e o Vagrant. Após a instalação destes, é necessário instalar os plugins para o funcionamento do projeto:

```bash
vagrant plugin install vagrant-reload
vagrant plugin install vagrant-hosts
```

Com a instalação destes artefatos, é possível fazer a execução do projeto.

# Executando o projeto

Dadas as instruções acima, para carregar o ambiente é só usar o comando abaixo, que irá criar 6 instâncias de Ubuntu 22.04 (1 balanceador, 3 control nodes e 2 worker nodes), instalar todas as dependências, instalar o `kubeadm` e startar o cluster, adicionando os plugins citados acima.

```bash
vagrant up
```

Nos meus testes, o cluster inteiro usa 10,5 Gb de memória (2 Gb para cada instância do cluster, 512 Mb para o Balanceador) e demora por volta de 25 minutos para iniciar completamente em um i5-9400F.

## Checando o status do cluster e dos pods iniciais do Kubernetes

Para a operação do cluster, você pode logar no primeiro control node com o comando `vagrant ssh` ou se não quiser entrar na instância, pode usar conforme listado abaixo, por exemplo, para pegar as informações dos pods.

```bash
vagrant ssh -c "kubectl get pods -n kube-system"
vagrant ssh -c "kubectl get nodes"
```

Com a instalação do plugin de métricas, você pode checar o uso de memória e CPU dos nós e pods com os comandos abaixo:

```bash
vagrant ssh -c "kubectl top pod -n kube-system"
vagrant ssh -c "kubectl top nodes"
```

### Acesso ao Dashboard do cluster

Primeiramente, você precisa buscar o token criado no script `scripts/34-dashboard.sh` com o seguinte comando:

```bash
vagrant ssh control-plane -c "kubectl -n kubernetes-dashboard create token admin-user"
```

Na última atualização deste projeto, adicionamos um service do tipo NodePort que permite acessarmos o dashboard sem precisar usar a URL do `kubectl proxy`. Como o service é do tipo NodePort, seu acesso pode ser feito através da URL [https://192.168.56.11:32000/](https://192.168.56.11:32000/).

Ainda é possível acessar através do IP do loadbalancer criado para o dashboard, que está sendo anunciado no IP do serviço `kubernetes-dashboard-lb` (que vc pode pegar com o comando `kubectl get service --namespace kubernetes-dashboard kubernetes-dashboard-lb`).

## Exemplos de deploys e continuação dos estudos

Com o objetivo de ajudar nos estudos de Kubernetes, estou também deixando alguns scripts na pasta `exemplos/` para que vocês possam subir e experimentar com o cluster. Nem todos estão bem documentados, e com o passar o tempo, vou melhorar isto, para se tornar uma ferramenta de referência simples do que fazer em cada etapa.

Outra coisa interessante, caso vocês tenham dúvidas sobre o que uma determinada configuração do arquivo YAML significa, vocês podem usar o comando `kubectl explain` para ler sobre aquilo. Por exemplo, `kubectl explain deployment.spec.selector` vai te mostrar a descrição de como é feita a seleção dos pods para a criação do ReplicaSet dentro do Deployment.

## Destruindo o ambiente de estudos e liberando os recursos alocados

Para apagar o cluster e todos os recursos criados, é só usar o comando abaixo. Também pode ser usado caso você queira recriar o ambiente do zero.

```bash
vagrant destroy -f
```

# Considerações finais

Como dito mais acima, este repositório é um esforço de estudo de como fazer deploy de um cluster Kubernetes usando o comando `kubeadm`, e todas as situações passadas por mim neste processo foram documentadas ou neste README ou através de comentários nos arquivos dos scripts, que são separados segundo as fases que estão sendo efetuadas no momento, para deixar mais claro e organizado.

Em tempo, esse deploy não foi testado em um ambiente Windows, somente em um ambiente Linux (Linux Mint 20.2 Uma). Caso você encontre algum problema com a execução deste repositório em outros ambientes, sinta-se à vontade de enviar contribuições e/ou até PRs com correções ou adições ao script.
