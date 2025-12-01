output "public_ip_address" {
  description = "L'adresse IP publique de la VM Splunk."
  value       = azurerm_public_ip.pip.ip_address
}

output "splunk_gui_url" {
  description = "L'URL d'accès au GUI de Splunk (Port 8000)."
  value       = "http://${azurerm_public_ip.pip.ip_address}:8000"
}