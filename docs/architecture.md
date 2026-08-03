# Arquitetura do projeto

## Fluxo principal

```text
Desenvolvedor
     │
     │ git push
     ▼
GitLab Repository
     │
     ▼
GitLab CI/CD Runner
     ├── Validate
     ├── Docker Build
     ├── Push da imagem
     └── Deploy com kubectl
              │
              ├──────────────► Artifact Registry
              │                    imagem:<commit-sha>
              ▼
      Google Kubernetes Engine
              │
              ├── Namespace: lf-labs
              ├── Deployment: 2 réplicas
              ├── Service: LoadBalancer
              ├── HPA: 2 a 5 réplicas
              └── PodDisruptionBudget
```

## Decisões técnicas

### Imagem não privilegiada

A aplicação utiliza uma imagem NGINX preparada para execução sem usuário root e atende na porta `8080`.

### Tags imutáveis

Cada imagem recebe a tag do commit (`CI_COMMIT_SHORT_SHA`). Isso facilita rastrear exatamente qual versão está em produção.

### Autenticação

O pipeline foi desenhado para a integração Google Cloud do GitLab com OIDC e Workload Identity Federation, evitando armazenar uma chave JSON permanente no repositório.

### Deploy declarativo

A infraestrutura da aplicação é descrita em manifests Kubernetes. O pipeline apenas injeta a URI da imagem gerada e aplica os recursos.

### Disponibilidade

O Deployment usa `RollingUpdate`, duas réplicas iniciais, probes de saúde, HPA e PodDisruptionBudget.

## Aplicação de exemplo

O diretório `app/` contém o workload estático usado para construir a imagem Docker e validar o processo de deploy. O repositório não inclui publicação automática no GitHub Pages.
