#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-helm}"
PROFILE=taskboard
IMAGE=taskboard-backend:local
NAMESPACE=taskboard
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# 1. Start minikube, only if it isn't already running
if ! minikube status -p "$PROFILE" >/dev/null 2>&1; then
  minikube start -p "$PROFILE" --cpus 2 --memory 4096
fi

# 2. Build the backend image and copy it into minikube
docker build --pull -t "$IMAGE" "$ROOT/app/backend"
minikube -p "$PROFILE" image load "$IMAGE"

if [ "$MODE" = "argocd" ]; then
  # 3a. Argo CD mode: Argo CD deploys the chart from Git
  kubectl config use-context "$PROFILE"
  "$ROOT/gitops/install-argocd.sh" "$ROOT/gitops/applications/taskboard-local.yaml"
else
  # 3b. Normal mode: install the chart directly
  helm upgrade --install taskboard "$ROOT/deploy/helm/taskboard" \
    --kube-context "$PROFILE" -n "$NAMESPACE" --create-namespace \
    -f "$ROOT/deploy/helm/taskboard/values-local.yaml" --wait
  helm test taskboard --kube-context "$PROFILE" -n "$NAMESPACE" --logs
fi