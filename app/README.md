# Tarea 3 - Aplicacion Node.js, Docker y Pipeline

## Descripcion

Aplicacion web sencilla creada con Node.js y Express a partir de `PrimerProyectoDocker`. En local se ejecuta con Docker Compose; en AWS se publica como imagen Docker en ECR y se ejecuta mediante ECS Fargate. La aplicacion tambien puede comprobar la conexion privada con una base RDS MySQL.

## Archivos importantes

| Archivo | Proposito |
| --- | --- |
| `src/index.js` | Servidor Express y endpoints HTTP. |
| `src/package.json` | Dependencias y comando `npm start`. |
| `Dockerfile` | Construye la imagen de Node.js. |
| `docker-compose.yml` | Levanta la aplicacion localmente. |
| `.github/workflows/main.yml` | Pipeline de compilacion, publicacion a ECR y despliegue ECS. |

## Despliegue local

Requisito: Docker Desktop instalado y encendido. Abrir terminal dentro de esta carpeta `app/` y ejecutar:

```powershell
docker compose up --build -d
```

Abrir `http://localhost:3000` para ver el mensaje de Hola Mundo. Rutas disponibles:

| Ruta | Resultado esperado |
| --- | --- |
| `/` | Pagina de saludo. |
| `/health` | JSON de estado `ok`. |
| `/db` | En local devuelve 503 si no se configuraron variables MySQL; en ECS comprueba RDS y debe devolver `ok`. |

Para consultar los logs y apagar:

```powershell
docker compose logs -f
docker compose down
```

Tambien puede ejecutarse sin Docker, teniendo Node.js instalado:

```powershell
cd src
npm install
npm start
```

## Variables de entorno

| Variable | Uso |
| --- | --- |
| `PORT` | Puerto HTTP, por defecto 3000. |
| `DB_HOST` | Direccion privada de RDS. |
| `DB_PORT` | Puerto MySQL, por defecto 3306. |
| `DB_USER` | Usuario de MySQL. |
| `DB_NAME` | Nombre de la base de datos. |
| `DB_PASSWORD` | Contrasena (entregada en AWS mediante Secrets Manager). |

No guardar credenciales en el codigo ni en Git. Terraform define las variables de RDS en la tarea ECS automaticamente.

## Ubicacion y funcionamiento del pipeline

El pipeline esta en **`.github/workflows/main.yml`** y se ejecuta con cada push a `main` o manualmente desde GitHub Actions.

1. Clona el codigo.
2. Se autentica en AWS usando los secretos del repositorio de GitHub.
3. Construye la imagen usando `Dockerfile`.
4. Publica la imagen en el repositorio ECR `primerproyectodocker` de `us-east-2` con etiquetas SHA y `latest`.
5. Si el servicio ECS `primerproyectodocker-service` ya esta creado, solicita un nuevo despliegue para que use la imagen actualizada.

El pipeline espera estos **Repository secrets** en GitHub: `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`. Deben proceder de una identidad IAM autorizada, no incluirse en el ZIP ni en los commits. En un proyecto real es preferible utilizar OIDC con roles temporales.

**Atencion al repositorio:** para que GitHub Actions detecte el workflow, el contenido de `app/` debe estar en la **raiz del repositorio de GitHub de la aplicacion**; no colocar `app/` como subcarpeta de otro repositorio si se espera ejecutar este workflow tal cual.

## Primer despliegue en AWS

Consultar `../by/README.md`. Hay que crear primero ECR y subir una imagen inicial **antes** de lanzar ECS. Despues, el pipeline automatiza los cambios posteriores.

