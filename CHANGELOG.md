# Changelog

Todas as mudanças relevantes deste projeto são registradas neste arquivo.

## [1.1.0] - 2026-09-04

### Adicionado

- Workflow de validação pública com GitHub Actions.
- ShellCheck para os scripts Bash.
- Build automatizado da imagem no GitHub Actions.
- Teste real do endpoint `/healthz`.
- Verificação automatizada de execução non-root.
- Validação do Docker Compose.
- Pod Security Standards no perfil `restricted`.
- UID e GID explícitos no Deployment Kubernetes.
- Validação adicional de controles de segurança e disponibilidade.
- Suporte a tags Git como versão adicional da imagem no pipeline GitLab.
- Documentação detalhada dos limites entre validação local e infraestrutura GCP real.

### Alterado

- Pipeline GitLab renomeado para `.gitlab-ci.yml`, seguindo o nome padrão esperado pelo GitLab.
- Estágio de validação do GitLab passou a executar `scripts/validate.sh`.
- Autenticação do Artifact Registry simplificada para utilizar `gcloud` com Workload Identity Federation.
- Pipeline atualizado para trabalhar com branches e tags.
- `scripts/bootstrap-gcp.sh` reformulado para evitar criação automática de cluster GKE.
- Criação de cluster passou a exigir `CREATE_CLUSTER=true`.
- Removida a criação automática de service account e de permissões IAM amplas pelo bootstrap.
- Dockerfile atualizado para versão explícita do NGINX Unprivileged.
- Usuário `101:101` declarado explicitamente no container.
- Docker Compose reforçado com non-root, capabilities removidas, filesystem somente leitura e limite de processos.
- Content Security Policy do NGINX endurecida.
- Frontend atualizado para representar um fluxo de referência, sem afirmar deploy real em produção.
- Arquitetura e README revisados para refletir o comportamento real do projeto.
- Kustomize atualizado para aplicar o label `managed-by` sem alterar selectors.

### Segurança

- Removido `'unsafe-inline'` do `style-src` da Content Security Policy.
- Adicionado `object-src 'none'`.
- Explicitado `runAsUser`, `runAsGroup` e `fsGroup`.
- Mantido `automountServiceAccountToken: false`.
- Mantido `allowPrivilegeEscalation: false`.
- Mantido `readOnlyRootFilesystem: true`.
- Mantido `seccompProfile: RuntimeDefault`.
- Mantida remoção de todas as Linux capabilities.
- Namespace configurado com Pod Security Standards `restricted`.

### Documentação

- README reposicionado como projeto técnico de CI/CD, Kubernetes, cloud e DevSecOps.
- Removidas afirmações que poderiam sugerir um deploy GKE já executado.
- Documentação de arquitetura atualizada.
- Custos e dependências externas do Google Cloud documentados com mais clareza.
- Workload Identity Federation documentada como configuração externa necessária.

---

## [1.0.0] - 2026-08-03

### Adicionado

- Aplicação web LF.LABS responsiva.
- Dockerfile com NGINX não privilegiado.
- Docker Compose para execução local.
- Pipeline GitLab CI/CD com validação, build, publicação e deploy.
- Integração planejada com Google Artifact Registry e GKE.
- Manifests de Deployment, Service, HPA e PodDisruptionBudget.
- Estrutura preparada para repositório e pipeline técnico.
- Documentação de arquitetura e bootstrap da infraestrutura.