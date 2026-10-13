# Automated Web Infrastructure on Azure (Terraform + Ansible)

This project provisions a base network architecture and a server in Microsoft Azure using Terraform (Infrastructure as Code), and subsequently configures it automatically as a web server using Ansible (Configuration Management).

## Deployed Architecture 

The code deploys the following resources in the 'Spain Central' region:
* **Dedicated Resource Group** for the project.
* **Virtual Network (VNet)** segmented into two subnets:
  * `snet-app`: Oriented towards the public application.
  * `snet-db`: Isolated subnet for future database implementations.
* **Network Security Group (NSG)** with strict rules attached to the network interface (allowing inbound traffic on ports 22, 80, and 443).
* **Static Public IP** and a **Network Interface (NIC)**.
* **Linux Virtual Machine** (Ubuntu 22.04 LTS) optimized
## Directory Structure
```text
The project separates the physical infrastructure layer from the logical software layer:
terraform-azure/
├── Variables/
│   ├── 01-configuracion-server.yml  # Playbook de Ansible que instala Nginx
│   └── index.html                   # Archivo estático inyectado en el servidor
├── main.tf                          # Declaración de recursos y disparador de Ansible
├── outputs.tf                       # Salidas dinámicas (IP Pública y comando SSH)
├── providers.tf                     # Configuración del proveedor AzureRM
├── .gitignore                       # Protección de archivos de estado y secretos
└── README.md                        # Documentación del proyecto
