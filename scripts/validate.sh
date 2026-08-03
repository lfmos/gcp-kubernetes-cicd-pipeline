#!/usr/bin/env bash
set -Eeuo pipefail

required_files=(
  "Dockerfile"
  "docker-compose.yml"
  ".gitlab-ci.yml"
  "app/index.html"
  "app/css/styles.css"
  "app/js/app.js"
  "app/nginx.conf"
  "k8s/namespace.yaml"
  "k8s/deployment.yaml"
  "k8s/service.yaml"
  "k8s/hpa.yaml"
  "k8s/pdb.yaml"
)

for file in "${required_files[@]}"; do
  [[ -f "${file}" ]] || { echo "Arquivo ausente: ${file}"; exit 1; }
done

grep -q "IMAGE_PLACEHOLDER" k8s/deployment.yaml || {
  echo "O placeholder da imagem não foi encontrado."
  exit 1
}

echo "Validação concluída com sucesso."
