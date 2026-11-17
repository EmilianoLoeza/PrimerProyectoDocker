# Tarea 3 - Infraestructura en AWS con Terraform

## Descripción del proyecto

En esta actividad desarrollé una infraestructura en AWS utilizando Terraform, con el objetivo de automatizar la creación de diferentes servicios en la nube y desplegar una aplicación web desarrollada con Node.js y Express.

El proyecto incluye una VPC con subredes públicas y privadas, un NAT Gateway, una instancia EC2 con Nginx, un repositorio Amazon ECR, un servicio ECS Fargate y una base de datos MySQL en Amazon RDS.

También implementé un pipeline mediante GitHub Actions que permite construir la imagen Docker de la aplicación, publicarla automáticamente en Amazon ECR y actualizar el servicio ECS Fargate.

Para organizar el proyecto dividí los archivos en dos carpetas principales. En `iac` se encuentra toda la configuración de Terraform, mientras que en `app` se encuentra el código fuente de la aplicación y los archivos necesarios para ejecutarla mediante Docker.

El pipeline se encuentra en `.github/workflows/main.yml`.

Durante el desarrollo comprobé que la infraestructura podía crearse correctamente mediante Terraform, que la aplicación funcionaba en ECS Fargate y que podía comunicarse con la base de datos MySQL. También se verificó el funcionamiento del despliegue automático utilizando GitHub Actions.

Finalmente, después de realizar las pruebas, eliminé los recursos creados en AWS para evitar mantener servicios innecesarios activos.

Las instrucciones completas para ejecutar la aplicación y desplegar la infraestructura se encuentran en los archivos README de las carpetas `app` e `iac`.