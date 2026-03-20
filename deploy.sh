#!/bin/bash

set -e

# 1. Captura de Parâmetros
GIT_TOKEN=$1
FLAVOR=${2:-"full"}
RAW_GA4_DATASET=${3:-"RAW_SRC_GA4_EXTERNAL"}
RAW_ADS_DATASET=${4:-"RAW_SRC_ADS_EXTERNAL"}
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
EMAIL_USER=${15}      # Novo: Para SMTP
EMAIL_PASSWORD=${16}  # Novo: Para SMTP (App Password)

# Captura o projeto atual para garantir consistência
CURRENT_PROJECT=$(gcloud config get-value project)

echo "--------------------------------------------------------"
echo "🚀 Iniciando Deploy Martech v9 (Infra & Config)"
echo "--------------------------------------------------------"
echo "Projeto: $CURRENT_PROJECT"
echo "Região: $SERVICE_REGION"
echo "--------------------------------------------------------"

# 2. Execução do Terraform
cd infra/
terraform init -reconfigure

terraform apply -auto-approve \
  -var="project_id=$CURRENT_PROJECT" \
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
  -var="notification_email=$NOTIFICATION_EMAIL" \
  -var="email_user=$EMAIL_USER" \
  -var="email_password=$EMAIL_PASSWORD"

# 3. Captura do ID do Repositório para o Workspace
# Usamos o ID completo para evitar erro 400 em comandos posteriores
REPO_NAME_SHORT=$(terraform output -raw dataform_repository_id | awk -F/ '{print $NF}')

echo "⏳ Aguardando propagação de permissões (30s)..."
sleep 30

# 4. Criação do Workspace de Desenvolvimento
echo "🏗️ Criando Workspace: dev-workspace..."
ACCESS_TOKEN=$(gcloud auth print-access-token)

RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "https://dataform.googleapis.com/v1beta1/projects/${CURRENT_PROJECT}/locations/${SERVICE_REGION}/repositories/${REPO_NAME_SHORT}/workspaces?workspaceId=dev-workspace")

if [ "$RESPONSE_CODE" == "200" ] || [ "$RESPONSE_CODE" == "409" ]; then
    echo "✅ Workspace pronto ou já existente ($RESPONSE_CODE)."
else
    echo "⚠️ Erro ao criar Workspace. Status: $RESPONSE_CODE"
fi

echo "--------------------------------------------------------"
echo "🏁 DEPLOY FINALIZADO COM SUCESSO!"
echo "💡 Todas as variáveis foram injetadas no Workflow."
echo "--------------------------------------------------------"
echo ""
echo "========================================================"
echo "📊 RESUMO DO DEPLOY - MARTECH TOOLKIT V9"
echo "========================================================"
echo "🏷️  PROJETO:        $CURRENT_PROJECT"
echo "🌍 REGIÃO:         $SERVICE_REGION ($DATA_LOCATION)"
echo "🍦 SABOR (FLAVOR): $FLAVOR"
echo "--------------------------------------------------------"
echo "🗄️  DATASETS (BigQuery):"
echo "   🔹 RAW GA4:      $RAW_GA4_DATASET"
echo "   🔹 RAW ADS:      $RAW_ADS_DATASET"
echo "   🔹 SILVER:       $SILVER_SCHEMA"
echo "   🔹 REFINED:      $REFINED_SCHEMA"
echo "   🔹 QUALITY:      QUALITY (Audit & Assertions)"
echo "--------------------------------------------------------"
echo "🏗️  DATAFORM:"
echo "   🔹 REPOSITÓRIO:  $REPO_NAME_SHORT"
echo "   🔹 WORKSPACE:    dev-workspace"
echo "--------------------------------------------------------"
echo "🧠 ORQUESTRAÇÃO & GOVERNANÇA:"
echo "   🔹 WORKFLOW:     martech-v9-orchestrator"
echo "   🔹 DATAPLEX:     martech-toolkit-lake"
echo "--------------------------------------------------------"
echo "🔔 NOTIFICAÇÕES (SMTP):"
echo "   🔹 DESTINATÁRIO: $NOTIFICATION_EMAIL"
echo "   🔹 REMETENTE:    $EMAIL_USER"
echo "   🔹 STATUS:       Configurado (Porta 587)"
echo "========================================================"
echo "✅ TUDO PRONTO! Seu ambiente está operacional."
echo "========================================================"
