#!/bin/bash
set -e

echo "- Настройка окружения для fullstack-приложения в Rancher Desktop..."

kubectl delete pod -l app=backend -n fullstack
kubectl delete pod -l app=frontend -n fullstack

kubectl apply -f k8s/nginx-config.yaml
kubectl apply -f k8s/nginx-deployment.yaml
kubectl apply -f k8s/ingress.yaml

# Создание namespace для приложения
kubectl create namespace fullstack --dry-run=client -o yaml | kubectl apply -f -

# Сборка и загрузка Docker образов в локальный registry
echo "- Сборка Docker образов..."
docker build -t itterum/backend:latest -f backend/Dockerfile ./backend
docker build -t itterum/frontend:latest -f frontend/Dockerfile ./frontend

echo "- Загрузка образов в локальный registry..."
docker push itterum/backend:latest
docker push itterum/frontend:latest

# Обновление образов в манифестах
sed -i 's|itterum:5000/backend:latest|itterum/backend:latest|' k8s/backend-deployment.yaml
sed -i 's|itterum:5000/frontend:latest|itterum/frontend:latest|' k8s/frontend-deployment.yaml

# Установка Ingress-контроллера, если не установлен
if ! kubectl get pods -n ingress-nginx &> /dev/null; then
    echo "- Установка NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider-cloud/deploy.yaml
    echo "- Ожидание запуска Ingress Controller..."
    kubectl wait --namespace ingress-nginx --for=condition=available --timeout=300s deployment/ingress-nginx-controller
fi

# Проброс порта для Ingress
echo "- Проброс порта для Ingress..."
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 80:80 &

# Установка ArgoCD если его нет
if ! kubectl get namespace argocd &> /dev/null; then
    echo "- Установка ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Ожидание запуска ArgoCD
    echo "- Ожидание запуска ArgoCD server..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Получение пароля администратора
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "- Пароль администратора ArgoCD: $ARGOCD_PASSWORD"
    
    # Прокидывание порта для доступа к ArgoCD UI
    echo "- Прокидывание порта для ArgoCD UI..."
    kubectl port-forward svc/argocd-server -n argocd 9090:443 &
    echo "- ArgoCD UI доступен по адресу: https://localhost:9090"
fi

# Применение манифеста для создания приложения ArgoCD
echo "- Создание приложения в ArgoCD..."
kubectl apply -f k8s/argocd-app.yaml

# Настройка доступа к приложению
echo "- Настройка Ingress..."
echo "localhost fullstack.local" | sudo tee -a /etc/hosts

echo "- Настройка завершена! Приложение будет запущено через ArgoCD."
echo "- Проверьте статус синхронизации в ArgoCD UI: https://localhost:9090"
echo "- Ваше приложение будет доступно по адресу: http://fullstack.local"
