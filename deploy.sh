#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
REPO_URL="https://github.com/Matheus-Fuzati-de-Carvalho/martech-toolkit-v8"

echo "----------------------------------------------------"
echo "🚀 DEPLOY V8 - ESTRUTURA ROOT"
echo "📍 Projeto: $PROJECT_ID"
echo "----------------------------------------------------"

read -p "🔑 GitHub Token (PAT): " GH_TOKEN
read -p "🍋 Flavor (marketing / retail_media / full): " FLAVOR

# Ativação do Secret Manager
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID

# Gerenciamento do Secret
gcloud secrets create dataform-github-token --replication-policy="automatic" --project=$PROJECT_ID || true
echo -n "$GH_TOKEN" | gcloud secrets versions add dataform-github-token --data-file=- --project=$PROJECT_ID

cd infra
rm -rf .terraform* terraform.tfstate* .terraform.lock.hcl

terraform init -upgrade
terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="github_token=$GH_TOKEN" \
  -var="github_repo_url=$REPO_URL" \
  -var="flavor=$FLAVOR" \
  -auto-approve