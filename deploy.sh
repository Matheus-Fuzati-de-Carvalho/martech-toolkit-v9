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
SERVICE_REGION=${12}  # Novo: us-central1
DATA_LOCATION=${13}   # Novo: US
NOTIFICATION_EMAIL=${14} # Adicionado para v9

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
  -var="service_region=$SERVICE_REGION" \
  -var="data_location=$DATA_LOCATION" \
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
    --location="$SERVICE_REGION" || true

# 5. Execução de Teste do Orquestrador
echo "🚦 Disparando Workflow de teste..."
WORKFLOW_NAME=$(terraform output -raw workflow_name)
gcloud workflows run "$WORKFLOW_NAME" --project="$CURRENT_PROJECT" --location="$SERVICE_REGION"

echo "🏗️ Configurando Workspace de desenvolvimento via API..."

# Captura o token de acesso atual
ACCESS_TOKEN=$(gcloud auth print-access-token)
WORKSPACE_ID="dev-workspace"

# Chamada via CURL (O método infalível para Dataform v1beta1)
# O '-s' silencia o progresso e o '-o /dev/null' descarta a resposta gigante, mantendo o foco no status
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "https://dataform.googleapis.com/v1beta1/projects/${PROJECT_ID}/locations/${SERVICE_REGION}/repositories/martech-toolkit-v9/workspaces?workspaceId=${WORKSPACE_ID}")

if [ "$RESPONSE_CODE" == "200" ]; then
    echo "✅ Workspace '${WORKSPACE_ID}' criado com sucesso."
elif [ "$RESPONSE_CODE" == "409" ]; then
    echo "ℹ️ Workspace '${WORKSPACE_ID}' já existe. Seguindo..."
else
    echo "⚠️ Aviso: A API retornou status ${RESPONSE_CODE}. Verifique no console do Dataform."
fi

echo "🚀 DEPLOY DA INFRAESTRUTURA V9 FINALIZADO!"
