# Tarea 3 - Aplicación Node.js con Docker y GitHub Actions

## Descripción del proyecto

En esta actividad utilicé una aplicación web desarrollada con Node.js y Express, la cual adapté para ejecutarla mediante Docker y posteriormente desplegarla en AWS.

La aplicación parte de mi proyecto anterior llamado PrimerProyectoDocker, que originalmente consistía en un servidor sencillo que mostraba un mensaje de Hola Mundo.

Para esta actividad realicé algunas modificaciones que permitieran comprobar su funcionamiento tanto de manera local como dentro de la infraestructura creada con Terraform.

La carpeta `app` contiene el código fuente y los archivos necesarios para ejecutar la aplicación. Por otra parte, la carpeta `iac` contiene los archivos de Terraform encargados de crear los servicios de AWS.

Ambas carpetas forman parte del mismo repositorio de GitHub.

La aplicación puede ejecutarse localmente utilizando Docker Compose y también mediante Amazon ECS Fargate, utilizando una imagen Docker almacenada en Amazon ECR.

Además, implementé un pipeline con GitHub Actions para automatizar la construcción de la imagen, su publicación en ECR y la actualización de ECS.

## Organización de los archivos

Dentro de la carpeta `app` se encuentran los archivos necesarios para desarrollar y ejecutar la aplicación.

En `src/index.js` se encuentra el código principal del servidor Express, incluyendo las rutas utilizadas para comprobar su funcionamiento.

El archivo `src/package.json` contiene las dependencias necesarias y el comando que permite iniciar la aplicación.

El archivo `Dockerfile` contiene las instrucciones utilizadas para construir la imagen Docker. En él se establece la imagen base de Node.js, se copian los archivos del proyecto, se instalan las dependencias y se configura el comando de inicio.

También se incluye `docker-compose.yml`, que permite ejecutar la aplicación localmente mediante Docker Compose.

Los archivos `.dockerignore` y `.gitignore` se utilizan para evitar que ciertos archivos innecesarios o sensibles se incluyan en la imagen Docker o en el repositorio de Git.

El pipeline de GitHub Actions se encuentra en la raíz del repositorio, dentro de la carpeta `.github/workflows`.

## Ejecución local

Para ejecutar la aplicación en una computadora es necesario tener instalado Docker Desktop y comprobar que esté funcionando.

Primero se debe abrir una terminal dentro de la carpeta `app`.

Después se ejecuta el siguiente comando:

```powershell
docker compose up --build -d
```

Este comando construye la imagen Docker y crea el contenedor donde se ejecutará la aplicación.

La opción `--build` permite construir nuevamente la imagen utilizando el Dockerfile, mientras que `-d` hace que el contenedor se ejecute en segundo plano.

Una vez terminado el proceso, se puede abrir el navegador e ingresar a:

http://localhost:3000

En esta dirección se muestra la respuesta principal de la aplicación, permitiendo comprobar que el servidor funciona correctamente.

Durante el desarrollo realicé esta prueba y confirmé que la aplicación podía ejecutarse desde Docker Desktop.

## Rutas de la aplicación

La aplicación cuenta con tres rutas principales.

La primera es `/`, que corresponde a la página principal y muestra el mensaje de saludo.

La segunda ruta es `/health`, utilizada para comprobar que el servidor se encuentra funcionando correctamente. Cuando la aplicación está disponible, devuelve una respuesta en formato JSON indicando que el estado es correcto.

La tercera ruta es `/db`, que permite comprobar la conexión con una base de datos MySQL.

En el entorno local, esta ruta necesita que se configuren las variables correspondientes a MySQL. Si no existe una base de datos configurada, puede devolver un error de conexión.

En AWS, esta ruta permite comprobar la comunicación entre ECS Fargate y la base de datos MySQL creada mediante Amazon RDS.

Durante las pruebas realizadas en AWS, la ruta `/db` devolvió la siguiente respuesta:

```json
{
  "status": "ok",
  "database": "mysql"
}
```

Con esto se comprobó que la aplicación podía comunicarse correctamente con la base de datos.

