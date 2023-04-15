provider "azurerm" {
   features {}
}

data "azurerm_client_config" "current" {}

#Creat Resource Group APP-FSA 
resource "azurerm_resource_group" "argapp" {
  name     = "APP-FSA"
  location = "East US"
}

#Creat Resource Group Recursos COMMON-FSA
resource "azurerm_resource_group" "argcommon" {
name     = "COMMON-FSA" 
location = "East US"
}


#Creat Resources in the group APP-FSA 
#Creat Storage Account 
resource "azurerm_storage_account" "asafsa" {
    name                     = "funsocamigstorage"
    location                 = azurerm_resource_group.argapp.location
    resource_group_name      = azurerm_resource_group.argapp.name
    account_tier             = "Standard"
    account_replication_type = "LRS"
}

#Creat Key Vault 
resource "azurerm_key_vault" "akvfsa" {
  name                        = "fsa-keyvault"
  location                    = azurerm_resource_group.argapp.location
  resource_group_name         = azurerm_resource_group.argapp.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"
}

#Creat App Configuration 
resource "azurerm_app_configuration" "apcfsa" {
  name                = "fsa-app-config"
  location            = azurerm_resource_group.argapp.location
  resource_group_name = azurerm_resource_group.argapp.name
}


#Creat namespace EventHub
resource "azurerm_eventhub_namespace" "aenfsa" {
  name                = "fsa-namespae-eventhub"
  location            = azurerm_resource_group.argapp.location
  resource_group_name = azurerm_resource_group.argapp.name
  sku = "Basic"
}

#Creat EventHub
resource "azurerm_eventhub" "aehfsa" {
  name                = "fsa-eventhub"
  namespace_name      = azurerm_eventhub_namespace.aenfsa.name
  resource_group_name = azurerm_resource_group.argapp.name
  partition_count     = 2
  message_retention   = 1
}


#Creat  Resources in the group COMMON-FSA 
#Creat  AKS 
resource "azurerm_kubernetes_cluster" "cluster" {
name                = "fsa-kubed8sclusterfsa"
location            = azurerm_resource_group.argcommon.location
resource_group_name = azurerm_resource_group.argcommon.name
dns_prefix          = "fsa-kubed8sclusterfsa"

default_node_pool {
name       = "default"
node_count = "2"
vm_size    = "standard_d2_v2"
}

identity {
type = "SystemAssigned"
}
}

#Creat Virtual Network 
resource "azurerm_virtual_network" "avnfsa" {
  name                = "fsa-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.argcommon.location
  resource_group_name = azurerm_resource_group.argcommon.name

  subnet {
    name           = "subnet-fsa"
    address_prefix = "10.0.1.0/24"
  }
}

#Creat Server PostgreSQL
resource "azurerm_postgresql_server" "apsfsa" {
  name                = "fsa-postgresql-server"
  location            = azurerm_resource_group.argcommon.location
  resource_group_name = azurerm_resource_group.argcommon.name
  version             = "11"

  administrator_login          = "fsaadmin"
  administrator_login_password = "S1rl@.1998"

  sku_name   = "B_Gen5_1"
  storage_mb = 5120
  ssl_enforcement_enabled = true
}

#Creat DB PostgreSQL
resource "azurerm_postgresql_database" "apdbfsa" {
  name                = "fsa-postgresql-db"
  resource_group_name = azurerm_resource_group.argcommon.name
  server_name         = azurerm_postgresql_server.apsfsa.name
  charset             = "UTF8"
  collation           = "English_United States.1252"

}

#Creat Network Security Group
resource "azurerm_network_security_group" "ansgfsa" {
  name                = "fsa-nsg"
  location            = azurerm_resource_group.argcommon.location
  resource_group_name = azurerm_resource_group.argcommon.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#Creat Redis
resource "azurerm_redis_cache" "example" {
  name                = "fsa-redis"
  location            = azurerm_resource_group.argcommon.location
  resource_group_name = azurerm_resource_group.argcommon.name
  capacity            = 1
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  # Tags
  tags = {
    environment = "dev"
  }
}