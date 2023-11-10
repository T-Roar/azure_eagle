# Create Resource Group

resource "azurerm_resource_group" "logging" {
  name     = "logging-resource-group"
  location = "eastus"
}

resource "azurerm_automation_account" "log_cleaning_acc" {
  name                = "logcleaningacc"
  location            = azurerm_resource_group.logging.location
  resource_group_name = azurerm_resource_group.logging.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }
}



#  Set up Access

resource "azurerm_role_assignment" "acc_sys" {
  scope                = azurerm_resource_group.logging.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_automation_account.log_cleaning_acc.identity[0].principal_id
}

# Azure Automation Runbook

data "local_file" "log_cleaning_runbk" {
  filename = "${path.module}/scripts/LogCleanupRunbook.ps1"
}

data "azurerm_client_config" "client" {
  
}
resource "azurerm_automation_schedule" "log_cleanup_schedule" {
  name = "log-cleanup-schedule"
  resource_group_name = azurerm_resource_group.logging.name
  automation_account_name = azurerm_automation_account.log_cleaning_acc.name
  frequency = "Week"
  interval = 7
#   start_time = "23:45"
   description = "Schedule to cleanup log each week"
}

resource "azurerm_automation_job_schedule" "ajs" {
  resource_group_name = azurerm_resource_group.logging.name
  automation_account_name       = azurerm_automation_account.log_cleaning_acc.name
  schedule_name      = azurerm_automation_schedule.log_cleanup_schedule.name
  runbook_name        = azurerm_automation_runbook.log_cleaning_runbk.name

  parameters = {
    subscriptionid          = data.azurerm_client_config.client.subscription_id
    storagecontainername    = azurerm_storage_container.log.name
    storagecredentialsname  = azurerm_automation_credential.log_storage_credentials.name
  }
}



resource "azurerm_automation_runbook" "log_cleaning_runbk" {
  name                    = "log-cleaning-runbk"
  location                = azurerm_resource_group.logging.location
  resource_group_name     = azurerm_resource_group.logging.name
  automation_account_name = azurerm_automation_account.log_cleaning_acc.name
  log_verbose             = true
  log_progress            = true
  description             = "This runbook is used to clean up logs from the VMs in a subscription."
  runbook_type            = "PowerShellWorkflow"

  content = data.local_file.log_cleaning_runbk.content
}

# Storage Credentials

resource "azurerm_automation_credential" "log_storage_credentials" {
  name                    = "log-storage-credentials"
  resource_group_name     = azurerm_resource_group.logging.name
  automation_account_name = azurerm_automation_account.log_cleaning_acc.name
  username                = azurerm_storage_account.log_storage.name
  password                = azurerm_storage_account.log_storage.primary_access_key
}

resource "azurerm_storage_container" "log" {
    name                  = "log"
    storage_account_name  = azurerm_storage_account.log_storage.name
    container_access_type = "private"
}

resource "azurerm_storage_account" "log_storage" {
  name                     = "logstorage24"
  resource_group_name      = azurerm_resource_group.logging.name
  location                 = azurerm_resource_group.logging.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = false
}


