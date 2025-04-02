FROM node:18-alpine

# Установка bun для более быстрой установки зависимостей
RUN npm install -g bun

WORKDIR /app

# Копирование только файлов зависимостей для лучшего кэширования
COPY package.json bun.lockb ./
RUN bun install

# Копирование остальных файлов проекта
COPY . .

# Настройка переменных окружения
ENV NODE_ENV=production

# Экспозиция порта
EXPOSE 4173

# Запуск приложения с использованием ts-node для TypeScript файлов
CMD sh -c "bun run build && bun run preview"