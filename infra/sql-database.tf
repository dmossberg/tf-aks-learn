resource "random_integer" "sql-unique-id" {
  min = 1000
  max = 9999
}

resource "random_password" "sql-admin-password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_string" "sql-admin-username" {
  length  = 16
  special = false
}

# User: 8DICgG1OHqqu9b1D
output db_user {
  value     = random_string.sql-admin-username.result
  sensitive = false
}

# Pwd: HJE0WWYp@ytKG0eD
output db_passsword {
  value     = random_password.sql-admin-password.result
  sensitive = true
}

# Create the SQL Server 
resource "azurerm_mssql_server" "sample-sql-server" {
  name                          = "${var.sql_server_name}-${random_integer.sql-unique-id.id}" #NOTE: globally unique
  resource_group_name           = azurerm_resource_group.aks-rg.name
  location                      = azurerm_resource_group.aks-rg.location
  version                       = "12.0"
  connection_policy             = "Default"
  administrator_login           = random_string.sql-admin-username.result
  administrator_login_password  = random_password.sql-admin-password.result
  public_network_access_enabled = true # this is changed after the SQL Server is configured with the managed identity: az sql server update --enable-public-network false 

  tags = {
    environment = "Non-Prod"
  }

  azuread_administrator {
    login_username              = var.sql_admin_group_name
    object_id                   = var.sql_admin_group_object_id
    azuread_authentication_only = false # this is changed after the SQL Server is configured with the managed identity: az sql server ad-only-auth enable
    tenant_id                   = var.tenant_id
  }
}

resource "azurerm_mssql_firewall_rule" "deployment-ip" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.sample-sql-server.id
  start_ip_address = chomp(data.http.myip.response_body)
  end_ip_address   = chomp(data.http.myip.response_body)
}

# Create a the SQL database 
resource "azurerm_mssql_database" "sample-sql-db" {
  name      = "northwind-db"
  server_id = azurerm_mssql_server.sample-sql-server.id
  sku_name  = "S0"
}

# Create a private endpoint to allow access to the SQL Server from the AKS subnet
resource "azurerm_private_endpoint" "sql-private-endpoint" {
  name                = "sql-private-endpoint"
  location            = azurerm_resource_group.aks-rg.location
  resource_group_name = azurerm_resource_group.aks-rg.name
  subnet_id           = azurerm_subnet.private-link-subnet.id

  private_service_connection {
    name                           = "sql-private-endpoint"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.sample-sql-server.id
    subresource_names              = ["sqlServer"]
  }
}

# Create a private DNS A Record for the SQL Server
resource "azurerm_private_dns_a_record" "sql-private-dns" {
  name                = lower(azurerm_mssql_server.sample-sql-server.name)
  zone_name           = azurerm_private_dns_zone.database-private-dns.name
  resource_group_name = azurerm_resource_group.aks-rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql-private-endpoint.private_service_connection[0].private_ip_address]
}

locals {
  sql_server_fqdn       = "${azurerm_private_dns_a_record.sql-private-dns.name}.database.windows.net"
  sql_server_db         = azurerm_mssql_database.sample-sql-db.name
  managed_identity_name = "aks-workload-identity"
}

resource "azurerm_user_assigned_identity" "app_managed_identity" {
  name                = local.managed_identity_name
  resource_group_name = var.aks_rg_name
  location            = var.region

  # ./scripts/create-db-user.sh mssql-server-5728.database.windows.net 14bfade6-7c80-49d8-849f-1b16c4a0ecef northwind-db

  provisioner "local-exec" {
    command     = "./scripts/create-db-user.sh ${local.sql_server_fqdn} ${local.managed_identity_name} ${local.sql_server_db} ${random_string.sql-admin-username.result} ${random_password.sql-admin-password.result}"
    working_dir = path.module
    when        = create
  }

  # provisioner "local-exec-2" {
  #   command    = ""
  #   depends_on = [provisioner.local-exec]
  # }

  depends_on = [
    azurerm_mssql_database.sample-sql-db,
    azurerm_mssql_firewall_rule.deployment-ip
  ]
}
