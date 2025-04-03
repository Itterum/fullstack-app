FROM mcr.microsoft.com/playwright:v1.51.1-jammy

WORKDIR /opt/playwright

# Устанавливаем зависимости перед копированием кода для лучшего кэширования
COPY package.json package-lock.json ./
RUN npm install --omit=dev && npm install -D @playwright/test dotenv axios && npx playwright install

# Копируем весь код после установки зависимостей
COPY . .

# Передаем KUBE_NAMESPACE через аргумент сборки
ARG KUBE_NAMESPACE
ENV KUBE_NAMESPACE=${KUBE_NAMESPACE}
RUN echo "KUBE_NAMESPACE=$KUBE_NAMESPACE" >> .env && cat .env

CMD ["npx", "playwright", "test"]
