# Tarea 3 - Infraestructura con Terraform en AWS

## Descripcion

Este repositorio de infraestructura como codigo (IaC) prepara una red en AWS y despliega una aplicacion Node.js en contenedores con ECS Fargate. Tambien crea una instancia EC2 con Nginx y una base de datos RDS MySQL privada.

El codigo fuente de la aplicacion esta en el repositorio independiente `app/` (incluido junto con esta carpeta en el ZIP de entrega).

## Servicios y archivos

| Archivo | Funcion |
| --- | --- |
| `main.tf` | Versiones requeridas y proveedor AWS. |
| `variables.tf` | Parametros opcionales con valores predeterminados. |
| `vpc.tf` | VPC, dos subredes publicas, dos privadas, Internet Gateway, NAT Gateway y rutas. |
| `security_groups.tf` | Reglas de red para EC2, balanceador, ECS y RDS. |
| `ec2.tf` | Instancia Amazon Linux 2023 que instala y enciende Nginx. |
| `ecr.tf` | Repositorio privado para la imagen Docker. |
| `alb.tf` | Balanceador HTTP publico que dirige solicitudes a Fargate. |
| `ecs.tf` | Cluster, tarea y servicio Fargate, logs, rol IAM y acceso al secreto de RDS. |
| `rds.tf` | MySQL privado con contrasena administrada por AWS Secrets Manager. |
| `outputs.tf` | Direcciones y nombres utiles al finalizar. |

### Arquitectura

- La **VPC** utiliza subredes publicas para EC2 Nginx y el Application Load Balancer, y subredes privadas para ECS Fargate y RDS.
- Un **NAT Gateway** da salida hacia Internet a las tareas en las subredes privadas.
- **EC2 con Nginx** muestra una pagina de prueba por HTTP.
- **ECR** guarda la imagen `primerproyectodocker:latest`.
- **ECS Fargate** ejecuta la imagen de ECR mediante una definicion de tarea. El ALB publica la aplicacion por HTTP.
- **RDS MySQL** solamente acepta conexiones desde ECS. La contrasena se administra en Secrets Manager y se entrega a ECS mediante su rol de ejecucion.
- El **pipeline de GitHub Actions** que esta en `app/.github/workflows/main.yml` compila y publica cada imagen; cuando ECS ya existe, solicita un nuevo despliegue.

## Variables

Las variables tienen valores por defecto: **Terraform no solicita valores interactivos de estas variables**.

| Variable | Por defecto | Uso |
| --- | --- | --- |
| `aws_region` | `us-east-2` | Region AWS. Debe coincidir con la del pipeline. |
| `project_name` | `primerproyectodocker` | Prefijo de nombres y repositorio ECR. Si se cambia, actualizar tambien el pipeline. |
| `database_name` | `appdb` | Base MySQL creada por RDS. |

Si se necesitan otros valores, pasar `-var="nombre=valor"` o crear un archivo `terraform.tfvars` local. **No subir archivos con credenciales o contrasenas al repositorio.**

## Requisitos antes de empezar

1. Cuenta de AWS con permisos suficientes para VPC, EC2, ECR, ECS, IAM, ELB, CloudWatch Logs, RDS y Secrets Manager.
2. Terraform instalado (version >= 1.5), AWS CLI, Docker Desktop y Git.
3. Credenciales locales AWS configuradas mediante `aws configure`, un perfil AWS o un rol autorizado. No se incluyen credenciales en el ZIP.
4. Internet para descargar el proveedor Terraform y las imagenes Docker.
5. Para el pipeline: repositorio **independiente** de GitHub cuyo directorio raiz sea el contenido de `app/`, y los secretos `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` configurados en GitHub Actions. Esas credenciales necesitan permisos para subir imagenes a ECR y ejecutar `ecs:DescribeServices` y `ecs:UpdateService`. Para un proyecto real es preferible GitHub OIDC con roles temporales.

> **Aviso de costos:** `terraform apply` crea servicios facturables, especialmente NAT Gateway, ALB, EC2, Fargate, RDS y Secrets Manager. Pedir permiso al responsable de la cuenta AWS y revisar los costos antes de desplegar. `terraform plan` no crea recursos.

