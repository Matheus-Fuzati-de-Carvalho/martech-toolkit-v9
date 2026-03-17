#!/bin/bash
set -e

# 1. Captura de Variáveis
PROJECT_ID=$(gcloud config get-value project)
REPO_URL="https://github.com/Matheus-Fuzati-de-Carvalho/martech-toolkit-v8"

# Se houver argumentos ($1 e $2), usa eles. Se não, pergunta.
GH_TOKEN=${1:-$TOKEN_INPUT}
FLAVOR=${2:-$FLAVOR_INPUT}

if [ -z "$GH_TOKEN" ]; then
    read -p "🔑 GitHub Token (PAT): " GH_TOKEN
fi

if [ -z "$FLAVOR" ]; then
    read -p "🍋 Flavor (marketing / retail_media / full): " FLAVOR
fi

echo "----------------------------------------------------"
echo "🚀 EXECUTANDO DEPLOY V8 AUTOMATIZADO"
echo "📍 Projeto: $PROJECT_ID"
echo "🍋 Flavor: $FLAVOR"
echo "----------------------------------------------------"

# 2. Ativações Prévias de Segurança
gcloud services enable cloudresourcemanager.googleapis.com \
                       secretmanager.googleapis.com \
                       dataform.googleapis.com --project=$PROJECT_ID

# 3. Secret Manager (Força a atualização do token sempre)
gcloud secrets create dataform-github-token --replication-policy="automatic" --project=$PROJECT_ID || true
echo -n "$GH_TOKEN" | gcloud secrets versions add dataform-github-token --data-file=- --project=$PROJECT_ID

# 4. Terraform
cd infra
rm -rf .terraform* terraform.tfstate* .terraform.lock.hcl
terraform init -upgrade
terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="github_token=$GH_TOKEN" \
  -var="github_repo_url=$REPO_URL" \
  -var="flavor=$FLAVOR" \
  -auto-approve