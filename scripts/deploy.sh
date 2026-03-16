#!/bin/bash
set -e

echo "----------------------------------------------------"
echo "Martech Toolkit v8 - Deployment Script"
echo "----------------------------------------------------"

# Coleta de variáveis
read -p "GCP Project ID: " PROJECT_ID
read -p "Sabor (marketing/retail_media/full): " FLAVOR
read -p "GitHub URL: " REPO_URL

# Navega para infra
cd infra

# Inicia Terraform
terraform init

# Aplica infraestrutura
terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="flavor=$FLAVOR" \
  -var="github_repo_url=$REPO_URL" \
  -auto-approve

echo "----------------------------------------------------"
echo "Deploy finalizado com sucesso."
echo "Workflow de orquestração criado: dataform-martech-v8-flow"
echo "Aguarde o primeiro ciclo de processamento."
echo "----------------------------------------------------"