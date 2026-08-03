#!/usr/bin/env bash
set -Eeuo pipefail

# Ajuste antes de executar ou exporte as variáveis no terminal.
PROJECT_ID="${PROJECT_ID:-seu-projeto-gcp}"
REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-portfolio-cluster}"
REPOSITORY="${REPOSITORY:-portfolio-images}"
SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME:-gitlab-cicd}"

if [[ "${PROJECT_ID}" == "seu-projeto-gcp" ]]; then
  echo "Defina PROJECT_ID com o ID real do projeto GCP."
  exit 1
fi

SERVICE_ACCOUNT="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "[1/5] Configurando projeto"
gcloud config set project "${PROJECT_ID}"

echo "[2/5] Habilitando APIs"
gcloud services enable \
  artifactregistry.googleapis.com \
  container.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com

echo "[3/5] Criando Artifact Registry quando necessário"
gcloud artifacts repositories describe "${REPOSITORY}" --location "${REGION}" >/dev/null 2>&1 || \
  gcloud artifacts repositories create "${REPOSITORY}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Imagens do portfólio LF.LABS"

echo "[4/5] Criando conta de serviço quando necessário"
gcloud iam service-accounts describe "${SERVICE_ACCOUNT}" >/dev/null 2>&1 || \
  gcloud iam service-accounts create "${SERVICE_ACCOUNT_NAME}" \
    --display-name="GitLab CI/CD"

for ROLE in roles/artifactregistry.writer roles/container.developer; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="${ROLE}" \
    --condition=None >/dev/null
done

echo "[5/5] Criando cluster GKE Autopilot quando necessário"
gcloud container clusters describe "${CLUSTER_NAME}" --region "${REGION}" >/dev/null 2>&1 || \
  gcloud container clusters create-auto "${CLUSTER_NAME}" --region "${REGION}"

cat <<EOF

Recursos básicos criados.

Próximos passos:
1. Configure a integração Google Cloud no projeto GitLab.
2. Informe no GitLab: cluster ${CLUSTER_NAME} e região ${REGION}.
3. Confirme as permissões de Workload Identity Federation.
4. Faça push para a branch main.

Conta de serviço: ${SERVICE_ACCOUNT}
Artifact Registry: ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}
EOF
