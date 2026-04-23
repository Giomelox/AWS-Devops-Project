# AWS DevOps Project

## Este projeto implementa uma infraestrutura completa na AWS para deploy automatizado de um site estático containerizado, utilizando Terraform para provisionamento da infraestrutura e GitHub Actions para automação do pipeline CI/CD. O fluxo segue boas práticas de DevOps com autenticação via OIDC, sem uso de chaves de acesso estáticas.

# Fluxo Geral

Terraform (Manual via GitHub Actions) → Infraestrutura AWS (VPC + EC2 + ECR) → GitHub Actions (tag push) → Docker Build → Push para ECR → Deploy na EC2 via SSM

# Decisões Arquiteturais

- O provisionamento da infraestrutura é separado do deploy da aplicação, garantindo que a infra seja criada antes do primeiro deploy.

- A autenticação com a AWS é feita via OIDC (OpenID Connect), eliminando a necessidade de secrets com chaves de acesso estáticas no GitHub.

- O deploy na EC2 é realizado via AWS SSM, sem necessidade de acesso SSH direto à instância.

- A imagem Docker é armazenada no Amazon ECR com tags imutáveis, garantindo rastreabilidade e evitando sobrescrita acidental.

- Uma lifecycle policy no ECR mantém apenas as últimas 5 imagens, controlando custos de armazenamento.

- O estado do Terraform é armazenado remotamente em um bucket S3 com criptografia habilitada, garantindo consistência entre execuções.

# Serviços Utilizados

- AWS IAM Role + IAM Policy
- AWS VPC + Subnets + Internet Gateway + NAT Gateway
- AWS EC2
- AWS ECR (Elastic Container Registry)
- AWS SSM (Systems Manager)
- AWS S3 (Terraform State Backend)
- GitHub Actions (CI/CD)
- Docker + Nginx
- Terraform

# Workflows do GitHub Actions

O projeto possui dois workflows distintos, com responsabilidades separadas:

- **terraform.yaml** → Provisionamento manual da infraestrutura AWS
- **docker.yaml** → Build, push e deploy automático da aplicação

Essa separação garante que a infraestrutura seja gerenciada de forma controlada e independente do ciclo de deploy da aplicação.

# Terraform CI/CD — Provisionamento Manual

O workflow `terraform.yaml` é acionado manualmente via GitHub Actions UI (`workflow_dispatch`) e permite escolher entre três ações antes de executar:

- **Plan** → Visualiza as mudanças que seriam aplicadas, sem alterar nada na infraestrutura. Útil para revisão antes de um Apply.
- **Apply** → Gera o plano e aplica as mudanças na infraestrutura. O `-out=tfplan` garante que o Apply execute exatamente o que foi planejado.
- **Destroy** → Destrói toda a infraestrutura gerenciada pelo Terraform. Use com cautela — esta operação é irreversível.

## Action Reutilizável (terraform_setup)

Para evitar repetição de código entre os jobs, foi criada uma action local em `.github/actions/terraform_setup/action.yaml` que encapsula os passos comuns:

- Checkout do repositório
- Configuração das credenciais AWS via OIDC
- Instalação do Terraform
- `terraform init`
- `terraform validate`

Essa action é chamada pelos três jobs (Plan, Apply, Destroy), mantendo o workflow limpo e de fácil manutenção.

```yaml
- uses: ./.github/actions/terraform_setup
```

## Autenticação OIDC com a AWS

A autenticação é feita assumindo uma IAM Role via OIDC, sem necessidade de configurar secrets com chaves de acesso:

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::538073092645:role/github_infra_terraform_role
    aws-region: us-east-2
