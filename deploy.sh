#!/bin/bash

# ==============================================================================
# MARTECH TOOLKIT V9 - ONE TOUCH DEPLOYER (Legacy Parameter Style)
# ==============================================================================

set -e

# Captura de Parâmetros Posicionais (Padrão v8)
GIT_TOKEN=$1
FLAVOR=${2:-"full"}
RAW_GA4_DATASET=${3:-"RAW_SRC_GA4"}
RAW_ADS_DATASET=${4:-"RAW_SRC_ADS"}
RAW_ADS_TABLE=${5:-"ad_CampaignBasicStats_987654321"}
SILVER_SCHEMA=${6:-"TRUSTED"}
REFINED_SCHEMA=${7:-"REFINED"}
TAB_FT_GA4=${8:-"FT_SIL_GA4_EVENTS"}
TAB_FT_ADS=${9:-"FT_SIL_ADS_PERFORMANCE"}
TAB_DM_MKT=${10:-"DM_GOLD_MARKETING_PERFORMANCE"}
TAB_DM_RETAIL=${11:-"DM_GOLD_RETAIL_CUBE"}
REGION=${12:-"US"}
NOTIFICATION_EMAIL=${13:-"seu-email-padrao@dominio.com"} # Adicionado para v9

# Validação Inicial
if [ -z "$GIT_TOKEN" ]; then
    echo "❌ Erro: O GIT_TOKEN (Parâmetro 1) é obrigatório."
    exit 1
fi

echo "--------------------------------------------------------"
echo "🛠️ Preparando Ambiente Virgem no GCP..."
echo "--------------------------------------------------------"

# 1. Ativação de API Crítica para o Terraform
gcloud services enable cloudresourcemanager.googleapis.com

# 2. Configuração do Terraform
cd infra/
terraform init -reconfigure

echo "🏗️ Aplicando Infraestrutura v9 (APIs, BQ, Workflows, Dataplex)..."

terraform apply -auto-approve \
  -var="git_token=$GIT_TOKEN" \
  -var="flavor=$FLAVOR" \
  -var="raw_ga4_dataset=$RAW_GA4_DATASET" \
  -var="raw_ads_dataset=$RAW_ADS_DATASET" \
  -var="raw_ads_table=$RAW_ADS_TABLE" \
  -var="silver_schema=$SILVER_SCHEMA" \
  -var="refined_schema=$REFINED_SCHEMA" \
  -var="tab_ft_ga4=$TAB_FT_GA4" \
  -var="tab_ft_ads=$TAB_FT_ADS" \
  -var="tab_dm_mkt=$TAB_DM_MKT" \
  -var="tab_dm_retail=$TAB_DM_RETAIL" \
  -var="region=$REGION" \
  -var="notification_email=$NOTIFICATION_EMAIL"

# 3. Tratamento de Latência (Garantindo que o IAM propague)
echo "⏳ Aguardando 60 segundos para propagação de permissões..."
sleep 60

# 4. Sincronização do Dataform
CURRENT_PROJECT=$(gcloud config get-value project)
REPO_NAME=$(terraform output -raw dataform_repository_id)

echo "🔄 Sincronizando repositório com o Git..."
gcloud dataform repositories fetch-remote-branches "$REPO_NAME" \
    --project="$CURRENT_PROJECT" \
    --location="$REGION" || true

# 5. Execução de Teste do Orquestrador
echo "🚦 Disparando Workflow de teste..."
WORKFLOW_NAME=$(terraform output -raw workflow_name)
gcloud workflows run "$WORKFLOW_NAME" --project="$CURRENT_PROJECT" --location="$REGION"

echo "🏗️ Criando Workspace de desenvolvimento no Dataform..."
gcloud dataform workspaces create dev-workspace \
    --repository=martech-toolkit-v9 \
    --location=$REGION \
    --project=$PROJECT_ID \
    --quiet || echo "⚠️ Workspace já existe ou houve um erro leve."

echo "--------------------------------------------------------"
echo "✅ DEPLOY v9 FINALIZADO COM SUCESSO!"
echo "--------------------------------------------------------"