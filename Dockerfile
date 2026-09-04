FROM nginxinc/nginx-unprivileged:1.30.4-alpine-slim

LABEL org.opencontainers.image.title="GKE CI/CD Pipeline" \
      org.opencontainers.image.description="Aplicação de referência para CI/CD com Docker, GitLab, Kubernetes e GKE" \
      org.opencontainers.image.source="https://github.com/lfmos/gcp-kubernetes-cicd-pipeline" \
      org.opencontainers.image.licenses="MIT"

COPY --chown=101:101 app/nginx.conf /etc/nginx/conf.d/default.conf
COPY --chown=101:101 app/ /usr/share/nginx/html/

USER 101:101

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1