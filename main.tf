# 1. Grupo de Recursos
resource "azurerm_resource_group" "rg_horsebit_lab_tf" {
  name     = "rg-horsebit-lab-tf"
  location = "Spain Central"
}

# 2. Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-horsebit-lab"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_horsebit_lab_tf.location
  resource_group_name = azurerm_resource_group.rg_horsebit_lab_tf.name
}

# 3. Subred Pública (Para la Máquina Virtual)
resource "azurerm_subnet" "subnet_app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.rg_horsebit_lab_tf.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. Subred Privada (Aislada para la futura BBDD)
resource "azurerm_subnet" "subnet_db" {
  name                 = "snet-db"
  resource_group_name  = azurerm_resource_group.rg_horsebit_lab_tf.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 5. IP Pública
resource "azurerm_public_ip" "public_ip" {
  name                = "pip-horsebit-lab"
  location            = azurerm_resource_group.rg_horsebit_lab_tf.location
  resource_group_name = azurerm_resource_group.rg_horsebit_lab_tf.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 6. Interfaz de Red (VNIC)
resource "azurerm_network_interface" "nic" {
  name                = "nic-horsebit-vm"
  location            = azurerm_resource_group.rg_horsebit_lab_tf.location
  resource_group_name = azurerm_resource_group.rg_horsebit_lab_tf.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_app.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# 7. Máquina Virtual (Linux Ubuntu)
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-horsebit-app"
  resource_group_name = azurerm_resource_group.rg_horsebit_lab_tf.name
  location            = azurerm_resource_group.rg_horsebit_lab_tf.location
  size                = "Standard_D2s_v4" # Tamaño económico ideal para cuenta de estudiante
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # Autenticación segura mediante clave SSH
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
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

# 8. Grupo de Seguridad de Red (NSG) con reglas individuales
resource "azurerm_network_security_group" "nsg_app" {
  name                = "nsg-horsebit-app"
  location            = azurerm_resource_group.rg_horsebit_lab_tf.location
  resource_group_name = azurerm_resource_group.rg_horsebit_lab_tf.name

  # Regla 1: Permitir conexión de administración SSH (Puerto 22)
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # Idealmente, cambia el "*" por tu IP pública real (ej. "85.12.34.56")
    destination_address_prefix = "*"
  }

  # Regla 2: Permitir tráfico web no seguro HTTP (Puerto 80)
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*" # Abierto a todo internet
    destination_address_prefix = "*"
  }

  # Regla 3: Permitir tráfico web seguro HTTPS (Puerto 443)
  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*" # Abierto a todo internet
    destination_address_prefix = "*"
  }
}

# 9. Asociación del NSG a la Interfaz de Red (NIC)
resource "azurerm_network_interface_security_group_association" "nsg_nic_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg_app.id
}

# 10. Disparador de Ansible
resource "null_resource" "ansible_provisioner" {
  depends_on = [azurerm_linux_virtual_machine.vm]

  triggers = {
    public_ip = azurerm_public_ip.public_ip.ip_address
  }

provisioner "local-exec" {
    command = <<-EOT
      sleep 30
      
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -u adminuser \
        --private-key ~/.ssh/id_rsa \
        -i '${azurerm_public_ip.public_ip.ip_address},' \
        Variables/01-configuracion-server.yml
    EOT
  }
}
