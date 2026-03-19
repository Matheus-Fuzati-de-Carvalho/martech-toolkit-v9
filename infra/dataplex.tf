# infra/dataplex.tf

# 1. Criação do Lake (Contentor de Governança)
resource "google_dataplex_lake" "martech_lake" {
  name         = "martech-toolkit-lake"
  project      = local.project_id
  location     = var.region
  display_name = "Martech Toolkit v9 Governance"
}

# 2. Criação das Zonas Lógicas (Sem custo fixo alto)
resource "google_dataplex_zone" "trusted_zone" {
  name         = "trusted-zone"
  lake         = google_dataplex_lake.martech_lake.name
  project      = local.project_id
  location     = var.region
  type         = "RAW" # RAW no Dataplex aceita datasets do BQ sem transformação
  discovery_spec {
    enabled = false # Mantemos desativado para evitar custos de scan automático
  }
}

resource "google_dataplex_zone" "refined_zone" {
  name         = "refined-zone"
  lake         = google_dataplex_lake.martech_lake.name
  project      = local.project_id
  location     = var.region
  type         = "CURATED"
  discovery_spec {
    enabled = false
  }
}

# 3. Associar os Datasets como Assets (A linhagem aparece aqui)
resource "google_dataplex_asset" "silver_asset" {
  name          = "trusted-dataset-asset"
  lake          = google_dataplex_lake.martech_lake.name
  dataplex_zone = google_dataplex_zone.trusted_zone.name
  project       = local.project_id
  location      = var.region

  resource_spec {
    name = "projects/${local.project_id}/datasets/${var.silver_schema}"
    type = "BIGQUERY_DATASET"
  }
}