provider "google" {
  project = "YOUR_PROJECT_ID"
  region  = "YOUR_REGION"
}

resource "google_sql_database_instance" "default" {
  name             = "example-instance"
  database_version = "MYSQL_5_7"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "default" {
  name     = "example-database"
  instance = google_sql_database_instance.default.name
}

resource "google_sql_user" "default" {
  name     = "example-user"
  instance = google_sql_database_instance.default.name
  password = "example-password"
}
