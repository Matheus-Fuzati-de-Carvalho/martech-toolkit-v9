#!/bin/bash
set -e

echo "----------------------------------------------------"
echo "🚀 MARTECH TOOLKIT V8 - PROVISIONAMENTO AUTOMÁTICO"
echo "----------------------------------------------------"

# 1. Captura Automática (Padrão v7)
PROJECT_ID=$(gcloud config get-value project)
REPO_URL="https://github.com/Matheus-Fuzati-de-Carvalho/martech-toolkit-v8"

echo "📍 Projeto Detectado: $PROJECT_ID"
echo "📦 Repo Definido: $REPO_URL"
echo "----------------------------------------------------"

# 2. Solicitação de Variáveis Dinâmicas
read -p "🔑 GitHub Token (PAT): " GH_TOKEN
read -p "🍋 Flavor (marketing / retail_media / full): " FLAVOR

# 3. Preparação do Ambiente
echo "🔧 Ativando Secret Manager..."
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID

# 4. Gerenciamento do Secret
echo "🔐 Configurando credenciais..."
# Tenta criar, se já existir, apenas adiciona nova versão (evita erro de recurso existente)
gcloud secrets create dataform-github-token --replication-policy="automatic" --project=$PROJECT_ID || true
echo -n "$GH_TOKEN" | gcloud secrets versions add dataform-github-token --data-file=- --project=$PROJECT_ID

# 5. Execução do Terraform
cd infra

# Limpeza preventiva de estados anteriores para evitar conflitos
rm -rf .terraform* terraform.tfstate* terraform init
terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="github_token=$GH_TOKEN" \
  -var="github_repo_url=$REPO_URL" \
  -var="flavor=$FLAVOR" \
  -auto-approve

echo "----------------------------------------------------"
echo "✅ DEPLOY FINALIZADO NO PROJETO: $PROJECT_ID"
echo "----------------------------------------------------"