variable "project_id" {
  type = string
}

provider "google" {
  project = var.project_id
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
    ip_configuration {
      authorized_networks {
        name = "allow-all"
        value = "0.0.0.0/0"
      }
    }
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
    build: .
    ports:
      - "80:80"
    environment:
      DB_HOST: ${google_sql_database_instance.default.ip_address.0.ip_address}
      DB_PASS: ${random_password.dbpass.result}
      DB_NAME: ${google_sql_database.default.name}
    tty: true
EOT
}

resource "google_compute_firewall" "allow_mysql" {
  name    = "allow-mysql"
  network = "default"  # Replace with your network name if different from "default"

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]  # Replace with specific IP ranges for security if needed
}

# resource "null_resource" "update_docker_compose" {
#   triggers = {
#     docker_compose_content = local_file.docker_compose_env.content
#   }

#   provisioner "local-exec" {
#     command = "mv ${local_file.docker_compose_env.filename} docker-compose.yml"
#   }
# }
