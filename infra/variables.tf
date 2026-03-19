# ==============================================================================
# VARIÁVEIS DE INFRAESTRUTURA - MARTECH TOOLKIT V9
# Sincronizado com deploy.sh (Estilo v8)
# ==============================================================================

variable "project_id" {
  type        = string
  description = "ID do projeto (Capturado automaticamente, mas declarado por segurança)"
  default     = ""
}

variable "service_region" {
  description = "Região para serviços (Functions, Workflows, Scheduler)"
  type        = string
  default     = "us-central1"
}

variable "data_location" {
  description = "Localização para dados (BigQuery, Dataplex Assets)"
  type        = string
  default     = "US"
}

variable "git_token" {
  type      = string
  sensitive = true
}

variable "git_repo_url" {
  type    = string
  default = "https://github.com/Matheus-Fuzati-de-Carvalho/martech-toolkit-v9.git"
}

# --- Schemas (Datasets) ---
variable "silver_schema" {
  type    = string
  default = "TRUSTED"
}

variable "refined_schema" {
  type    = string
  default = "REFINED"
}

variable "quality_schema" {
  type    = string
  default = "QUALITY"
}

variable "assertion_schema" {
  type    = string
  default = "QUALITY_ASSERTIONS"
}

# --- Fontes Raw ---
variable "raw_ga4_dataset" {
  type    = string
  default = "RAW_SRC_GA4"
}

variable "raw_ads_dataset" {
  type    = string
  default = "RAW_SRC_ADS"
}

variable "raw_ads_table" {
  type    = string
  default = "ad_CampaignBasicStats_987654321"
}

# --- Nomes de Tabelas (Injetados via deploy.sh) ---
variable "tab_ft_ga4" {
  type    = string
  default = "FT_SIL_GA4_EVENTS"
}

variable "tab_ft_ads" {
  type    = string
  default = "FT_SIL_ADS_PERFORMANCE"
}

variable "tab_dm_mkt" {
  type    = string
  default = "DM_GOLD_MARKETING_PERFORMANCE"
}

variable "tab_dm_retail" {
  type    = string
  default = "DM_GOLD_RETAIL_CUBE"
}

# --- Orquestração e Monitoramento ---
variable "flavor" {
  type    = string
  default = "full"
}

variable "lookback_days" {
  type    = number
  default = 3
}

variable "cron_schedule" {
  type    = string
  default = "0 8 * * *"
}

variable "notification_email" {
  type    = string
  default = "alerta@exemplo.com"
}