```

# Docker CI/CD — Deploy Automático

O workflow `docker.yaml` é acionado automaticamente quando uma tag seguindo o padrão `v*.*.*` é criada (ex: `v1.0.0`). O fluxo é dividido em dois jobs:

## Job 1 — Build_ECR

- Clona o repositório
- Calcula a tag da imagem no formato `v1.0.0-a3f1c2d` (ref_name + 7 primeiros caracteres do SHA), garantindo unicidade e rastreabilidade
- Autentica na AWS via OIDC
- Realiza login no Amazon ECR
- Faz o build, tag e push da imagem Docker para o ECR

```bash
# Formato da tag gerada automaticamente
image_tag=${{ github.ref_name }}-$SHORT_SHA
# Exemplo: v1.0.0-a3f1c2d
```

## Job 2 — Deploy_image_EC2

Executado somente após o `Build_ECR` concluir com sucesso. Recebe a `image_tag` gerada no job anterior via `outputs` e realiza o deploy na EC2 via SSM:

- Busca o ID da instância EC2 pelo nome da tag
- Envia comandos remotos via `aws ssm send-command` sem necessidade de SSH
- Na EC2: autentica no ECR, faz pull da nova imagem, para o container antigo e sobe o novo

```bash
# Sequência executada remotamente na EC2 via SSM
aws ecr get-login-password | docker login ...
docker pull <nova-imagem>
docker stop site_estatico
docker rm site_estatico
docker run -d --name site_estatico -p 80:80 <nova-imagem>
```

# Infraestrutura AWS (Terraform)

A infraestrutura é definida como código e organizada em arquivos por responsabilidade dentro de `infra-dev/codes/`.

# Rede — network.tf

Cria toda a camada de rede do projeto:

- **VPC** com CIDR `10.0.0.0/16`
- **Subnet pública** (`10.0.1.0/24`) — onde a EC2 está alocada
- **Subnet privada** (`10.0.2.0/24`) — reservada para expansão futura
- **Internet Gateway** — permite acesso à internet a partir da subnet pública
- **NAT Gateway** com Elastic IP — permite que recursos na subnet privada acessem a internet sem exposição direta
- **Route Tables** configuradas para pública e privada

# Segurança — security.tf

Cria o Security Group da EC2:

- Permite tráfego de entrada na **porta 80 (HTTP)** de qualquer origem, tornando o site acessível publicamente
- Permite todo o tráfego de saída, permitindo que a EC2 se comunique com o ECR e outros serviços AWS

# IAM — IAM.tf

Cria a IAM Role associada à EC2 com duas políticas anexadas:

- **AmazonEC2ContainerRegistryReadOnly** — permite que a EC2 faça pull de imagens do ECR
- **AmazonSSMManagedInstanceCore** — permite que a EC2 seja gerenciada remotamente via SSM, sem necessidade de acesso SSH

```hcl
resource "aws_iam_role_policy_attachment" "ec2_access_ecr_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
```

# Computação — compute.tf

Cria a instância EC2:

- AMI: Amazon Linux 2 (buscada dinamicamente via `data.tf`)
- Tipo: `t3.micro`
- Alocada na subnet pública com IP público associado
- IAM Instance Profile com as permissões de ECR e SSM
- `user_data` executado na inicialização para configurar o ambiente (instalação do Docker, etc.)

# Container Registry — container.tf

Cria o repositório ECR com:

- Tags imutáveis (`IMMUTABLE`) — impede sobrescrita de imagens já publicadas
- Criptografia AES256
- Lifecycle policy mantendo apenas as **últimas 5 imagens**, controlando custos de armazenamento

# Estado Remoto — provider.tf

O estado do Terraform é armazenado remotamente em um bucket S3 com criptografia habilitada:

```hcl
backend "s3" {
  bucket  = "projeto-docker-terraform-state-538073092645-us-east-2-an"
  key     = "infra-dev/terraform.tfstate"
  region  = "us-east-2"
  encrypt = true
}
```

Isso garante consistência entre execuções e permite colaboração sem conflitos de estado.

# Outputs — outputs.tf

Ao final do `terraform apply`, os seguintes valores são exibidos:

```
IP público da EC2: <ip>
EC2 criada com ID: <id>
URL do repositório ECR: <url>
```

# Dockerfile

A aplicação é um site estático servido via Nginx Alpine. O Dockerfile copia os arquivos do frontend para o diretório padrão do Nginx e expõe a porta 80:

```dockerfile
FROM nginx:alpine
COPY Tela-de-Login /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

# Pré-requisitos

Para rodar o projeto localmente ou provisionar a infraestrutura manualmente:

- Terraform >= 1.0.0 (provider AWS 6.41.0)
- Docker instalado
- AWS CLI configurado
- Conta AWS com permissões adequadas para criar os recursos listados
- IAM Roles configuradas para autenticação OIDC com o GitHub Actions

# Como Executar

## 1. Clone o repositório

```bash
git clone https://github.com/Giomelox/AWS-Devops-Project.git
cd AWS-Devops-Project
```

## 2. Provisione a infraestrutura

Acesse a aba **Actions** no GitHub, selecione o workflow **Terraform CI/CD - Manual Deploy** e escolha a ação desejada (Plan → Apply).

## 3. Deploy da aplicação

Faça uma alteração no HTML ou CSS e crie uma tag seguindo o padrão `v*.*.*` para acionar o pipeline automaticamente:

```bash
git add .
git commit -m "Comentario"
git push
git tag v1.0.0
git push origin v1.0.0
```

O GitHub Actions irá buildar a imagem, publicar no ECR e fazer o deploy na EC2 automaticamente.

# Fim do Projeto
