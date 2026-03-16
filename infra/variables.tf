variable "project_id" {
  type        = string
  description = "ID do projeto GCP onde o Toolkit será instalado."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Região para os recursos de infraestrutura."
}

variable "github_repo_url" {
  type        = string
  description = "URL do repositório GitHub (ex: https://github.com/usuario/v8-toolkit.git)"
}

variable "github_token_secret_name" {
  type        = string
  default     = "github-token-dataform"
  description = "Nome do segredo no Secret Manager contendo o Personal Access Token."
}

variable "flavor" {
  type        = string
  default     = "full"
  description = "Sabor da instalação: marketing, retail_media ou full."
}