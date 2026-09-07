# Arquitetura — GKE DevSecOps Lab

## Visão geral

O projeto demonstra uma arquitetura de entrega contínua para uma aplicação web containerizada utilizando Docker, GitLab CI/CD, Google Artifact Registry, Kubernetes e Google Kubernetes Engine.

O repositório também possui um workflow independente no GitHub Actions para validar gratuitamente os componentes que não dependem de credenciais ou infraestrutura Google Cloud.

---

## Fluxos de validação e entrega

Existem dois fluxos distintos.

### Validação pública no GitHub

    GitHub
       |
       v
    GitHub Actions
       |
       +--> ShellCheck
       |
       +--> scripts/validate.sh
       |
       +--> Docker Compose validation
       |
       +--> Docker build
       |
       +--> non-root validation
       |
       +--> hardened container
       |
       +--> /healthz

Esse fluxo não utiliza credenciais GCP e não cria recursos cloud.

Seu objetivo é fornecer uma evidência pública e reproduzível de que o container e a estrutura do projeto funcionam.

---

### Pipeline de entrega no GitLab

    GitLab Repository
           |
           v
       Validate
           |
           v
        Build
           |
           v
    Artifact Registry
           |
           v
      Deploy to GKE
           |
           v
     Verify rollout

O deploy depende de um projeto Google Cloud, Artifact Registry, cluster GKE e Workload Identity Federation configurados.

---

## Identidade e autenticação

O pipeline foi projetado para evitar chaves permanentes de service account.

O fluxo esperado é:

    GitLab Job
        |
        v
       OIDC
        |
        v
    Workload Identity Federation
        |
        v
    Google Cloud IAM
        |
        +--> Artifact Registry
        |
        +--> GKE

As credenciais utilizadas pelos jobs devem ser temporárias e associadas ao principal federado autorizado.

A configuração efetiva dessa relação ocorre externamente ao repositório, no GitLab e no Google Cloud.

---

## Build e rastreabilidade

Cada build utiliza como identificação principal:

    CI_COMMIT_SHORT_SHA

Isso permite relacionar uma imagem ao commit que a originou.

Na branch padrão, a imagem também pode receber:

    latest

Quando o pipeline é disparado por uma Git tag, essa tag pode ser publicada como versão adicional da imagem.

O SHA continua sendo a referência adequada para rastrear um build específico.

---

## Container

A aplicação utiliza NGINX Unprivileged e atende na porta:

    8080

O container executa como:

    UID 101
    GID 101

Controles aplicados:

- usuário non-root;
- filesystem somente leitura;
- capabilities removidas;
- no-new-privileges;
- diretórios temporários separados;
- healthcheck em `/healthz`;
- headers HTTP de segurança;
- Content Security Policy.

---

## Kubernetes

Os recursos são implantados no namespace:

    lf-labs

A arquitetura inclui:

    Namespace
       |
       +--> Deployment
       |      |
       |      +--> 2 réplicas iniciais
       |      +--> RollingUpdate
       |      +--> readiness probe
       |      +--> liveness probe
       |      +--> requests / limits
       |
       +--> Service / LoadBalancer
       |
       +--> HorizontalPodAutoscaler
       |      |
       |      +--> mínimo: 2
       |      +--> máximo: 5
       |
       +--> PodDisruptionBudget

---

## Segurança do workload

O Deployment aplica:

- `automountServiceAccountToken: false`;
- `runAsNonRoot: true`;
- UID e GID explícitos;
- `seccompProfile: RuntimeDefault`;
- `allowPrivilegeEscalation: false`;
- `readOnlyRootFilesystem: true`;
- remoção de todas as Linux capabilities.

O namespace utiliza Pod Security Standards no perfil:

    restricted

com:

    enforce
    audit
    warn

Os diretórios que precisam permanecer graváveis são fornecidos por volumes `emptyDir`.

---

## Disponibilidade

O Deployment inicia com duas réplicas e utiliza RollingUpdate com:

    maxUnavailable: 0
    maxSurge: 1

O HPA pode ajustar o número de réplicas entre:

    2 → 5

O PodDisruptionBudget mantém pelo menos uma réplica disponível durante interrupções voluntárias.

Esses recursos demonstram práticas de resiliência e disponibilidade aplicadas ao laboratório.

---

## Aplicação de demonstração

O diretório:

    app/

contém o workload utilizado para construir e testar a imagem.

Ele pode ser executado localmente com:

    docker compose up -d --build

O frontend apresenta a arquitetura de referência do pipeline e não afirma que um deploy GKE real está ativo.

---

## Infraestrutura Google Cloud

O script:

    scripts/bootstrap-gcp.sh

pode:

- validar o projeto GCP;
- habilitar APIs necessárias;
- criar o Artifact Registry quando necessário.

A criação do cluster GKE é opt-in:

    CREATE_CLUSTER=true

Isso evita criação acidental de infraestrutura que possa gerar custos.

O script não cria chaves permanentes de service account.

---

## Limites da arquitetura demonstrada

A presença dos arquivos de pipeline e infraestrutura não comprova automaticamente:

- um cluster GKE ativo;
- uma integração GitLab/GCP configurada;
- um deploy real executado;
- um endpoint público em produção.

Esses componentes dependem de infraestrutura externa.

A validação pública no GitHub é deliberadamente limitada aos componentes que podem ser testados sem credenciais GCP e sem gerar custos.