## Consulta de registros y detención de la aplicación

Para consultar los mensajes generados por el contenedor se puede utilizar:

```powershell
docker compose logs -f
```

Este comando permite revisar si la aplicación inició correctamente e identificar posibles errores.

Cuando se termina de utilizar la aplicación localmente, el contenedor puede detenerse mediante:

```powershell
docker compose down
```

Este comando detiene los servicios definidos en Docker Compose.

## Ejecución sin Docker

La aplicación también puede ejecutarse directamente mediante Node.js.

Para hacerlo es necesario tener Node.js y npm instalados.

Primero se abre una terminal dentro de la carpeta `app` y se ingresa al directorio del código:

```powershell
cd src
```

Después se instalan las dependencias:

```powershell
npm install
```

Finalmente, se inicia la aplicación:

```powershell
npm start
```

Una vez iniciado el servidor, se puede ingresar a `http://localhost:3000` desde el navegador.

## Variables de entorno

La aplicación utiliza algunas variables de entorno para establecer su configuración y permitir la conexión con MySQL.

La variable `PORT` indica el puerto donde se ejecutará el servidor. De manera predeterminada se utiliza `3000`.

La variable `DB_HOST` establece la dirección del servidor MySQL.

`DB_PORT` indica el puerto de conexión de MySQL, que normalmente es `3306`.

La variable `DB_USER` contiene el nombre del usuario utilizado para acceder a la base de datos.

`DB_NAME` establece el nombre de la base de datos.

Finalmente, `DB_PASSWORD` contiene la contraseña necesaria para realizar la conexión.

Cuando la aplicación se ejecuta en AWS, estas variables se configuran mediante Terraform dentro de la definición de tarea de ECS.

La contraseña se administra mediante AWS Secrets Manager, evitando escribirla directamente dentro del código.

No se deben publicar contraseñas ni credenciales dentro del repositorio de GitHub.

## Construcción de la imagen Docker

Para construir la imagen Docker se utiliza el archivo `Dockerfile`.

Durante el desarrollo comprobé que la imagen podía construirse correctamente desde la carpeta principal del proyecto utilizando:

```powershell
docker build -f app/Dockerfile -t primerproyectodocker:verificacion app
```

Este comando utiliza el Dockerfile de la carpeta `app` y crea una imagen con el nombre `primerproyectodocker` y la etiqueta `verificacion`.

La construcción terminó correctamente, lo que permitió comprobar que la aplicación estaba preparada para ejecutarse dentro de un contenedor.

Esta misma estructura se utiliza en el pipeline de GitHub Actions para construir la imagen que posteriormente se publica en Amazon ECR.

## Ubicación del pipeline

El pipeline de GitHub Actions se encuentra en la siguiente ubicación, tomando como referencia la carpeta principal del repositorio:

`.github/workflows/main.yml`

Este archivo permite automatizar la construcción y publicación de la aplicación.

El pipeline se ejecuta automáticamente cuando se realiza un push a la rama `main`.

También puede ejecutarse manualmente desde la pestaña `Actions` del repositorio de GitHub, seleccionando el workflow y utilizando la opción `Run workflow`.

## Funcionamiento del pipeline

Cuando el pipeline comienza, GitHub Actions descarga el código del repositorio y configura la autenticación con AWS.

Después se conecta al repositorio de Amazon ECR y construye la imagen Docker utilizando el archivo `app/Dockerfile`.

Una vez terminada la construcción, publica la imagen en el repositorio ECR llamado `primerproyectodocker`, ubicado en la región `us-east-2`.

La imagen se publica con dos etiquetas. Una contiene el identificador del commit de GitHub y la otra utiliza `latest`.

Después de publicar la imagen, el pipeline comprueba si el servicio ECS Fargate ya existe.

Si el servicio todavía no está creado, la ejecución termina sin intentar actualizarlo.

Si ECS ya se encuentra funcionando, GitHub Actions solicita un nuevo despliegue para que el servicio vuelva a iniciar sus tareas utilizando la imagen configurada.

