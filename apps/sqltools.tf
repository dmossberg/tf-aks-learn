resource "kubernetes_namespace" "sql-tools" {
  metadata {
    name = "sql-tools"
  }

  depends_on = [
    data.azurerm_kubernetes_cluster.aks
  ]
}

# Deploy pod for SQL Tools
resource "kubernetes_pod" "sql-tools" {
  metadata {
    name      = "sql-tools"
    namespace = kubernetes_namespace.sql-tools.metadata[0].name
  }

  spec {
    container {
      image   = "mcr.microsoft.com/mssql-tools"
      name    = "sql-tools"
      command = ["/bin/bash", "-c", "--"]
      args    = ["while true; do sleep 30; done;"]
    }
  }
}
