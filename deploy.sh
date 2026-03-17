#!/bin/bash
set -e

PROJECT_ID=$(gcloud config get-value project)
REPO_URL="https://github.com/Matheus-Fuzati-de-Carvalho/martech-toolkit-v8"

# Mapeamento de Argumentos (Ordem é Vital)
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

if [ -z "$GH_TOKEN" ]; then echo "❌ Erro: Token obrigatório."; exit 1; fi

echo "🚀 Iniciando Deploy v8.1 (Cenário B - Full Dynamic)..."

# Ativações prévias
gcloud services enable secretmanager.googleapis.com cloudresourcemanager.googleapis.com dataform.googleapis.com --project=$PROJECT_ID

# Secret Manager
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
  -var="raw_ga4=$RAW_GA4" \
  -var="raw_ads=$RAW_ADS" \
  -var="raw_ads_table=$ADS_RAW_TAB" \
  -var="silver_dataset=$SILVER_DS" \
  -var="gold_dataset=$GOLD_DS" \
  -var="tab_slv_ga4=$TAB_SLV_GA4" \
  -var="tab_slv_ads=$TAB_SLV_ADS" \
  -var="tab_gld_mkt=$TAB_GLD_MKT" \
  -var="tab_gld_retail=$TAB_GLD_RETAIL" \
  -auto-approve