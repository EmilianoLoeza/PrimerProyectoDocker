# Tarea 3 - Infraestructura en AWS con Terraform

## Descripción del proyecto

En esta actividad desarrollé una infraestructura en AWS utilizando Terraform, con el objetivo de automatizar la creación de diferentes servicios en la nube y utilizarlos para ejecutar una aplicación web.

El proyecto consiste en una aplicación desarrollada con Node.js y Express, la cual se ejecuta mediante Docker y se despliega en AWS utilizando ECS Fargate. También se configuró una máquina virtual EC2 con Nginx, una base de datos MySQL en Amazon RDS y los recursos de red necesarios para conectar los servicios.

Para organizar el proyecto separé los archivos en dos carpetas principales. La carpeta `iac` contiene la configuración de Terraform, mientras que `app` contiene el código fuente de la aplicación.

Ambas carpetas forman parte del mismo repositorio de GitHub, llamado PrimerProyectoDocker.

Además, implementé un pipeline con GitHub Actions para automatizar la construcción de la imagen Docker, su publicación en Amazon ECR y la actualización del servicio ECS Fargate.

## Servicios de AWS utilizados

Para comenzar, creé una VPC que funciona como la red principal de la infraestructura. Esta cuenta con dos subredes públicas y dos privadas, lo que permite separar los servicios que necesitan recibir conexiones desde Internet de aquellos que deben mantenerse dentro de la red.

También se configuraron un Internet Gateway y un NAT Gateway. El primero permite la comunicación de los recursos públicos con Internet, mientras que el segundo proporciona acceso de salida a los recursos ubicados en las subredes privadas.

Otro de los servicios utilizados fue Amazon EC2. Se creó una instancia con Amazon Linux 2023 que instala e inicia automáticamente Nginx. Su función es mostrar una página web de prueba para comprobar que el servidor está funcionando.

Para almacenar las imágenes Docker utilicé Amazon ECR. Este servicio permite guardar las imágenes de la aplicación y ponerlas a disposición de ECS Fargate.

Amazon ECS con Fargate se encarga de ejecutar la aplicación dentro de un contenedor, sin necesidad de administrar directamente el servidor donde se encuentra alojada.

También se implementó un Application Load Balancer, encargado de recibir las solicitudes HTTP y dirigirlas hacia la aplicación ejecutada en ECS.

Finalmente, se creó una base de datos MySQL mediante Amazon RDS. La base de datos se encuentra dentro de subredes privadas y sus conexiones están controladas mediante grupos de seguridad.

Las credenciales de la base de datos se administran utilizando AWS Secrets Manager, evitando escribir directamente las contraseñas dentro del código.

## Organización de los archivos

Los archivos de Terraform se encuentran separados dependiendo del servicio que configuran.

El archivo `main.tf` contiene la configuración general de Terraform y del proveedor de AWS.

En `variables.tf` se encuentran las variables que permiten personalizar la región, el nombre del proyecto y el nombre de la base de datos.

El archivo `vpc.tf` configura la red principal, las subredes, las rutas, el Internet Gateway y el NAT Gateway.

En `security_groups.tf` se encuentran las reglas que controlan las conexiones permitidas entre los diferentes recursos.

El archivo `ec2.tf` crea la máquina virtual e instala Nginx automáticamente.

En `ecr.tf` se configura el repositorio donde se almacenan las imágenes Docker.

El archivo `ecs.tf` contiene la configuración del clúster, las tareas y el servicio de ECS Fargate.

En `rds.tf` se configura la base de datos MySQL.

El archivo `alb.tf` crea el balanceador de carga que permite acceder a la aplicación.

En `github_oidc.tf` se configura la autenticación entre GitHub Actions y AWS mediante OIDC, incluyendo el rol IAM y los permisos necesarios.

Finalmente, `outputs.tf` permite consultar información de los servicios después de ejecutar Terraform, como las direcciones públicas de EC2 y ECS, el repositorio ECR y el endpoint de RDS.

Esta organización facilita la identificación de los archivos y permite modificar cada servicio de manera independiente.

## Variables del proyecto

El proyecto utiliza tres variables principales, definidas en `variables.tf`.

La variable `aws_region` establece la región donde se crearán los recursos. Para esta actividad se utilizó `us-east-2`, correspondiente a Ohio.

La variable `project_name` permite definir el nombre general que se utilizará para identificar los recursos. Su valor predeterminado es `primerproyectodocker`.

La variable `database_name` establece el nombre de la base de datos MySQL y tiene como valor predeterminado `appdb`.

Todas estas variables cuentan con valores predeterminados, por lo que no es necesario introducirlas manualmente para ejecutar Terraform.

Si se desean utilizar valores diferentes, pueden modificarse desde el archivo de variables o mediante un archivo local `terraform.tfvars`.

