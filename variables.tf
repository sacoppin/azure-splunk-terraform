variable "vm_password" {
  description = "Le mot de passe pour l'utilisateur Linux 'splunkadmin' de la VM."
  type        = string
  sensitive   = true
}

variable "splunk_admin_password" {
  description = "Le mot de passe pour l'utilisateur Splunk 'admin'."
  type        = string
  sensitive   = true
}
