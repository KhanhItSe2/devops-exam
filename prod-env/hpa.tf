resource "kubernetes_horizontal_pod_autoscaler_v2" "product_service_hpa" {
  metadata {
    name      = "product-service-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.product_service.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type               = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}