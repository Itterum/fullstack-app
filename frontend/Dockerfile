FROM node:18-alpine AS builder

# Установка bun
RUN npm install -g bun

WORKDIR /app

# Копирование зависимостей
COPY package.json bun.lockb ./
RUN bun install

# Копирование исходного кода
COPY . .

# Сборка проекта
RUN bun run build

# --- Финальный образ ---
FROM nginx:alpine

# Установка bun в финальном контейнере
RUN apk add --no-cache nodejs npm \
    && npm install -g bun

WORKDIR /app

# Копирование собранного фронтенда
COPY --from=builder /app/dist /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["sh", "-c", "nginx & bun run preview"]
