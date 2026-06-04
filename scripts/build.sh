#!/usr/bin/env bash
set -euo pipefail

SERVICES=("users-api" "posts-api" "comments-api" "notifications-api")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Building SOF2AI service images..."

for SERVICE in "${SERVICES[@]}"; do
  echo ""
  echo "--- Building $SERVICE ---"
  docker build \
    -t "${SERVICE}:latest" \
    -f "${ROOT_DIR}/services/${SERVICE}/Dockerfile" \
    "${ROOT_DIR}/services/${SERVICE}"
  echo "Built ${SERVICE}:latest"
done

echo ""
echo "==> All images built successfully."
docker images | grep -E "users-api|posts-api|comments-api|notifications-api"
