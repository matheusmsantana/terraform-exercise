
resource "azurerm_public_ip" "azure_public_ip" {
  name                = "publicip"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "network_interface" {
  name                = "nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nicnsg" {
  network_interface_id      = azurerm_network_interface.network_interface.id
  network_security_group_id = azurerm_network_security_group.network_security_group.id
}


resource "azurerm_storage_account" "storage_db01" {
    name                        = "db0000001"
    resource_group_name         = azurerm_resource_group.resource_group.name
    location                    = azurerm_resource_group.resource_group.location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    depends_on = [ azurerm_resource_group.resource_group ]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "virtual-machine"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = "Standard_DS1_v2"
  admin_username      = var.user-vm 
  admin_password      = var.password-user-vm
  disable_password_authentication = false
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage_db01.primary_blob_endpoint
  }
  network_interface_ids = [
    azurerm_network_interface.network_interface.id,
  ]

  os_disk {
    name                 = "myOsDBDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "time_sleep" "wait_30_seconds_db" {
  create_duration = "30s"
  depends_on = [azurerm_linux_virtual_machine.vm]
}

resource "null_resource" "upload_sql" {
  provisioner "file" {
    connection {
      type = "ssh"
      user = var.user-vm
      password = var.password-user-vm
      host = azurerm_public_ip.azure_public_ip.ip_address 
    }
    source = "mysql"
    destination = "/home/azureuser"

  }
  depends_on = [time_sleep.wait_30_seconds_db]
}

resource "null_resource" "install-database" {
  triggers = {
    order = null_resource.upload_sql.id
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      host = azurerm_public_ip.azure_public_ip.ip_address
      user = var.user-vm
      password = var.password-user-vm
    }

    script = "./bootstrap.sh"
  }
}

/*
output "publicip" {
  //Ip publico da maquina virtual
  value = azurerm_public_ip.azure_public_ip.ip_address
}*/