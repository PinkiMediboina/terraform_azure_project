terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-demo"
  location = "Central India"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-demo"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-demo"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "pip-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "nic-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Attach NSG to NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-demo"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2ms"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

 admin_ssh_key {
  username   = "azureuser"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpudMQ+nfvDpuqaBP34MrstvA3BN5zZLPqgBIdu7DmHkfXtJaYDywUyTs6dtqstiDg4XKVqVtRR9xB4/GdntNlEWOri8EPcPDv9oaOY7AxxaT4MDNuWaBzwHH/FMwb4L2ZQ0VBcM+JDZaKMLuEFGBf/qjVY9C5uzOFa8MdzWSkG0RD1fTun5Mj+mdZis6aD5W5jktKbQPrGstK014lG9NRPHQ6Y+z5lZkriGerzqIcye0t5FUn6YmzPLhmB/QWJtpeeSEuMcNyx56zepDd/x3Q21zWiSMfFHEwuJzIZk7K5DuxBbw7Z1X+VyOAgptlT0X1RtOwc0hFZr+gwjKe0iPOSAG7bIcpMv2lW9eoH1OJiP54qRiz/1BizIstLlTJDI97YGRVC99qDb4MZv5jTur9bdgcm88E+6XPKIxU9G67HxU29pwQHikmim7EZnRddo6uhPHtpHA/1vQCaiKbzHyZEOJmBg+2wkMnSiMip5imym43dsoiOmewXQVhTSaK48BPcEjlIkQIAbGWouHOMy7/G8t2RBpvZiFDrawU3VhR33/D9JaisPOvwGD37v+qJ4XVy96+5Eru1H4tX+lFDTrDbw2kwiascCOITNXkdK+fJiL+8Al40LI6PqytPGLqJE0tFzkP7Rvm0A4GnLt+5UvLBc8xYnXWVz/XDMMIvSBdyQ== azureuser"
}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"   
    version   = "latest"
  }
}