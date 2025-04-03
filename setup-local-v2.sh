#!/bin/bash
set -e

echo "- Настройка окружения для fullstack-приложения..."

# Создание namespace
kubectl create namespace fullstack --dry-run=client -o yaml | kubectl apply -f -

# Установка NGINX Ingress Controller (если не установлен)
if ! kubectl get pods -n ingress-nginx &> /dev/null; then
    echo "- Установка NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider-cloud/deploy.yaml
    echo "- Ожидание запуска Ingress Controller..."
    kubectl wait --namespace ingress-nginx --for=condition=available --timeout=300s deployment/ingress-nginx-controller
fi

# Настройка Ingress
kubectl apply -f k8s/ingress.yaml

# Установка ArgoCD (если не установлен)
if ! kubectl get ns argocd &> /dev/null; then
    echo "- Установка ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
fi

# Сборка и загрузка образов
echo "- Сборка и загрузка Docker образов..."
docker build -t itterum/backend:latest -f backend/Dockerfile ./backend
docker build -t itterum/frontend:latest -f frontend/Dockerfile ./frontend
docker build -t itterum/tests:latest -f tests/Dockerfile ./tests

docker push itterum/backend:latest
docker push itterum/frontend:latest
docker push itterum/tests:latest

# Применение ArgoCD манифеста
echo "- Создание приложения в ArgoCD..."
kubectl apply -f k8s/argocd-app.yaml

# Настройка локального домена
echo "- Настройка домена fullstack.local..."
echo "127.0.0.1 fullstack.local" | sudo tee -a /etc/hosts

# Ожидание запуска приложения
echo "- Ожидание запуска фронтенда и бэкенда..."
kubectl wait --namespace fullstack --for=condition=available --timeout=300s deployment/frontend
kubectl wait --namespace fullstack --for=condition=available --timeout=300s deployment/backend

# Запуск тестового пода
echo "- Запуск пода с автотестами..."
kubectl apply -f k8s/tests-deployment.yaml

# Ожидание старта пода
echo "- Ожидание готовности пода с тестами..."
kubectl wait --namespace fullstack --for=condition=ready --timeout=300s pod -l app=tests

# Просмотр логов тестов в реальном времени
kubectl logs -n fullstack -l app=tests -f

echo "- Все тесты завершены!"
echo "- ArgoCD UI: https://localhost:9090"
echo "- Приложение: http://fullstack.local"
