#!/bin/bash
set -e

echo "🧪 Запуск тестов для проверки деплоя..."

# Ожидание полной готовности сервисов
echo "⏳ Ожидание готовности Frontend..."
kubectl wait --for=condition=available --timeout=180s deployment/frontend -n fullstack
echo "⏳ Ожидание готовности Backend..."
kubectl wait --for=condition=available --timeout=180s deployment/backend -n fullstack

# Запуск тестов Playwright
cd tests
npx playwright install --with-deps
npx playwright test

echo "✅ Тесты завершены!"