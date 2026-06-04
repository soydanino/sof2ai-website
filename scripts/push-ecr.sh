#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="${ROOT_DIR}/infra"

SERVICES=("users-api" "posts-api" "comments-api" "notifications-api")

# Read outputs from Terraform
echo "==> Reading Terraform outputs..."
cd "$INFRA_DIR"
AWS_REGION=$(terraform output -raw ec2_public_ip 2>/dev/null || echo "us-east-1")
AWS_REGION="${AWS_REGION:-us-east-1}"

ECR_USERS=$(terraform output -raw ecr_users_api_url)
ECR_POSTS=$(terraform output -raw ecr_posts_api_url)
ECR_COMMENTS=$(terraform output -raw ecr_comments_api_url)
ECR_NOTIFICATIONS=$(terraform output -raw ecr_notifications_api_url)

declare -A ECR_URLS=(
  ["users-api"]="$ECR_USERS"
  ["posts-api"]="$ECR_POSTS"
  ["comments-api"]="$ECR_COMMENTS"
  ["notifications-api"]="$ECR_NOTIFICATIONS"
)

# Extract account ID and region from the first ECR URL
ECR_REGISTRY=$(echo "$ECR_USERS" | cut -d'/' -f1)
REGION=$(echo "$ECR_USERS" | grep -oP '(?<=\.)[a-z0-9-]+(?=\.amazonaws)')
REGION="${REGION:-us-east-1}"

echo "==> Logging in to ECR registry: $ECR_REGISTRY"
aws ecr get-login-password --region "$REGION" | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo ""
echo "==> Tagging and pushing images..."

for SERVICE in "${SERVICES[@]}"; do
  ECR_URL="${ECR_URLS[$SERVICE]}"
  echo ""
  echo "--- $SERVICE -> $ECR_URL ---"
  docker tag "${SERVICE}:latest" "${ECR_URL}:latest"
  docker push "${ECR_URL}:latest"
  echo "Pushed ${SERVICE}:latest to ECR"
done

echo ""
echo "==> All images pushed to ECR successfully."