En caso de cambiar el nombre del proyecto o la región, también será necesario actualizar los valores correspondientes dentro del pipeline de GitHub Actions.

No se deben publicar contraseñas, archivos de estado de Terraform ni credenciales de AWS dentro del repositorio.

## Requisitos para ejecutar el proyecto

Para utilizar este proyecto es necesario contar con una cuenta de AWS con permisos suficientes para crear y administrar los servicios utilizados.

También es necesario tener instalados Terraform, AWS CLI, Git y Docker Desktop.

Durante el desarrollo utilicé Terraform 1.16.6 y AWS CLI para administrar la infraestructura desde VS Code.

Para realizar las pruebas configuré un usuario de IAM llamado `tarea3-lab`, con autenticación multifactor y permisos temporales para administrar los recursos.

La conexión con AWS se realizó mediante un perfil de AWS CLI, sin utilizar directamente la cuenta raíz.

Para iniciar sesión con un perfil configurado se puede ejecutar:

```powershell
aws login --profile tarea3-lab
```

Después se selecciona el perfil que utilizará Terraform:

```powershell
$env:AWS_PROFILE = "tarea3-lab"
```

Para comprobar que la conexión funciona correctamente se utiliza:

```powershell
aws sts get-caller-identity --profile tarea3-lab
```

El nombre `tarea3-lab` corresponde al perfil utilizado durante esta actividad. Si otra persona ejecuta el proyecto, deberá configurar su propio usuario o perfil autorizado de AWS.

## Inicialización de Terraform

Para comenzar, se debe abrir una terminal dentro de la carpeta `iac`.

El primer paso consiste en inicializar Terraform:

```powershell
terraform init
```

Este comando prepara el directorio y descarga los proveedores necesarios.

Después se puede verificar que los archivos estén configurados correctamente:

```powershell
terraform validate
```

Para comprobar su formato se utiliza:

```powershell
terraform fmt -check
```

Finalmente, se ejecuta:

```powershell
terraform plan
```

Este último comando permite revisar qué recursos se crearán, modificarán o eliminarán.

Durante el desarrollo comprobé que la configuración era válida y que Terraform podía generar correctamente el plan de infraestructura.

Es importante mencionar que `terraform plan` no crea los recursos, solamente muestra las acciones previstas.

## Creación inicial de Amazon ECR

Para realizar el primer despliegue fue necesario crear el repositorio ECR antes que el servicio ECS.

Esto se debe a que ECS Fargate necesita encontrar una imagen Docker disponible para poder ejecutar la aplicación.

Por esta razón, primero se utilizó el siguiente comando:

```powershell
terraform apply '-target=aws_ecr_repository.app'
```

Con este comando se crea únicamente el repositorio ECR.

Después se puede consultar su dirección mediante:

```powershell
terraform output -raw ecr_repository_url
```

La opción `-target` se utilizó solamente para preparar los recursos iniciales. Para las actualizaciones habituales se recomienda ejecutar Terraform sobre toda la configuración.

## Configuración de GitHub Actions con AWS

Para que el pipeline pudiera conectarse con AWS implementé autenticación mediante OIDC.

Esta configuración se encuentra en el archivo `github_oidc.tf`.

El archivo crea un proveedor de identidad, un rol IAM y una política que permite a GitHub Actions publicar imágenes en ECR y actualizar ECS Fargate.

Para preparar estos recursos inicialmente se pueden utilizar los siguientes comandos:

```powershell
terraform apply '-target=aws_iam_openid_connect_provider.github' '-target=aws_iam_role.github_actions' '-target=aws_iam_role_policy.github_actions'
```

Después se consulta el ARN del rol creado:

```powershell
terraform output -raw github_actions_role_arn
```

Este ARN debe agregarse como variable del repositorio de GitHub.

Para hacerlo, se ingresa a `Settings`, después a `Secrets and variables`, se selecciona `Actions` y finalmente la pestaña `Variables`.

La variable debe llamarse:

`AWS_ROLE_ARN`

Su valor corresponde al ARN completo del rol generado por Terraform.

De esta forma, GitHub Actions puede utilizar credenciales temporales de AWS sin almacenar claves de acceso permanentes en el repositorio.

El archivo del pipeline se encuentra en la raíz del repositorio, en la ubicación:

`.github/workflows/main.yml`

## Publicación de la imagen Docker

Una vez creado ECR y configurada la autenticación, se debe publicar la primera imagen Docker.

Para esto se puede ejecutar el pipeline desde GitHub Actions.

El pipeline descarga el código, construye la imagen utilizando `app/Dockerfile` y la publica en ECR con dos etiquetas.

Una etiqueta corresponde al identificador del commit de GitHub y la otra utiliza el nombre `latest`.

