# GCP Kubernetes CI/CD Pipeline

Projeto técnico de referência para demonstrar um fluxo de entrega contínua com Docker, GitLab CI/CD, Google Artifact Registry, Kubernetes e Google Kubernetes Engine (GKE).

O repositório combina uma aplicação web containerizada com manifests Kubernetes, automação de validação, pipeline de build/deploy e práticas de segurança aplicadas a containers e workloads.

> O deploy em GKE depende de um ambiente Google Cloud e de uma integração GitLab configurados. O repositório demonstra e automatiza esse fluxo, mas não apresenta um cluster GKE ativo como requisito para visualizar ou validar o projeto.

---

## Objetivo

Representar a arquitetura:

    Código
      ↓
    Validação
      ↓
    Build Docker
      ↓
    Artifact Registry
      ↓
    Deploy no GKE
      ↓
    Verificação do rollout

O foco do projeto está em CI/CD, containers, Kubernetes, cloud e DevSecOps.

---

## Status

| Componente | Estado |
| --- | --- |
| Aplicação web de demonstração | Implementada |
| Container NGINX não privilegiado | Implementado |
| Docker Compose local | Implementado |
| GitHub Actions | Workflow de validação incluído |
| GitLab CI/CD | Pipeline de build e deploy incluído |
| Manifests Kubernetes | Implementados |
| Hardening de container e workload | Implementado |
| Artifact Registry | Configuração prevista pelo pipeline |
| Google Cloud / GKE | Requer ambiente GCP configurado |
| Workload Identity Federation | Requer integração GitLab ↔ Google Cloud |

---

## Tecnologias

- Docker
- Docker Compose
- GitLab CI/CD
- GitHub Actions
- Google Artifact Registry
- Google Kubernetes Engine
- Kubernetes
- NGINX Unprivileged
- Bash
- Google Cloud CLI

---

## Pipeline GitLab

O arquivo `.gitlab-ci.yml` define três estágios:

    validate
       ↓
    build
       ↓
    deploy

### Validate

Executa o script:

    bash scripts/validate.sh

A validação verifica:

- estrutura esperada do projeto;
- sintaxe dos scripts Bash;
- presença do placeholder da imagem;
- controles de segurança do Deployment;
- readiness e liveness probes;
- requests e limits;
- HPA;
- PodDisruptionBudget;
- endpoint `/healthz`;
- configuração de identidade Google Cloud no pipeline.

### Build

O pipeline é configurado para:

- gerar uma imagem Docker;
- identificar a imagem pelo SHA do commit;
- publicar no Google Artifact Registry;
- publicar `latest` a partir da branch padrão;
- utilizar uma tag Git como versão adicional da imagem quando aplicável.

### Deploy

Na branch padrão, o pipeline é configurado para:

- autenticar no Google Cloud;
- obter credenciais do cluster GKE;
- substituir `IMAGE_PLACEHOLDER` pela imagem do commit;
- aplicar os manifests Kubernetes;
- acompanhar o rollout do Deployment.

---

## Identidade no Google Cloud

A arquitetura utiliza:

    GitLab
      ↓
    OIDC
      ↓
    Workload Identity Federation
      ↓
    Google Cloud IAM
      ↓
    Artifact Registry / GKE

O objetivo é evitar chaves de service account armazenadas como segredos permanentes no pipeline.

A integração deve ser configurada no projeto GitLab e no Google Cloud antes de executar build e deploy reais.

---

## GitHub Actions

O workflow:

    .github/workflows/validate.yml

fornece validação pública do projeto no GitHub sem exigir credenciais GCP.

Ele executa:

- ShellCheck;
- `scripts/validate.sh`;
- validação do Docker Compose;
- build da imagem;
- verificação do usuário non-root;
- execução do container com hardening;
- teste real do endpoint `/healthz`.

Isso permite validar o container e a estrutura do projeto sem criar infraestrutura cloud.

---

## Segurança do container

A imagem utiliza NGINX Unprivileged e declara explicitamente:

    USER 101:101

O ambiente local também aplica:

- usuário non-root;
- `no-new-privileges`;
- remoção de Linux capabilities;
- filesystem somente leitura;
- limites de processos;
- diretórios temporários isolados;
- healthcheck.

O NGINX adiciona headers como:

- `X-Content-Type-Options`;
- `X-Frame-Options`;
- `Referrer-Policy`;
- `Permissions-Policy`;
- Content Security Policy.

Também existe:

    /healthz

para verificações de disponibilidade.

---

## Segurança no Kubernetes

O Deployment inclui:

- `automountServiceAccountToken: false`;
- `runAsNonRoot: true`;
- UID e GID explícitos;
- `RuntimeDefault` seccomp;
- `allowPrivilegeEscalation: false`;
- filesystem somente leitura;
- remoção de todas as Linux capabilities;
- readiness probe;
- liveness probe;
- requests e limits de CPU e memória;
- volumes graváveis apenas onde necessários.

O namespace também utiliza Kubernetes Pod Security Standards no perfil:

    restricted

com modos de:

- enforce;
- audit;
- warn.

---

## Disponibilidade e resiliência

O laboratório inclui:

- duas réplicas iniciais;
- RollingUpdate;
- `maxUnavailable: 0`;
- `maxSurge: 1`;
- Horizontal Pod Autoscaler;
- mínimo de 2 réplicas;
- máximo de 5 réplicas;
- PodDisruptionBudget;
- readiness e liveness probes.

