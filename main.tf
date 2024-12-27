# Reference the existing resource group
resource "azurerm_resource_group" "rg" {
  name = "ACCIPIENSTEST-UK-AZCLD-S-DEWEU-RG-001-VWFS-RGP"
  location = "Germany West Central"
}

data "azurerm_resource_group" "vnet_rg" {
  name = "platform-connectivity-s-gwc-001-vwfs-rgp"
}

# Data block to fetch an existing virtual network from another resource group
data "azurerm_virtual_network" "existing_vnet" {
  name                = "accipiens-spoke-s-gwc-001-vwfs-vnt"
  resource_group_name = data.azurerm_resource_group.vnet_rg.name
}
# Data block to fetch an existing subnet from another resource group
data "azurerm_subnet" "subnet" {
  name                 = "fe-subnet"
  resource_group_name  = data.azurerm_resource_group.vnet_rg.name
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
}

resource "azurerm_network_security_group" "nsg" {
  name                = "ACPTIDEWEUS2101-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface" "nic" {
  name                = "ACPTIDEWEUS2101-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_virtual_machine" "machine_fe" {
  name                  = "ACPTIDEWEUS210"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_F2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "ACPTIDEWEUS210"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_managed_disk" "example" {
  name                 = "ACPTIDEWEUS210-datadisk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  managed_disk_id    = azurerm_managed_disk.example.id
  virtual_machine_id = azurerm_virtual_machine.machine_fe.id
  lun                = "10"
  caching            = "ReadWrite"
}