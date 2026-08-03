# Pipeline CI/CD com Docker, Kubernetes e GCP

Projeto técnico que demonstra a criação de uma imagem Docker, publicação no Google Artifact Registry e implantação automatizada em Kubernetes usando GitLab CI/CD e Google Kubernetes Engine (GKE).

> Este repositório foi preparado apenas para versionamento e apresentação do código. Ele não contém workflow de GitHub Pages e não publica o frontend como site estático.

## Status do projeto

| Componente | Estado |
|---|---|
| Aplicação de exemplo | Pronta |
| Container NGINX não privilegiado | Pronto |
| Docker Compose local | Pronto |
| GitLab CI/CD | Pipeline incluído |
| Manifests Kubernetes | Prontos |
| Google Cloud/GKE | Requer configuração da conta |

## Objetivo

Representar um fluxo completo de entrega contínua:

```text
Código → Validação → Build Docker → Artifact Registry → Deploy no GKE → Verificação do rollout
```

A pasta `app/` contém somente a aplicação de exemplo usada pelo Docker e pelo Kubernetes. Ela faz parte do laboratório técnico e não é configurada para publicação no GitHub Pages.

## Tecnologias

- Docker e Docker Compose
- GitLab CI/CD
- Google Artifact Registry
- Google Kubernetes Engine (GKE)
- Kubernetes
- NGINX não privilegiado
- Bash

## Diferenciais implementados

- Pipeline dividido em `validate`, `build` e `deploy`.
- Imagens versionadas pelo SHA do commit.
- Autenticação com Google Cloud por OIDC/Workload Identity Federation.
- Container NGINX executado sem privilégios de root.
- Headers HTTP de segurança e endpoint `/healthz`.
- Readiness e liveness probes.
- Limites e solicitações de CPU e memória.
- Rolling Update.
- Horizontal Pod Autoscaler entre 2 e 5 réplicas.
- PodDisruptionBudget.
- Documentação de arquitetura e scripts auxiliares.

## Arquitetura

```text
┌──────────────┐    ┌───────────────────┐    ┌─────────────────────┐
│ GitLab Repo  │───►│ GitLab CI/CD      │───►│ Artifact Registry   │
└──────────────┘    │ validate/build    │    └──────────┬──────────┘
                    └─────────┬─────────┘               │
                              │ kubectl                  │ image pull
                              ▼                          ▼
                    ┌───────────────────────────────────────────────┐
                    │ Google Kubernetes Engine                     │
                    │ Deployment + Service + HPA + PDB             │
                    └───────────────────────────────────────────────┘
```

Mais detalhes em [`docs/architecture.md`](docs/architecture.md).

## Estrutura do repositório

```text
gcp-kubernetes-cicd-pipeline/
├── app/
│   ├── css/styles.css
│   ├── js/app.js
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
```

## Como colocar no GitHub

1. Extraia o arquivo ZIP.
2. Crie um repositório chamado `gcp-kubernetes-cicd-pipeline`.
3. Envie todos os arquivos e pastas extraídos.
4. Mantenha o repositório público para incluí-lo no portfólio.

Não é necessário ativar o GitHub Pages.

## Execução local com Docker

```bash
docker compose up -d --build
```

A aplicação de exemplo ficará disponível em:

```text
http://localhost:8080
```

Teste de saúde:

```text
http://localhost:8080/healthz
```

Para encerrar:

```bash
docker compose down
```

## Validação da estrutura

Em Linux, WSL ou Git Bash:

```bash
bash scripts/validate.sh
```

## Configuração do GitLab e Google Cloud

O arquivo `.gitlab-ci.yml` foi preparado para integração do GitLab com o Google Cloud usando OIDC e Workload Identity Federation.

### Recursos esperados

- Projeto ativo no Google Cloud.
- Repositório Docker no Artifact Registry.
- Cluster GKE.
- Conta de serviço para o pipeline.
- Workload Identity Federation configurada entre GitLab e Google Cloud.
- Integração do Google Artifact Registry configurada no projeto GitLab.

### Variáveis usadas pelo pipeline

```text
GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID
GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME
GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION
```

Ajuste no `.gitlab-ci.yml`, quando necessário:

```yaml
GKE_CLUSTER: portfolio-cluster
GCP_REGION: us-central1
```

## Preparação opcional da infraestrutura

Em um terminal Bash com o `gcloud` autenticado:

```bash
export PROJECT_ID="seu-projeto-real"
bash scripts/bootstrap-gcp.sh
```

O script habilita APIs, cria um Artifact Registry, uma conta de serviço e um cluster GKE Autopilot quando esses recursos ainda não existem.

> A configuração de identidade entre GitLab e Google Cloud depende do projeto, grupo e políticas IAM da sua conta.

## Deploy manual no Kubernetes

Substitua `IMAGE_PLACEHOLDER` em `k8s/deployment.yaml` pela URI real da imagem e execute:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/pdb.yaml
kubectl rollout status deployment/gke-cicd-showcase -n lf-labs
```

Consultar o serviço:

```bash
kubectl get service gke-cicd-showcase -n lf-labs
```

## Boas práticas demonstradas

| Área | Implementação |
|---|---|
| Segurança | Non-root, capabilities removidas e filesystem somente leitura |
| Identidade | OIDC e credenciais temporárias no pipeline |
| Confiabilidade | Probes, duas réplicas, RollingUpdate e PDB |
| Escalabilidade | HPA baseado em CPU |
| Rastreabilidade | Imagem marcada com SHA do commit |
| Portabilidade | Aplicação de exemplo containerizada |
| Documentação | README, arquitetura e scripts operacionais |

## Aviso sobre custos

Recursos como GKE, Artifact Registry e Service do tipo LoadBalancer podem gerar cobranças no Google Cloud. Exclua os recursos de laboratório quando não estiverem em uso.

## Possíveis evoluções

- TLS e domínio personalizado.
- Ingress ou Gateway API.
- Observabilidade com métricas e logs centralizados.
- Análise de vulnerabilidades da imagem.
- Geração de SBOM.
- Assinatura de imagens.
- Ambientes separados para homologação e produção.

## Autor

**Luís Filipe Medeiros de Oliveira e Silva**

- GitHub: [github.com/lfmos](https://github.com/lfmos)

## Licença

Distribuído sob a licença MIT. Consulte [`LICENSE`](LICENSE).
