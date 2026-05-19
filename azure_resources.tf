resource "azurerm_resource_group" "rg" {
  name     = "workshop-rg"
  location = "westeurope"
}

# Azure Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "workshopstorage999"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = true

  https_traffic_only_enabled = false

  public_network_access_enabled = false

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }

  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }

  shared_access_key_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = ["127.0.0.1"]
  }
}

# Azure Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "workshop-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  size = var.azure_vm_size

  admin_username = "johndoe"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-noble"
    sku       = "24_04-lts"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "johndoe"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8ZWuXrDWHGm1rf2fUURD7+tUGE9e8rQccOLUG1lD9R dummy@key"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/dummy/providers/Microsoft.Network/virtualNetworks/dummy/subnets/dummy"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_rule" "sr" {
  name                        = "allow-ssh"
  network_security_group_name = "workshop-nsg"
  resource_group_name         = azurerm_resource_group.rg.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"

  source_address_prefix      = "*"
  destination_address_prefix = "*"
}