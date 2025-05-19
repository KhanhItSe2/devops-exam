resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = "default"
  }

  data = {
    APP_NAME  = "coffeeshop"
    LOG_LEVEL = "info"
  }
}