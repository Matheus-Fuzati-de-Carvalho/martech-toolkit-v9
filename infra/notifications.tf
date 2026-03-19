# infra/notifications.tf

# 1. Tópico Pub/Sub para Alertas
resource "google_pubsub_topic" "pipeline_alerts" {
  name       = "martech-v9-alerts"
  project    = local.project_id
  depends_on = [time_sleep.wait_api_propagation]
}

# 2. Permissão para o Workflow publicar
resource "google_pubsub_topic_iam_member" "workflow_publisher" {
  project = local.project_id
  topic   = google_pubsub_topic.pipeline_alerts.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# 3. Cloud Function de E-mail
resource "google_cloudfunctions2_function" "email_notifier" {
  name        = "martech-v9-email-sender"
  location    = var.region
  project     = local.project_id
  description = "Envia notificações de erro do Dataform por e-mail"

  build_config {
    runtime     = "python311"
    entry_point = "send_email_notification" 
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }
  depends_on = [
    time_sleep.wait_api_propagation,
    google_storage_bucket_object.function_source
  ]
}

  service_config {
    max_instance_count = 1
    available_memory   = "256Mi"
    timeout_seconds    = 60
    environment_variables = {
      NOTIFICATION_EMAIL = var.notification_email
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.pipeline_alerts.id
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
  }
}

# 4. Bucket para a Função
resource "google_storage_bucket" "function_bucket" {
  name                        = "${local.project_id}-fn-sources"
  location                    = var.region
  project                     = local.project_id
  uniform_bucket_level_access = true
  force_destroy               = true
  depends_on                  = [time_sleep.wait_api_propagation]
}

# 5. Zip dos arquivos
data "archive_file" "function_zip" {
  type        = "zip"
  output_path = "${path.module}/function_deploy.zip"
  
  source {
    content  = file("${path.module}/files/main.py")
    filename = "main.py"
  }
  
  source {
    content  = file("${path.module}/files/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "function_source" {
  name   = "function-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_zip.output_path
}