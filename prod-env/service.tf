resource "kubernetes_service" "product_service" {
  metadata {
    name      = "product-service"
    namespace = "default"
    labels = {
      app = "product-service"
    }
  }

  spec {
    selector = {
      app = "product-service"
    }

    port {
      port        = 5001
      target_port = 5001
    }

    type = "ClusterIP"
  }
}