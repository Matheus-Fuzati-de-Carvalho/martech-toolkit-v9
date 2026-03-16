variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east1"
}

variable "github_repo_url" {
  type = string
}

# ESSA É A VARIÁVEL QUE O DEPLOY.SH PRECISA:
variable "github_token" {
  type      = string
  sensitive = true
}

variable "flavor" {
  type    = string
  default = "full"
}