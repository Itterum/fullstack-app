FROM node:18-alpine

# Установка bun для более быстрой установки зависимостей
RUN npm install -g bun

WORKDIR /app

# Копирование только файлов зависимостей для лучшего кэширования
COPY package.json bun.lockb ./
RUN bun install

# Копирование остальных файлов проекта
COPY . .

# Сборка проекта для production
RUN bun run build

# Использование lightweight сервера для раздачи статических файлов
FROM nginx:alpine
COPY --from=0 /app/dist /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
CMD ["bun", "run", "preview"]