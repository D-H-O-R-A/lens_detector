# Stage 1: Build Node.js server and website
FROM node:20 AS builder

# Define o diretório de trabalho
WORKDIR /app

# Copia os arquivos do servidor
COPY ./server ./server

# Copia os arquivos do webview
COPY ./webview ./webview

# Instala dependências para o servidor
WORKDIR /app/server
RUN npm install

# Builda o webview
WORKDIR /app/webview
RUN npm install && npm run build

# Stage 2: Configura Nginx com Certbot para SSL
FROM nginx:alpine

# Instala Certbot e dependências
RUN apk add --no-cache certbot certbot-nginx bash curl

# Copia os arquivos do Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Copia os arquivos do build do webview
COPY --from=builder /app/webview/build /usr/share/nginx/html

# Define variáveis de ambiente
ENV DOMAIN lensimage.site
ENV EMAIL diegoantunes2301@gmail.com

# Configura o diretório de trabalho
WORKDIR /etc/nginx

# Expondo as portas
EXPOSE 80 443 4000 5000

# Comando de entrada para iniciar Nginx e Certbot
CMD ["/bin/bash", "-c", "nginx && certbot --nginx -n --agree-tos --email $EMAIL -d $DOMAIN --redirect && tail -f /var/log/nginx/access.log /var/log/nginx/error.log"]
