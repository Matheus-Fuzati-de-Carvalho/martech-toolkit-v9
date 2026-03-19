# infra/main.tf

# 1. Captura automaticamente o projeto configurado no gcloud/provider
data "google_client_config" "current" {}

locals {
  project_id = data.google_client_config.current.project
  # Lista de datasets para criação em lote
  datasets = [
    var.silver_schema,
    var.refined_schema,
    var.quality_schema,
    var.assertion_schema
  ]
}

# 2. Ativação das APIs necessárias (Obrigatório para um deploy limpo)
resource "google_project_service" "services" {
  for_each = toset([
    "dataform.googleapis.com",
    "bigquery.googleapis.com",
    "workflows.googleapis.com",
    "dataplex.googleapis.com",
    "cloudfunctions.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "pubsub.googleapis.com"
  ])
  service = each.key
  disable_on_destroy = false
}

resource "time_sleep" "wait_api_propagation" {
  create_duration = "30s"
  depends_on      = [google_project_service.services]
}

# 3. Criação dos Datasets no BigQuery
resource "google_bigquery_dataset" "datasets" {
  for_each = toset(local.datasets)
  dataset_id = each.key
  location   = var.region
  project    = local.project_id

  labels = {
    managed_by = "terraform"
    toolkit    = "martech-v9"
  }

  depends_on = [google_project_service.services]
}
