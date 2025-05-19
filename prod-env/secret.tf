resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "db-credentials"
    namespace = "default"
  }

  data = {
    POSTGRES_USER     = base64encode("adminopswat")
    POSTGRES_PASSWORD = base64encode("adminopswatpass")
  }

  type = "Opaque"
}