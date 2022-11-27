resource "kubernetes_namespace" "inspector-gadget" {
  metadata {
    name = "inspector-gadget"
  }

  depends_on = [
    data.azurerm_kubernetes_cluster.aks
  ]
}

resource "kubernetes_deployment" "inspector-gadget" {
  metadata {
    name      = "inspector-gadget"
    namespace = kubernetes_namespace.inspector-gadget.metadata[0].name
    labels = {
      version = "latest"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "inspector-gadget"
      }
    }

    template {
      metadata {
        labels = {
          app = "inspector-gadget"
        }
      }

      spec {
        container {
          image = "jelledruyts/inspectorgadget:latest"
          name  = "inspectorgadget"
          port {
            container_port = 80
          }

          env {
            name  = "PathBase"
            value = "/inspector-gadget"
          }
            
          resources {
            limits = {
              cpu    = "0.5"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "inspector-gadget" {
  metadata {
    name      = "inspector-gadget"
    namespace = kubernetes_namespace.inspector-gadget.metadata[0].name
  }
  spec {
    selector = {
      app = "inspector-gadget"
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# ingress class
resource "kubernetes_ingress_v1" "inspector-gadget" {
  metadata {
    name      = "inspector-gadget"
    namespace = kubernetes_namespace.inspector-gadget.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect" : "false"
      "nginx.ingress.kubernetes.io/use-regex" : "true"
      "nginx.ingress.kubernetes.io/rewrite-target" : "/$2"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path = "/inspector-gadget(/|$)(.*)"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.inspector-gadget.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
