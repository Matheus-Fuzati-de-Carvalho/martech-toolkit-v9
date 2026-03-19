# infra/dataplex.tf

# 1. Criação do Lake (Contentor de Governança)
resource "google_dataplex_lake" "martech_lake" {
  name         = "martech-toolkit-lake"
  project      = local.project_id
  location     = var.region
  display_name = "Martech Toolkit v9 Governance"
}

resource "google_dataplex_zone" "trusted_zone" {
  name         = "trusted-zone"
  lake         = google_dataplex_lake.martech_lake.name
  project      = local.project_id
  location     = var.region
  type         = "RAW"
  resource_spec {
    location_type = "SINGLE_REGION" # Ou "MULTI_REGION" se a sua var.region for "US" ou "EU"
  }

  discovery_spec {
    enabled = false
  }
}

resource "google_dataplex_zone" "refined_zone" {
  name         = "refined-zone"
  lake         = google_dataplex_lake.martech_lake.name
  project      = local.project_id
  location     = var.region
  type         = "CURATED"
  resource_spec {
    location_type = "SINGLE_REGION" 
  }

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
  discovery_spec {
    enabled = false
  }
}