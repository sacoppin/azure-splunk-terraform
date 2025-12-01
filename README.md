# ☁️ Azure Splunk Lab Deployment (Terraform IaC)

This repository contains the Infrastructure as Code (IaC) necessary to deploy a fully functional Splunk Enterprise Single-Instance lab environment on Azure using Terraform.

---

## 🎯 Purpose and Architecture

This deployment serves as a secure sandbox for **SOC Analyst training**, enabling the rapid creation of a dedicated SIEM environment for developing custom **Threat Detection rules (SPL)** and testing **Log Ingestion pipelines**.

The infrastructure includes:
1.  **Azure Resources:** Resource Group, VNet, Subnet, Public IP.
2.  **Security:** Network Security Group (NSG) configured to only allow SSH (Port 22) and Splunk GUI (Port 8000) access from a specified IP address.
3.  **VM:** Ubuntu LTS VM (used for its stability and common use in production).
4.  **Automation:** Installs Splunk Enterprise via a Custom Script Extension and starts the service automatically upon deployment.

## 🛠️ Deployment Instructions

### Prerequisites

1.  **Azure CLI:** Must be installed and authenticated (`az login`).
2.  **Terraform:** Must be installed (`brew install terraform`).
3.  **Splunk Download Link:** A direct download URL for the Splunk Enterprise Linux `.deb` package.

### Configuration

Before running, replace the placeholders in the `main.tf` file:
* `YOUR_PUBLIC_IP/32` (Required for NSG security).
* `VOTRE_LIEN_DE_TÉLÉCHARGEMENT_SPLUNK` (Direct URL to the `.deb` file).

### Execution

Run the following commands in the root directory:

```bash
terraform init
terraform plan -var='vm_password=YOUR_VM_PASS' -var='splunk_admin_password=YOUR_SPLUNK_PASS'
terraform apply -var='vm_password=YOUR_VM_PASS' -var='splunk_admin_password=YOUR_SPLUNK_PASS'