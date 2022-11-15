data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.acr_rg_name
}

resource "azurerm_role_assignment" "aks_to_acr" {
  # This role assignment is required to pull images from the ACR. All node pools share the same kubelet identity.
  # https://docs.microsoft.com/en-us/azure/aks/cluster-container-registry-integration#grant-aks-access-to-acr
  
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_kubernetes_cluster" "aks" {
  api_server_authorized_ip_ranges = ["${chomp(data.http.myip.response_body)}/32"]
  azure_policy_enabled            = true
  dns_prefix                      = "${var.aks_name}-dns"
  local_account_disabled          = true
  location                        = var.region
  name                            = var.aks_name
  resource_group_name             = azurerm_resource_group.aks-rg.name
  sku_tier                        = "Free"
  oidc_issuer_enabled             = true 
  workload_identity_enabled       = true
  automatic_channel_upgrade       = "patch"
  
  tags = {
    Environment = "Non-Prod"
  }
  
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = ["bcf60be2-0a6d-4dc1-912a-52d829bda22c"]
    managed                = true
    tenant_id              = "72f988bf-86f1-41af-91ab-2d7cd011db47"
  }

  network_profile {
    network_plugin     = "azure"
    load_balancer_sku  = "standard"
    network_policy     = "calico"
    outbound_type      = "loadBalancer"
  }

  default_node_pool {
    name           = "systempool"
    vm_size        = "Standard_B2ms"
    vnet_subnet_id = azurerm_subnet.aks-subnet.id
    pod_subnet_id = azurerm_subnet.aks-pod-subnet.id
    zones          = ["1", "2", "3"]
    enable_auto_scaling = false
    node_count = 1
  }

  identity {
    type = "SystemAssigned"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
    secret_rotation_interval = "2m"
  }

  oms_agent {
    log_analytics_workspace_id = "/subscriptions/f6b5c54e-aab5-4222-b073-9ddc407b66cb/resourceGroups/DefaultResourceGroup-WEU/providers/Microsoft.OperationalInsights/workspaces/aks-loganalytics"
  }

  depends_on = [
    azurerm_subnet.aks-subnet,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "user-pool" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  mode                  = "User"
  name                  = "userpool"
  vm_size               = "Standard_B2ms"
  vnet_subnet_id        = azurerm_subnet.aks-subnet.id
  pod_subnet_id         = azurerm_subnet.aks-pod-subnet.id 
  zones                 = ["1", "2", "3"]
  enable_auto_scaling = false
  node_count = 1
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_subnet.aks-subnet,
  ]
}