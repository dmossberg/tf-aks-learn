resource "azapi_resource" "flux_addon" {
  type       = "Microsoft.KubernetesConfiguration/extensions@2022-03-01"
  name       = "flux"
  parent_id  = azurerm_kubernetes_cluster.aks.id
  locks      = [azurerm_kubernetes_cluster.aks.id]
  body = jsonencode({
    properties = {
      extensionType           = "microsoft.flux"
      autoUpgradeMinorVersion = true
    }
  })

  timeouts {
    create = "20m"
  }
}

resource "azapi_resource" "flux_config" {
  type      = "Microsoft.KubernetesConfiguration/fluxConfigurations@2022-03-01"
  name      = "cluster-config"
  parent_id = azurerm_kubernetes_cluster.aks.id

  depends_on = [
    azapi_resource.flux_addon
  ]

  body = jsonencode({
    properties = {
      scope      = "cluster"
      namespace  = "flux-system"
      sourceKind = "GitRepository"
      suspend    = false
      gitRepository = {
        url                   = local.gitops_repo_url
        timeoutInSeconds      = 120
        syncIntervalInSeconds = 120
        repositoryRef = {
          branch = var.gitOpsSettings.branchName
        }
        httpsUser = var.gitOpsSettings.httpsUser
      }
      configurationProtectedSettings = {
        httpsKey = sensitive(base64encode(var.gitOpsSettings.httpsPassword))
      }
      kustomizations = {
        shared = {
          path                   = "cluster-config/shared"
          timeoutInSeconds       = 600
          syncIntervalInSeconds  = 60
          retryIntervalInSeconds = 60
          prune                  = false
          force                  = false
        }
        applications = {
          path                   = "cluster-config/applications"
          dependsOn              = ["shared"]
          timeoutInSeconds       = 600
          syncIntervalInSeconds  = 60
          retryIntervalInSeconds = 60
          prune                  = false
          force                  = false
        }
      }
    }
  })
}