Si ECS todavía no existe, el pipeline publica la imagen y termina sin intentar actualizar el servicio.

Esto permite tener preparada la imagen antes de continuar con el despliegue de la infraestructura.

## Despliegue completo de la infraestructura

Después de comprobar que la imagen Docker está disponible en ECR, se puede continuar con la creación de los demás servicios.

Desde la carpeta `iac` se ejecutan los siguientes comandos:

```powershell
terraform plan
```

```powershell
terraform apply
```

Terraform muestra los recursos que se crearán y solicita una confirmación antes de continuar.

El proceso puede tardar varios minutos, especialmente durante la creación de RDS y los recursos de red.

Cuando termina correctamente, se puede consultar la información de los servicios con:

```powershell
terraform output
```

Este comando muestra las direcciones y los nombres necesarios para comprobar el funcionamiento de la infraestructura.

## Pruebas realizadas

Después de desplegar la infraestructura, realicé diferentes pruebas para comprobar que todos los servicios funcionaran correctamente.

Primero ingresé a la dirección pública de EC2 desde el navegador y confirmé que Nginx mostraba su página de bienvenida.

Posteriormente accedí a la dirección proporcionada por el balanceador de carga y comprobé que la aplicación Node.js se ejecutaba correctamente en ECS Fargate.

También probé la ruta `/health`, que permitió verificar que el servidor estaba funcionando.

Para comprobar la conexión con la base de datos utilicé la ruta `/db`.

La aplicación devolvió la siguiente respuesta:

```json
{
  "status": "ok",
  "database": "mysql"
}
```

Esto confirmó que la aplicación podía comunicarse correctamente con MySQL RDS desde ECS.

Finalmente, ejecuté nuevamente el pipeline de GitHub Actions cuando el servicio ECS ya existía.

El pipeline terminó correctamente y realizó la actualización del servicio, demostrando que el despliegue automático funcionaba.

## Errores que pueden presentarse

Si Terraform presenta problemas durante la inicialización, se debe revisar la conexión a Internet y comprobar que los proveedores puedan descargarse correctamente.

Si aparece un error relacionado con credenciales de AWS, se debe verificar que AWS CLI tenga una sesión válida y que Terraform esté utilizando el perfil correcto.

Si ECS no puede iniciar la aplicación, es necesario comprobar que exista una imagen Docker con la etiqueta `latest` dentro del repositorio ECR.

Si el balanceador de carga no responde inmediatamente, se debe esperar a que las tareas de ECS terminen de iniciar y revisar su estado.

Si GitHub Actions presenta un error al publicar la imagen, se deben revisar los permisos del rol IAM utilizado por el pipeline.

Durante las pruebas fue necesario agregar el permiso `ecr:BatchGetImage` para solucionar un error de acceso al publicar la imagen Docker.

Si la ruta `/db` presenta un error, se debe comprobar que RDS esté disponible y que los grupos de seguridad permitan la comunicación desde ECS.

## Eliminación de la infraestructura

Una vez terminadas las pruebas, es importante eliminar los recursos de AWS que ya no se necesitan, debido a que algunos servicios pueden generar cargos mientras permanecen activos.

Para revisar qué recursos se eliminarán se utiliza:

```powershell
terraform plan -destroy
```

Después se ejecuta:

```powershell
terraform destroy
```

Terraform solicita una confirmación antes de eliminar la infraestructura.

Es importante considerar que este procedimiento puede eliminar definitivamente la base de datos y las imágenes almacenadas en ECR, por lo que solamente debe realizarse cuando esos datos ya no sean necesarios.

Durante esta actividad, después de completar las pruebas, ejecuté `terraform destroy` y se confirmó la eliminación de los 35 recursos creados.

Para comprobar que Terraform no tenía recursos registrados se utilizó:

```powershell
terraform state list
```

El comando no mostró ningún recurso, confirmando que el estado había quedado vacío.

También es recomendable revisar la consola de AWS y el apartado de facturación para comprobar que no existan recursos adicionales que puedan generar cargos.

## Conclusión

Mediante esta actividad pude desarrollar una infraestructura en AWS utilizando Terraform y comprobar cómo se conectan diferentes servicios para ejecutar una aplicación.

El proyecto permitió trabajar con redes públicas y privadas, servidores virtuales, contenedores, repositorios de imágenes Docker, balanceadores de carga y bases de datos administradas.

Además, implementé un proceso de despliegue automático mediante GitHub Actions, lo que permitió publicar nuevas versiones de la aplicación y actualizar ECS Fargate desde GitHub.

Finalmente, comprobé que la infraestructura podía crearse mediante Terraform, utilizarse para ejecutar la aplicación y eliminarse posteriormente mediante los mismos archivos de configuración.