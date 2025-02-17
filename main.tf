terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

resource "azurerm_resource_group" "iaas_group" {
  name     = "IaaS_group"
  location = "Poland Central"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "labwork1-vnet"
  location            = azurerm_resource_group.iaas_group.location
  resource_group_name = azurerm_resource_group.iaas_group.name
  address_space       = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "IaaS_subnet"
  resource_group_name  = azurerm_resource_group.iaas_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "labwork1-ip"
  location            = azurerm_resource_group.iaas_group.location
  resource_group_name = azurerm_resource_group.iaas_group.name
  allocation_method   = "Static"
  domain_name_label   = "labwork1"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "labwork1-nsg"
  location            = azurerm_resource_group.iaas_group.location
  resource_group_name = azurerm_resource_group.iaas_group.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "labwork1916_z1"
  location            = azurerm_resource_group.iaas_group.location
  resource_group_name = azurerm_resource_group.iaas_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "labwork1"
  resource_group_name   = azurerm_resource_group.iaas_group.name
  location              = azurerm_resource_group.iaas_group.location
  size                  = "Standard_B1s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/keys/labwork1_key.pub")
  }

  tags = {
    ENV = "IaaS"
  }
}
