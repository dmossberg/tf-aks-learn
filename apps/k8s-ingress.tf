data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  resource_group_name = var.aks_rg_name
}

data "azurerm_client_config" "current" {
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config.0.host
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--login",
      "azurecli", # spn if you want to use service principal, but requires use of env vars AAD_SERVICE_PRINCIPAL_CLIENT_ID and AAD_SERVICE_PRINCIPAL_CLIENT_SECRET
      "--environment",
      "AzurePublicCloud",
      "--tenant-id",
      data.azurerm_client_config.current.tenant_id,
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630",
      "|",
      "jq",
      ".status.token"
    ]
  }
}

resource "kubernetes_namespace" "nginx-basic" {
  metadata {
    name = "nginx-basic"
  }

  depends_on = [
    data.azurerm_kubernetes_cluster.aks
  ]
}
