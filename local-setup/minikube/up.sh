#!/usr/bin/env bash
set -euo pipefail

PROFILE=taskboard
IMAGE=taskboard-backend:local
NAMESPACE=taskboard
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# 1. Start minikube, only if it isn't already running
if ! minikube status -p "$PROFILE" >/dev/null 2>&1; then
  minikube start -p "$PROFILE" --cpus 2 --memory 4096
fi

# 2. Build the backend image on your laptop
docker build --pull -t "$IMAGE" "$ROOT/app/backend"

# 3. Copy the image into minikube
minikube -p "$PROFILE" image load "$IMAGE"

# 4. Install the Helm chart with the local values
helm upgrade --install taskboard "$ROOT/deploy/helm/taskboard" \
  --kube-context "$PROFILE" -n "$NAMESPACE" --create-namespace \
  -f "$ROOT/deploy/helm/taskboard/values-local.yaml" --wait

# 5. Run the chart's test
helm test taskboard --kube-context "$PROFILE" -n "$NAMESPACE" --logs