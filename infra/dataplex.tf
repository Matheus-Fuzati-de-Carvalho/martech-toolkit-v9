# infra/dataplex.tf

# 1. Criação do Lake
resource "google_dataplex_lake" "martech_lake" {
  name         = "martech-toolkit-lake"
  project      = local.project_id
  location     = var.service_region
  display_name = "Martech Toolkit v9 Governance"
  
  # Garante que as APIs estejam prontas antes de criar o Lake
  depends_on = [time_sleep.wait_api_propagation]
}

# 2. Zonas (CURATED para evitar datasets extras)
resource "google_dataplex_zone" "trusted_zone" {
  name     = "trusted-zone"
  lake     = google_dataplex_lake.martech_lake.name
  project  = local.project_id
  location = var.service_region
  type     = "CURATED"

  resource_spec {
    location_type = "MULTI_REGION" # Mude para MULTI_REGION se var.service_region for "US"
  }

  discovery_spec {
    enabled = false
  }
}

resource "google_dataplex_zone" "refined_zone" {
  name     = "refined-zone"
  lake     = google_dataplex_lake.martech_lake.name
  project  = local.project_id
  location = var.service_region
  type     = "CURATED"

  resource_spec {
    location_type = "MULTI_REGION"
  }

  discovery_spec {
    enabled = false
  }
}

# 3. Assets (Mapeando os Datasets Reais)

# Asset Silver
resource "google_dataplex_asset" "silver_asset" {
  name          = "trusted-dataset-asset"
  lake          = google_dataplex_lake.martech_lake.name
  dataplex_zone = google_dataplex_zone.trusted_zone.name
  project       = local.project_id
  location      = var.service_region

  resource_spec {
    name = "projects/${local.project_id}/datasets/${var.silver_schema}"
    type = "BIGQUERY_DATASET"
  }

  discovery_spec {
    enabled = false
  }
}

# Asset Gold (Adicionado para completar a linhagem)
resource "google_dataplex_asset" "refined_asset" {
  name          = "refined-dataset-asset"
  lake          = google_dataplex_lake.martech_lake.name
  dataplex_zone = google_dataplex_zone.refined_zone.name
  project       = local.project_id
  location      = var.service_region

  resource_spec {
    name = "projects/${local.project_id}/datasets/${var.refined_schema}"
    type = "BIGQUERY_DATASET"
  }

  discovery_spec {
    enabled = false
  }
}
