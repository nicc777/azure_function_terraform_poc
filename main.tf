resource "azurerm_resource_group" "rg" {
  name     = "nico-sandbox-001"
  location = var.location
}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/functions"
  output_path = "${path.module}/functions.zip"
}

resource "azurerm_storage_account" "storage_account_function" {
  name                     = "st${var.owner}${var.project_name}fn"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  tags                     = var.tags
}

resource "azurerm_storage_container" "storage_container_function" {
  name                 = "function-releases"
  storage_account_name = azurerm_storage_account.storage_account_function.name
}

resource "azurerm_storage_blob" "storage_blob_function" {
  name                   = "functions-${substr(data.archive_file.function.output_md5, 0, 6)}.zip"
  storage_account_name   = azurerm_storage_account.storage_account_function.name
  storage_container_name = azurerm_storage_container.storage_container_function.name
  type                   = "Block"
  content_md5            = data.archive_file.function.output_md5
  source                 = "${path.module}/functions.zip"
}

resource "azurerm_eventhub_namespace" "main" {
  location            = var.location
  name                = "eh-${var.owner}-${var.project_name}-datadog"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = 1
  tags                = var.tags
}
resource "azurerm_eventhub" "main" {
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.rg.name
  name                = "events"
  message_retention   = 1
  partition_count     = 2
}
resource "azurerm_eventhub_consumer_group" "fa" {
  eventhub_name       = azurerm_eventhub.main.name
  name                = "fa"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_application_insights" "app-insights" {
  application_type    = "web"
  location            = var.location
  name                = "app-${var.owner}-${var.project_name}"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_app_service_plan" "example" {
  name                = "azure-functions-test-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "B1"
  }
}

resource "azurerm_function_app" "function-app" {
  name                       = "fa-${var.owner}-${var.project_name}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.example.id
  storage_account_name       = azurerm_storage_account.storage_account_function.name
  storage_account_access_key = azurerm_storage_account.storage_account_function.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  enable_builtin_logging     = false

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "EventHub_AccessKey"             = azurerm_eventhub_namespace.main.default_primary_connection_string
    "WEBSITE_RUN_FROM_PACKAGE"       = azurerm_storage_blob.storage_blob_function.url
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app-insights.instrumentation_key
  }

  site_config {
    linux_fx_version = "python|3.11"
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                            = azurerm_storage_account.storage_account_function.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_function_app.function-app.identity.0.principal_id
  skip_service_principal_aad_check = true
}
