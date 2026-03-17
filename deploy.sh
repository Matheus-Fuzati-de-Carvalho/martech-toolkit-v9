#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
REPO_URL="https://github.com/Matheus-Fuzati-de-Carvalho/martech-toolkit-v8"

# Captura argumentos ou pede entrada se estiverem vazios
GH_TOKEN=${1:-""}
FLAVOR=${2:-""}

if [ -z "$GH_TOKEN" ]; then
    read -p "🔑 GitHub Token (PAT): " GH_TOKEN
fi

if [ -z "$FLAVOR" ]; then
    read -p "🍋 Flavor (marketing / retail_media / full): " FLAVOR
fi

echo "🚀 Iniciando Deploy no projeto: $PROJECT_ID"

gcloud services enable secretmanager.googleapis.com cloudresourcemanager.googleapis.com --project=$PROJECT_ID

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