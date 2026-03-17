#!/bin/bash
set -e

# Argumentos (1 a 13)
GH_TOKEN=$1
FLAVOR=${2:-"full"}
RAW_GA4=${3:-"raw_ga4"}
RAW_ADS=${4:-"raw_ads"}
ADS_RAW_TAB=${5:-"ad_CampaignBasicStats_987654321"}
SILVER_DS=${6:-"martech_silver"}
GOLD_DS=${7:-"martech_gold"}
TAB_SLV_GA4=${8:-"slv_ga4_events"}
TAB_SLV_ADS=${9:-"slv_ads_performance"}
TAB_GLD_MKT=${10:-"fct_marketing_performance"}
TAB_GLD_RETAIL=${11:-"fct_retail_media_cube"}
REGION=${12:-"us-east1"}
SCHEDULE_CRON="${13:-0 6 * * *}"

REPO_URL="https://github.com/Matheus-Fuzati-de-Carvalho/martech-toolkit-v8"
PROJECT_ID=$(gcloud config get-value project)

echo "🧬 Ajustando workflow_settings na raiz..."
sed -i "s/defaultProject: .*/defaultProject: \"$PROJECT_ID\"/g" workflow_settings.yaml
sed -i "s/defaultLocation: .*/defaultLocation: \"US\"/g" workflow_settings.yaml

echo "🚀 Iniciando Deploy..."

gcloud services enable secretmanager.googleapis.com \
                       cloudresourcemanager.googleapis.com \
                       dataform.googleapis.com \
                       iam.googleapis.com --project=$PROJECT_ID

gcloud secrets create dataform-github-token --replication-policy="automatic" --project=$PROJECT_ID || true
echo -n "$GH_TOKEN" | gcloud secrets versions add dataform-github-token --data-file=- --project=$PROJECT_ID

cd infra
# REMOVIDO terraform.tfstate* daqui para manter a memória do deploy
rm -rf .terraform .terraform.lock.hcl 

terraform init -upgrade

echo "🔍 Sincronizando estado (Check de Service Account)..."
SA_EMAIL="martech-v8-orchestrator@$PROJECT_ID.iam.gserviceaccount.com"

# Importa a SA caso o estado tenha sido perdido por algum motivo
terraform import google_service_account.martech_sa projects/$PROJECT_ID/serviceAccounts/$SA_EMAIL || true

echo "🚀 Rodando Terraform Apply..."
terraform apply \
  -var="project_id=$PROJECT_ID" \
  -var="github_token=$GH_TOKEN" \
  -var="github_repo_url=$REPO_URL" \
  -var="flavor=$FLAVOR" \
  -var="raw_ga4=$RAW_GA4" \
  -var="raw_ads=$RAW_ADS" \
  -var="raw_ads_table=$ADS_RAW_TAB" \
  -var="silver_dataset=$SILVER_DS" \
  -var="gold_dataset=$GOLD_DS" \
  -var="tab_slv_ga4=$TAB_SLV_GA4" \
  -var="tab_slv_ads=$TAB_SLV_ADS" \
  -var="tab_gld_mkt=$TAB_GLD_MKT" \
  -var="tab_gld_retail=$TAB_GLD_RETAIL" \
  -var="region=$REGION" \
  -var="schedule_cron=$SCHEDULE_CRON" \
  -auto-approve

# --- BLOCO DE OUTPUT FINAL ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "\n${GREEN}${BOLD}✅ DEPLOY FINALIZADO COM SUCESSO!${NC}"
echo "--------------------------------------------------------"
echo -e "${BOLD}🚀 Toolkit Martech v8.1${NC}"
echo -e "ID do Projeto:   ${CYAN}$PROJECT_ID${NC}"
echo -e "Pacote (Flavor): ${CYAN}$FLAVOR${NC}"
echo -e "Região Infra:    ${CYAN}$REGION${NC} (Repositório/Workflow)"
echo -e "Local Dados:     ${CYAN}US${NC} (BigQuery)"
echo "--------------------------------------------------------"
echo -e "${BOLD}📁 Camadas de Dados:${NC}"
echo -e "  - Silver Dataset: ${GREEN}$SILVER_DS${NC}"
echo -e "  - Gold Dataset:   ${GREEN}$GOLD_DS${NC}"
echo "--------------------------------------------------------"
echo -e "${BOLD}🤖 Automação e Orquestração:${NC}"
echo -e "  - Dataform Repo:  ${GREEN}toolkit-martech-v8${NC}"
echo -e "  - Workflow:       ${GREEN}martech-v8-orchestrator${NC}"
echo -e "  - Scheduler Job:  ${GREEN}daily-v8-sync${NC}"
echo -e "  - Agendamento:    ${CYAN}\"$SCHEDULE_CRON\"${NC}"
echo "--------------------------------------------------------"
echo -e "${BOLD}🔗 Próximos Passos:${NC}"
echo -e "1. Acesse o console do Dataform para validar a compilação."
echo -e "2. O Cloud Scheduler já está ativo com o cron acima."
echo "--------------------------------------------------------"