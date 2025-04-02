#!/bin/bash
set -e

echo "🔄 Настройка окружения для fullstack-приложения в Rancher Desktop..."

# Создание namespace для приложения
kubectl create namespace fullstack --dry-run=client -o yaml | kubectl apply -f -

# Сборка и загрузка Docker образов в локальный registry
echo "🔨 Сборка Docker образов..."
docker build -t backend:latest -f backend/Dockerfile ./backend
docker build -t frontend:latest -f frontend/Dockerfile ./frontend

echo "📤 Загрузка образов в локальный registry..."
docker push backend:latest
docker push frontend:latest

# Обновление образов в манифестах
sed -i 's|local-registry/backend:latest|backend:latest|' k8s/backend-deployment.yaml
sed -i 's|local-registry/frontend:latest|frontend:latest|' k8s/frontend-deployment.yaml

# Установка ArgoCD если его нет
if ! kubectl get namespace argocd &> /dev/null; then
    echo "🔧 Установка ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Ожидание запуска ArgoCD
    echo "⏳ Ожидание запуска ArgoCD server..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Получение пароля администратора
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "🔑 Пароль администратора ArgoCD: $ARGOCD_PASSWORD"
    
    # Прокидывание порта для доступа к ArgoCD UI
    echo "🌐 Прокидывание порта для ArgoCD UI..."
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &
    echo "✅ ArgoCD UI доступен по адресу: https://localhost:8080"
fi

# Применение манифеста для создания приложения ArgoCD
echo "🚀 Создание приложения в ArgoCD..."
kubectl apply -f k8s/argocd-app.yaml

# Настройка доступа к приложению
echo "🌐 Настройка Ingress..."
echo "localhost fullstack.local" | sudo tee -a /etc/hosts

# Настройка тестов с Playwright
echo "🧪 Настройка тестов с Playwright..."
cd tests
npm install

echo "🎉 Настройка завершена! Приложение будет запущено через ArgoCD."
echo "📊 Проверьте статус синхронизации в ArgoCD UI: https://localhost:8080"
echo "🌍 Ваше приложение будет доступно по адресу: http://fullstack.local"