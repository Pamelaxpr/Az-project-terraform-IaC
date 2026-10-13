# Infraestructura Web Automatizada en Azure (Terraform + Ansible)

Este proyecto aprovisiona una arquitectura de red base y un servidor en Microsoft Azure mediante **Terraform** (Infraestructura como Código), y posteriormente lo configura de manera automática como servidor web utilizando **Ansible** (Gestión de Configuración).

## Arquitectura Desplegada

El código levanta los siguientes recursos en la región `Spain Central`:
* **Grupo de Recursos** dedicado para el proyecto.
* **Red Virtual (VNet)** segmentada en dos subredes:
  * `snet-app`: Orientada a la aplicación pública.
  * `snet-db`: Subred aislada para futuras implementaciones de bases de datos.
* **Grupo de Seguridad de Red (NSG)** con reglas estrictas vinculadas a la interfaz de red (apertura de puertos 22, 80 y 443).
* **IP Pública Estática** y una **Interfaz de Red (NIC)**.
* **Máquina Virtual Linux** (Ubuntu 22.04 LTS) optimizada para capa gratuita/estudiantes (`Standard_B1s`).

## Estructura del Directorio

El proyecto separa la capa de infraestructura física de la capa lógica de software