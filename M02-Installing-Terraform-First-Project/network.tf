resource "azurerm_virtual_network" "main" {
  name                = "vnet-terraform-lab"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  address_space = ["10.10.0.0/16"]

  tags = {
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}



resource "azurerm_subnet" "main" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = ["10.10.1.0/24"]
}


resource "azurerm_network_security_group" "vm" {
  name                = "nsg-terraform-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_public_ip" "vm" {
  name                = "pip-terraform-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = {
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-terraform-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = {
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id

}