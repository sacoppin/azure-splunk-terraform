# Configure le fournisseur Azure
provider "azurerm" {
  features {}
}

# --- 1. Networking ---
resource "azurerm_resource_group" "rg" {
  name     = "rg-splunk-lab"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-splunk-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-splunk-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# --- 2. Security Group (NSG) ---
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-splunk-access"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# RULE port SSH (22)
resource "azurerm_network_security_rule" "ssh_rule" {
  name                        = "SSH_Allow"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# RULE port Splunk GUI (8000)
resource "azurerm_network_security_rule" "splunk_gui_rule" {
  name                        = "Splunk_GUI_Allow"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8000"
  source_address_prefix       = "YOUR_PUBLIC_IP/32" # <-- REMPLACEZ VOTRE IP ICI
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

# --- 3. Public IP & NIC ---
resource "azurerm_public_ip" "pip" {
  name                = "pip-splunk-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-splunk-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# --- 4. Virtual Machine (VM) ---
resource "azurerm_linux_virtual_machine" "splunk_vm" {
  name                            = "vm-splunk-lab"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B2s" 
  admin_username                  = "splunkadmin"
  network_interface_ids           = [azurerm_network_interface.nic.id]
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  admin_password = var.vm_password
}

# SCRIPT install splunk
resource "azurerm_virtual_machine_extension" "splunk_install" {
  name                       = "splunk-install-script"
  virtual_machine_id         = azurerm_linux_virtual_machine.splunk_vm.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.0"
  depends_on                 = [azurerm_linux_virtual_machine.splunk_vm]
  
  # Le script télécharge, installe, ouvre le port UFW et démarre Splunk 
  settings = <<SETTINGS
    {
      "commandToExecute": "wget -O splunk.deb 'VOTRE_LIEN_DE_TÉLÉCHARGEMENT_SPLUNK' && \
                           sudo dpkg -i splunk.deb && \
                           sudo ufw allow 8000/tcp && \
                           sudo /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd '${var.splunk_admin_password}' && \
                           sudo /opt/splunk/bin/splunk enable boot-start"
    }
  SETTINGS
}
