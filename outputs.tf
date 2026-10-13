
output "ip_publica_vm" {
  description = "Dirección IP pública para conectarte a la máquina virtual"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "ip_privada_vm" {
  description = "Dirección IP privada de la máquina dentro de la subred snet-app"
  value       = azurerm_network_interface.nic.private_ip_address
}

output "comando_ssh" {
  description = "Comando rápido para conectarte por SSH a tu servidor"
  value       = "ssh adminuser@${azurerm_public_ip.public_ip.ip_address}"
}