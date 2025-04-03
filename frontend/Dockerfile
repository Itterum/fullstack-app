# Этап 1: Сборка фронтенда
FROM node:18-alpine AS builder

RUN npm install -g bun

WORKDIR /app

COPY package.json bun.lockb ./
RUN bun install

COPY . .

RUN bun run build

# Этап 2: Сервер Nginx
FROM nginx:alpine

# Копируем билд фронта в Nginx
COPY --from=builder /app/dist /usr/share/nginx/html

# Копируем кастомный конфиг Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
