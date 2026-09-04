#!/usr/bin/env bash
set -Eeuo pipefail


PROJECT_ID="${PROJECT_ID:-}"
REGION="${REGION:-us-central1}"
CLUSTER_NAME="${CLUSTER_NAME:-portfolio-cluster}"
REPOSITORY="${REPOSITORY:-portfolio-images}"

# Cluster creation is intentionally opt-in because GKE resources can incur costs.
CREATE_CLUSTER="${CREATE_CLUSTER:-false}"


fail() {
  echo "[ERROR] $1" >&2
  exit 1
}


ok() {
  echo "[OK] $1"
}


command_exists() {
  command -v "$1" >/dev/null 2>&1
}


echo "GCP bootstrap for gcp-kubernetes-cicd-pipeline"
echo


command_exists gcloud ||
  fail "gcloud CLI was not found."

[[ -n "$PROJECT_ID" ]] ||
  fail "Define PROJECT_ID before running this script."


echo "[1/5] Validating Google Cloud project..."

gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1 ||
  fail "Project '$PROJECT_ID' does not exist or is not accessible."

gcloud config set project "$PROJECT_ID" >/dev/null

ok "Project configured: $PROJECT_ID"


echo "[2/5] Enabling required APIs..."

gcloud services enable \
  artifactregistry.googleapis.com \
  container.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  --project="$PROJECT_ID"

ok "Required APIs enabled."


echo "[3/5] Configuring Artifact Registry..."

if gcloud artifacts repositories describe "$REPOSITORY" \
  --location="$REGION" \
  --project="$PROJECT_ID" \
  >/dev/null 2>&1; then

  ok "Artifact Registry repository already exists."

else

  gcloud artifacts repositories create "$REPOSITORY" \
    --repository-format=docker \
    --location="$REGION" \
    --project="$PROJECT_ID" \
    --description="Container images for the GKE CI/CD portfolio project"

  ok "Artifact Registry repository created."

fi


echo "[4/5] Checking GKE cluster..."

if [[ "$CREATE_CLUSTER" == "true" ]]; then

  echo
  echo "WARNING: GKE resources can generate Google Cloud charges."
  echo "Cluster creation was explicitly enabled with CREATE_CLUSTER=true."
  echo

  if gcloud container clusters describe "$CLUSTER_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    >/dev/null 2>&1; then

    ok "GKE cluster already exists."

  else

    gcloud container clusters create-auto "$CLUSTER_NAME" \
      --region="$REGION" \
      --project="$PROJECT_ID"

    ok "GKE Autopilot cluster created."

  fi

else

  echo "[SKIP] GKE cluster creation is disabled."
  echo "       Use CREATE_CLUSTER=true only when you intentionally want"
  echo "       to create cloud infrastructure."

fi


echo "[5/5] GitLab identity configuration..."

cat <<EOF

Google Cloud base resources are ready.

Artifact Registry:
  ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}

GKE cluster:
  ${CLUSTER_NAME}

Cluster creation enabled:
  ${CREATE_CLUSTER}


NEXT STEPS

1. Open the GitLab project.

2. Go to:
   Settings > Integrations > Google Cloud IAM

3. Configure Workload Identity Federation for the Google Cloud project.

4. Restrict the federated identity to the intended GitLab project or
   appropriate GitLab role instead of granting broad anonymous access.

5. Grant only the permissions required by the pipeline, including
   Artifact Registry write access and the permissions required to
   access/deploy to the target GKE cluster.

6. Configure the Google Artifact Management integration so the pipeline
   receives variables such as:

   GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID
   GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION
   GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME

7. Review the configuration before pushing to the default branch,
   because the default branch contains the deploy job.


No service-account key is created by this script.
Workload Identity Federation should provide short-lived credentials.

EOF

ok "Bootstrap completed."