Esses recursos demonstram práticas comuns de disponibilidade e resiliência em Kubernetes.

---

## Arquitetura

    GitLab
       |
       v
    Validation
       |
       v
    Docker Build
       |
       v
    Artifact Registry
       |
       v
    GKE
       |
       +--> Deployment
       +--> Service
       +--> HPA
       +--> PDB

Mais detalhes estão disponíveis em:

    docs/architecture.md

---

## Estrutura do repositório

    gcp-kubernetes-cicd-pipeline/
    ├── .github/
    │   └── workflows/
    │       └── validate.yml
    ├── app/
    │   ├── css/
    │   │   └── styles.css
    │   ├── js/
    │   │   └── app.js
    │   ├── index.html
    │   └── nginx.conf
    ├── docs/
    │   └── architecture.md
    ├── k8s/
    │   ├── deployment.yaml
    │   ├── hpa.yaml
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   ├── pdb.yaml
    │   └── service.yaml
    ├── scripts/
    │   ├── bootstrap-gcp.sh
    │   └── validate.sh
    ├── .dockerignore
    ├── .gitignore
    ├── .gitlab-ci.yml
    ├── CHANGELOG.md
    ├── Dockerfile
    ├── LICENSE
    ├── docker-compose.yml
    └── README.md

---

## Execução local

### Requisitos

- Docker
- Docker Compose

Clone o projeto:

    git clone https://github.com/lfmos/gcp-kubernetes-cicd-pipeline.git
    cd gcp-kubernetes-cicd-pipeline

Inicie:

    docker compose up -d --build

Acesse:

    http://localhost:8080

Health check:

    http://localhost:8080/healthz

Para encerrar:

    docker compose down

---

## Validação local

Em Linux, WSL ou Git Bash:

    bash scripts/validate.sh

Para validar o Compose:

    docker compose config

---

## Preparação opcional do Google Cloud

O script:

    scripts/bootstrap-gcp.sh

pode habilitar APIs necessárias e preparar um repositório Docker no Artifact Registry.

Exemplo:

    export PROJECT_ID="meu-projeto-gcp"
    bash scripts/bootstrap-gcp.sh

Por padrão, o script NÃO cria um cluster GKE.

A criação do cluster é deliberadamente opt-in porque recursos GKE podem gerar custos:

    export PROJECT_ID="meu-projeto-gcp"
    export CREATE_CLUSTER=true
    bash scripts/bootstrap-gcp.sh

Antes de executar, revise os comandos e confirme o projeto Google Cloud selecionado.

---

## Variáveis utilizadas pelo pipeline

A integração Google Artifact Management / Google Cloud fornece variáveis como:

    GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID
    GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME
    GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION

O pipeline também utiliza:

    GKE_CLUSTER
    GCP_REGION

Os valores padrão presentes no laboratório são:

    GKE_CLUSTER=portfolio-cluster
    GCP_REGION=us-central1

---

## Deploy manual no Kubernetes

Para testes em um cluster configurado, substitua `IMAGE_PLACEHOLDER` em:

    k8s/deployment.yaml

pela URI da imagem e aplique:

    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    kubectl apply -f k8s/hpa.yaml
    kubectl apply -f k8s/pdb.yaml

Depois:

    kubectl rollout status deployment/gke-cicd-showcase -n lf-labs

E:

    kubectl get deployment,pods,service,hpa -n lf-labs

---

## Boas práticas demonstradas

| Área | Implementação |
| --- | --- |
| Container Security | non-root, capabilities removidas e filesystem somente leitura |
| Kubernetes Security | Restricted Pod Security Standards e seccomp |
| Identidade | OIDC / Workload Identity Federation |
| Disponibilidade | probes, múltiplas réplicas, RollingUpdate e PDB |
| Escalabilidade | HPA baseado em CPU |
| Rastreabilidade | imagens identificadas pelo SHA do commit |
| CI | GitHub Actions para validação pública |
| CD | pipeline GitLab para Artifact Registry e GKE |
| Portabilidade | aplicação containerizada |
| Segurança de pipeline | ausência de chave de service account no repositório |

---

## Limitações atuais

O repositório não comprova, por si só:

- existência de um cluster GKE ativo;
- existência de um projeto Google Cloud configurado;
- execução bem-sucedida de um deploy real em GKE;
- integração WIF ativa em uma instância GitLab específica.

Esses componentes dependem de infraestrutura e configurações externas.

O GitHub Actions valida apenas os componentes que podem ser executados sem credenciais e sem infraestrutura GCP.

---

## Custos

Google Cloud pode gerar cobranças para recursos como:

- GKE;
- Artifact Registry;
- Load Balancer;
- tráfego de rede.

Por esse motivo, o script de bootstrap não cria um cluster automaticamente.

Recursos de laboratório devem ser removidos quando não estiverem em uso.

---

## Possíveis evoluções

- TLS e domínio;
- Ingress ou Gateway API;
- NetworkPolicy;
- observabilidade;
- métricas e logs centralizados;
- análise de vulnerabilidades da imagem;
- SBOM;
- assinatura de imagens;
- image provenance;
- ambientes separados;
- políticas adicionais de supply-chain security.

---

## Autor

Luís Filipe Medeiros de Oliveira e Silva

GitHub: github.com/lfmos

---

## Licença

Distribuído sob a licença MIT. Consulte o arquivo `LICENSE`.