variable "project_id" {
  type        = string
  description = "O ID do projeto GCP"
}

variable "region" {
  type        = string
  default     = "US"
  description = "Região para os recursos"
}

variable "github_repo_url" {
  type        = string
  description = "URL do repositório Git"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "PAT do GitHub"
}

variable "flavor" {
  type    = string
  default = "full"
}

# Variáveis de Origem (RAW)
variable "raw_ga4" {
  type        = string
  description = "Dataset do GA4"
}

variable "raw_ads" {
  type        = string
  description = "Dataset do Ads"
}

variable "raw_ads_table" {
  type        = string
  description = "Nome da tabela principal de Ads"
}

# Variáveis de Destino (Datasets)
variable "silver_dataset" {
  type        = string
  description = "Nome do dataset Silver"
}

variable "gold_dataset" {
  type        = string
  description = "Nome do dataset Gold"
}

# Nomes das Tabelas (Dynamic Names)
variable "tab_slv_ga4" {
  type        = string
  description = "Nome da tabela silver ga4"
}

variable "tab_slv_ads" {
  type        = string
  description = "Nome da tabela silver ads"
}

variable "tab_gld_mkt" {
  type        = string
  description = "Nome da tabela gold marketing"
}

variable "tab_gld_retail" {
  type        = string
  description = "Nome da tabela gold retail media"
}