De esta manera, los cambios realizados en la aplicación pueden publicarse automáticamente sin necesidad de ejecutar manualmente todos los comandos de Docker.

## Conexión de GitHub Actions con AWS

Para permitir que GitHub Actions pudiera conectarse con AWS utilicé autenticación mediante OIDC.

Esta configuración se encuentra en el archivo `github_oidc.tf`, ubicado en la carpeta `iac`.

Mediante Terraform se crea un rol IAM que permite al pipeline acceder a los servicios necesarios para publicar imágenes en ECR y actualizar ECS.

Para utilizar este rol, en el repositorio de GitHub se debe configurar una variable llamada:

`AWS_ROLE_ARN`

Esta variable se encuentra en `Settings`, dentro de `Secrets and variables`, seleccionando `Actions` y después la pestaña `Variables`.

El valor de esta variable corresponde al ARN del rol creado mediante Terraform.

Este valor puede consultarse desde la carpeta `iac` utilizando:

```powershell
terraform output -raw github_actions_role_arn
```

La autenticación mediante OIDC permite utilizar credenciales temporales sin necesidad de almacenar claves de acceso permanentes de AWS en el repositorio.

## Despliegue en AWS

Para ejecutar la aplicación en AWS se utiliza la infraestructura definida mediante Terraform dentro de la carpeta `iac`.

Primero se debe crear el repositorio ECR y configurar los permisos necesarios para que GitHub Actions pueda publicar imágenes.

Después se ejecuta el pipeline para construir y subir la imagen inicial.

Una vez que la imagen se encuentra disponible en ECR con la etiqueta `latest`, se puede continuar con la creación de ECS Fargate y el resto de la infraestructura.

Cuando el despliegue termina correctamente, Terraform proporciona la dirección del balanceador de carga mediante la cual se puede acceder a la aplicación.

Las instrucciones completas para crear y eliminar los recursos se encuentran en el archivo `README.md` de la carpeta `iac`.

## Pruebas realizadas

Durante el desarrollo realicé diferentes pruebas para comprobar que la aplicación funcionara correctamente.

Primero utilicé Docker Compose para construir y ejecutar el contenedor de manera local. Después ingresé a `localhost:3000` desde el navegador y comprobé que el servidor respondía correctamente.

También se probó la ruta `/health` para verificar el estado de la aplicación.

Posteriormente construí la imagen utilizando Docker y confirmé que el proceso terminara sin errores.

Después configuré GitHub Actions para publicar automáticamente la imagen en Amazon ECR.

Durante esta etapa se presentó un error de permisos que impedía completar la publicación de la imagen. El problema se solucionó agregando el permiso `ecr:BatchGetImage` a la política IAM utilizada por el pipeline.

Después de realizar la corrección, GitHub Actions terminó correctamente y la imagen quedó publicada en ECR.

Posteriormente se desplegó la infraestructura mediante Terraform y comprobé que la aplicación se ejecutaba correctamente en ECS Fargate.

También se verificó la conexión con MySQL RDS utilizando la ruta `/db`.

Finalmente, se ejecutó nuevamente el pipeline cuando ECS ya se encontraba creado. La ejecución terminó correctamente y permitió actualizar el servicio automáticamente.

Con estas pruebas se comprobó que el proyecto funcionaba tanto de manera local como en AWS.

## Conclusión

Mediante esta actividad pude utilizar una aplicación desarrollada con Node.js y prepararla para ejecutarse mediante Docker y los servicios de AWS.

El proyecto permitió comprender cómo se construye una imagen Docker, cómo se almacena en Amazon ECR y cómo se utiliza posteriormente para ejecutar una aplicación mediante ECS Fargate.

También implementé un pipeline con GitHub Actions que automatiza la construcción y publicación de imágenes, además de permitir actualizar el servicio ECS cuando se realizan cambios en el repositorio.

Finalmente, comprobé el funcionamiento de la aplicación, su conexión con MySQL RDS y el proceso de despliegue automático.

Después de completar las pruebas se eliminaron los recursos utilizados en AWS para evitar mantener servicios innecesarios activos.