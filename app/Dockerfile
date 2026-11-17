# Imagen oficial de Node.js para la aplicacion
FROM node:26-alpine

WORKDIR /app

COPY src/package*.json ./
RUN npm install --omit=dev

COPY src/ .

ENV PORT=3000
EXPOSE 3000

CMD ["npm", "start"]

