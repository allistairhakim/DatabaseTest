provider "google" {
  project = "project-training-425616"
  region  = "us-central1"
}

resource "random_password" "dbpass" {
  length  = 20
  upper   = true
  lower   = true
  special = false
}

resource "random_id" "name_suffix" {
  byte_length = 4
}

variable "docker-image" {
    type = string
}

resource "google_sql_database_instance" "default" {
  name             = "test-instance-${random_id.name_suffix.hex}"
  database_version = "MYSQL_5_7"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "default" {
  name     = "test-database-${random_id.name_suffix.hex}"
  instance = google_sql_database_instance.default.name
}

resource "google_sql_user" "users" {
  project  = "project-training-425616"
  name     = "admin"
  instance = google_sql_database_instance.default.name
  host     = "%"
  password = random_password.dbpass.result
}

resource "local_file" "docker_compose_env" {
  filename = "docker-compose.yml"
  content  = <<-EOT
version: '3.1'
services:
  web:
    build: ${var.docker-image}
    ports:
      - "80:80"
    environment:
      DBHOST: ${google_sql_database_instance.default.connection_name}
      DBPASS: ${random_password.dbpass.result}
      DBNAME: ${google_sql_database.default.name}
EOT
}

resource "null_resource" "update_docker_compose" {
  triggers = {
    docker_compose_content = local_file.docker_compose_env.content
  }

  provisioner "local-exec" {
    command = "mv ${local_file.docker_compose_env.filename} >> docker-compose.yml"
  }
}
