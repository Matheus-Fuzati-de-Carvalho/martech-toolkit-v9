#!/bin/bash

set -e

# 1. Captura de Parâmetros (Sincronizado com o HCL)
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
SERVICE_REGION=${12:-"us-central1"}
DATA_LOCATION=${13:-"US"}
NOTIFICATION_EMAIL=${14}

echo "--------------------------------------------------------"
echo "🚀 Iniciando Deploy Martech v9 (Infra Only)"
echo "--------------------------------------------------------"

# 2. Terraform Apply
cd infra/
terraform init -reconfigure

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

# 3. Captura de variáveis do output do Terraform
CURRENT_PROJECT=$(gcloud config get-value project)
# Extrai apenas o nome final do repositório (ex: martech-toolkit-v9) do ID completo
REPO_NAME_SHORT=$(terraform output -raw dataform_repository_id | awk -F/ '{print $NF}')

echo "⏳ Aguardando 30s para propagação de APIs..."
sleep 30

# 5. Criação do Workspace via API (Corrigido com SERVICE_REGION)
echo "🏗️ Criando Workspace de desenvolvimento..."
ACCESS_TOKEN=$(gcloud auth print-access-token)

# Usamos o 'curl' para evitar dependência de versão do gcloud
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "https://dataform.googleapis.com/v1beta1/projects/${CURRENT_PROJECT}/locations/${SERVICE_REGION}/repositories/${REPO_NAME_SHORT}/workspaces?workspaceId=dev-workspace")

if [ "$RESPONSE_CODE" == "200" ] || [ "$RESPONSE_CODE" == "409" ]; then
    echo "✅ Workspace pronto (Status: $RESPONSE_CODE)."
else
    echo "⚠️ Aviso: Workspace não pôde ser criado (Status: $RESPONSE_CODE)."
fi

echo "--------------------------------------------------------"
echo "🏁 DEPLOY V9 FINALIZADO!"
echo "--------------------------------------------------------"
