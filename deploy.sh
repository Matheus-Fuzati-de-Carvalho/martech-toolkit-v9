#!/bin/bash
set -e

echo "----------------------------------------------------"
echo "🚀 MARTECH TOOLKIT V8 - PROVISIONAMENTO COMPLETO"
echo "----------------------------------------------------"

read -p "GCP Project ID: " PROJECT_ID
read -p "GitHub Token (PAT): " GH_TOKEN
read -p "Repo URL: " REPO_URL
read -p "Flavor (marketing / retail_media / full): " FLAVOR

gcloud config set project $PROJECT_ID

# Ativação manual da API de Secret Manager (pre-requisito Terraform)
gcloud services enable secretmanager.googleapis.com

# Gerenciamento do Secret de Conexão
echo -n "$GH_TOKEN" | gcloud secrets create dataform-github-token --data-file=- --replication-policy="automatic" || \
echo -n "$GH_TOKEN" | gcloud secrets versions add dataform-github-token --data-file=-

cd infra
terraform init
terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="github_repo_url=$REPO_URL" \
  -var="flavor=$FLAVOR" \
  -auto-approve