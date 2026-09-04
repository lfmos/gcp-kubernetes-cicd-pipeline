#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
  echo "[ERROR] $1" >&2
  exit 1
}

ok() {
  echo "[OK] $1"
}

require_file() {
  local file="$1"

  [[ -f "$file" ]] || fail "Required file not found: $file"
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  grep -Fq "$pattern" "$file" || fail "$description"
}


echo "Validating project structure..."

required_files=(
  "Dockerfile"
  "docker-compose.yml"
  ".gitlab-ci.yml"
  "app/index.html"
  "app/css/styles.css"
  "app/js/app.js"
  "app/nginx.conf"
  "scripts/bootstrap-gcp.sh"
  "scripts/validate.sh"
  "k8s/namespace.yaml"
  "k8s/deployment.yaml"
  "k8s/service.yaml"
  "k8s/hpa.yaml"
  "k8s/pdb.yaml"
)

for file in "${required_files[@]}"; do
  require_file "$file"
done

ok "Required project files found."


echo "Validating shell scripts..."

bash -n scripts/validate.sh ||
  fail "Syntax error in scripts/validate.sh"

bash -n scripts/bootstrap-gcp.sh ||
  fail "Syntax error in scripts/bootstrap-gcp.sh"

ok "Shell scripts have valid Bash syntax."


echo "Validating Kubernetes deployment..."

require_pattern \
  "k8s/deployment.yaml" \
  "IMAGE_PLACEHOLDER" \
  "IMAGE_PLACEHOLDER was not found in deployment.yaml"

placeholder_count="$(
  grep -o "IMAGE_PLACEHOLDER" k8s/deployment.yaml |
    wc -l |
    tr -d '[:space:]'
)"

[[ "$placeholder_count" == "1" ]] ||
  fail "deployment.yaml must contain exactly one IMAGE_PLACEHOLDER"

require_pattern \
  "k8s/deployment.yaml" \
  "automountServiceAccountToken: false" \
  "Service Account token automount must be disabled"

require_pattern \
  "k8s/deployment.yaml" \
  "runAsNonRoot: true" \
  "Container must be configured to run as non-root"

require_pattern \
  "k8s/deployment.yaml" \
  "allowPrivilegeEscalation: false" \
  "Privilege escalation must be disabled"

require_pattern \
  "k8s/deployment.yaml" \
  "readOnlyRootFilesystem: true" \
  "Root filesystem must be read-only"

require_pattern \
  "k8s/deployment.yaml" \
  "type: RuntimeDefault" \
  "RuntimeDefault seccomp profile was not found"

require_pattern \
  "k8s/deployment.yaml" \
  "readinessProbe:" \
  "Readiness probe was not found"

require_pattern \
  "k8s/deployment.yaml" \
  "livenessProbe:" \
  "Liveness probe was not found"

require_pattern \
  "k8s/deployment.yaml" \
  "resources:" \
  "Container resource requests/limits were not found"

ok "Deployment security and availability controls found."


echo "Validating resilience manifests..."

require_pattern \
  "k8s/hpa.yaml" \
  "kind: HorizontalPodAutoscaler" \
  "HorizontalPodAutoscaler manifest is invalid or missing"

require_pattern \
  "k8s/pdb.yaml" \
  "kind: PodDisruptionBudget" \
  "PodDisruptionBudget manifest is invalid or missing"

ok "HPA and PodDisruptionBudget manifests found."


echo "Validating application health endpoint..."

grep -Eq \
  'location[[:space:]]*=[[:space:]]*/healthz' \
  app/nginx.conf ||
  fail "NGINX /healthz endpoint was not found"

ok "NGINX health endpoint found."


echo "Validating GitLab pipeline integration..."

require_pattern \
  ".gitlab-ci.yml" \
  "identity: google_cloud" \
  "GitLab Google Cloud workload identity configuration was not found"

ok "Google Cloud workload identity configuration found."


echo
echo "Project validation completed successfully."