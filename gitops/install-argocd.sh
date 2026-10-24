#!/usr/bin/env bash
set -euo pipefail

APP_FILE="${1:?Usage: install-argocd.sh <application-file>}"

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace --wait
kubectl apply -f "$APP_FILE"