resource "kubernetes_namespace" "ingress-basic" {
  metadata {
    name = "ingress-basic"
  }

  depends_on = [
    data.azurerm_kubernetes_cluster.aks
  ]
}

# $ kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.12/examples/minikube/http-sw-app.yaml

# Deploy Helm chart for NGINX Ingress Controller
resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  # version    = "4.4.0"
  namespace  = kubernetes_namespace.ingress-basic.metadata[0].name

  set {
    name  = "controller.replicaCount"
    value = "2"
  }

  set {
    name  = "controller.nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }

  set {
    name  = "defaultBackend.enabled"
    value = "true"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-dns-label-name"
    value = "nginx-ingress"
  }

  # set {
  #   name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
  #   value = "true"
  # }

  # set {
  #   name  = "controller.service.externalTrafficPolicy"
  #   value = "Local"
  # }

  # set {
  #   name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal-subnet"
  #   value = var.aks_subnet_name
  # }

  # set {
  #   name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
  #   value = var.aks_rg_name
  # }
}