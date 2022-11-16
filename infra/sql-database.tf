resource "random_integer" "sql-unique-id" {
  min = 1000
  max = 9999
}

# Create the SQL Server 
resource "azurerm_mssql_server" "sample-sql-server" {
  name                          = "${var.sql_server_name}-${random_integer.sql-unique-id.id}" #NOTE: globally unique
  resource_group_name           = azurerm_resource_group.aks-rg.name
  location                      = azurerm_resource_group.aks-rg.location
  version                       = "12.0"
  connection_policy             = "Default"
  public_network_access_enabled = false

  tags = {
    environment = "Non-Prod"
  }

  azuread_administrator {
    login_username              = var.sql_admin_group_name
    object_id                   = var.sql_admin_group_object_id
    azuread_authentication_only = true
    tenant_id                   = var.tenant_id
  }
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