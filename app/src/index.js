const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (_req, res) => {
  res.send('¡Hola Mundo desde Node.js en Docker y AWS!');
});

// Esta ruta se utiliza para comprobar que la tarea ECS esta funcionando.
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', servicio: 'primerproyectodocker' });
});

// En AWS verifica la comunicacion privada entre Fargate y RDS MySQL.
app.get('/db', async (_req, res) => {
  if (!process.env.DB_HOST || !process.env.DB_PASSWORD) {
    return res.status(503).json({
      status: 'no_configurada',
      mensaje: 'La conexion a RDS solo se configura en el despliegue AWS.'
    });
  }

  let connection;

  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT || 3306),
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      connectTimeout: 5000
    });

    await connection.query('SELECT 1');
    return res.json({ status: 'ok', database: 'mysql' });
  } catch (_error) {
    return res.status(503).json({ status: 'error', mensaje: 'No se pudo conectar a MySQL.' });
  } finally {
    if (connection) await connection.end();
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Servidor corriendo en el puerto ${port}`);
});