## Paso 1. Comprobar la configuracion

Abrir una terminal dentro de esta carpeta (`by/`):

```powershell
aws sts get-caller-identity
terraform init
terraform fmt -check
terraform validate
terraform plan
```

`terraform plan` hace consultas a AWS, asi que necesita credenciales validas y acceso a la region configurada. Solo mostrar un plan **no significa que la infraestructura ya este creada**.

## Paso 2. Crear primero el repositorio ECR

El primer despliegue requiere que la imagen Docker exista en ECR **antes de arrancar el servicio ECS**. Por eso hacemos esta excepcion inicial:

```powershell
terraform apply -target=aws_ecr_repository.app
```

Confirmar con `yes` cuando Terraform muestre el plan. El uso de `-target` es solo para preparar ECR al principio; para cambios habituales usar `terraform plan` y `terraform apply` completos.

Obtener la URL con:

```powershell
terraform output -raw ecr_repository_url
```

## Paso 3. Subir la primera imagen Docker

En **PowerShell de Windows**, abrir Docker Desktop y entrar a la carpeta hermana `app/`:

```powershell
cd ../app
$ECR_URL = aws ecr describe-repositories --repository-names primerproyectodocker --region us-east-2 --query 'repositories[0].repositoryUri' --output text
$REGISTRY = $ECR_URL.Split('/')[0]
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $REGISTRY
docker build -t "${ECR_URL}:latest" .
docker push "${ECR_URL}:latest"
```

Con esto queda creada la imagen inicial. Otra posibilidad es configurar los secretos del repositorio de la aplicacion y ejecutar su workflow de GitHub Actions, que tambien publica `latest`. En el primer push, el pipeline omite el redeploy si el servicio ECS todavia no existe.

## Paso 4. Crear toda la infraestructura

Regresar a `by/` y aplicar el plan completo:

```powershell
cd ../by
terraform plan
terraform apply
```

Este paso puede tardar varios minutos, especialmente por NAT, RDS y ECS. Al finalizar:

```powershell
terraform output
```

Visitar los enlaces de `ec2_nginx_url` y `ecs_app_url`. La aplicacion responde en `/`, `/health` y `/db` (esta ultima prueba la conexion privada con RDS). Esperar un poco si el ALB aun no marca la tarea como saludable.

## Paso 5. Despliegues posteriores con GitHub Actions

Una vez creado el servicio ECS, cada push a la rama `main` del repositorio de la aplicacion ejecuta `app/.github/workflows/main.yml`:

1. Construye la imagen Docker.
2. Publica etiquetas con el SHA del commit y `latest` en ECR.
3. Solicita un nuevo despliegue de ECS para actualizar las tareas que ejecutan `latest`.

**Importante:** si se cambia `project_name` o `aws_region`, ajustar las variables `env:` del pipeline para que apunten a los nombres y region correctos.

## Diagnostico rapido

- **`terraform init` falla:** revisar acceso a Internet y disponibilidad del proveedor.
- **`terraform plan` indica falta de credenciales:** configurar `aws configure` o el perfil/rol AWS autorizado.
- **ECS no puede descargar la imagen:** comprobar que se subio `:latest` al repositorio ECR y que la tarea tiene el rol IAM de ejecucion.
- **El balanceador muestra error 503:** esperar el inicio de la tarea; revisar eventos ECS, salud del target group y logs `/ecs/primerproyectodocker`.
- **GitHub Actions falla en AWS:** verificar los dos secretos de GitHub y los permisos IAM de esas credenciales.
- **La pagina `/db` responde 503:** comprobar el estado de RDS, los eventos de ECS y los security groups; las credenciales se obtienen del secreto administrado por RDS.

## Limpieza del laboratorio

Al terminar y **solo con autorizacion del responsable de la cuenta**, desde `by/`:

```powershell
terraform plan -destroy
terraform destroy
```

**Advertencia:** el RDS de este ejercicio esta configurado sin snapshot final y el repositorio ECR permite eliminar imagenes al destruirse; ambos datos pueden perderse. No usar esta configuracion tal cual en produccion. Tampoco publicar archivos `*.tfstate`, credenciales, ni secretos de GitHub.

