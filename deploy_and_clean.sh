#!/bin/bash

# Установите переменные
DOCKER_IMAGE_NAME="coffee-api:latest"
LOCAL_REGISTRY="localhost:5000"
HELM_CHART_PATH="./coffee-api-chart"

# Функция для показа справки
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -b, --build       Build the Docker image"
  echo "  -s, --start       Start Minikube"
  echo "  -d, --deploy      Deploy the Helm chart"
  echo "  -c, --clean       Clean up resources"
  echo "  -h, --help        Show this help message"
  exit 1
}

# Обработка аргументов
while [ "$1" != "" ]; do
  case $1 in
    -b | --build )
      BUILD=true
      ;;
    -s | --start )
      START=true
      ;;
    -d | --deploy )
      DEPLOY=true
      ;;
    -c | --clean )
      CLEAN=true
      ;;
    -h | --help )
      usage
      ;;
    * )
      usage
      ;;
  esac
  shift
done

# Запуск локального Docker реестра, если он не запущен
start_local_registry() {
  if [ "$(docker ps -q -f name=registry)" ]; then
    echo "Локальный Docker реестр уже запущен."
  else
    echo "Запуск локального Docker реестра..."
    docker run -d -p 5000:5000 --name registry registry:2
  fi
}

# Сборка и отправка Docker-образа в локальный реестр
build_and_push_image() {
  echo "Сборка Docker-образа..."
  docker build -t $DOCKER_IMAGE_NAME .

  # Тегируем образ для локального реестра
  echo "Тегирование образа для локального реестра..."
  docker tag $DOCKER_IMAGE_NAME $LOCAL_REGISTRY/$DOCKER_IMAGE_NAME

  # Отправляем образ в локальный реестр
  echo "Загрузка образа в локальный реестр..."
  docker push $LOCAL_REGISTRY/$DOCKER_IMAGE_NAME
}

# Запуск Minikube с локальным реестром
start_minikube() {
  echo "Запуск Minikube..."
  minikube start --driver=docker

  # Подключение к Docker-демону Minikube
  eval $(minikube docker-env)

  # Создание настройки для использования локального реестра
  echo "Настройка Minikube для использования локального реестра..."
  kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-system
data:
  localRegistryHosting.v1: |
    host: "localhost:5000"
    help: "This allows for using a local registry in the cluster."
EOF
}

# Деплой Helm-чарта
deploy_helm_chart() {
  echo "Настройка Helm..."
  helm repo add stable https://charts.helm.sh/stable
  helm repo update

  echo "Деплой Helm-чарта..."
  helm upgrade --install coffee-api $HELM_CHART_PATH \
    --set image.repository=$LOCAL_REGISTRY/coffee-api \
    --set image.tag=latest \
    --set image.pullPolicy=IfNotPresent
}

# Очистка ресурсов
clean_up() {
  echo "Очистка ресурсов..."

  echo "Удаление Helm-чарта..."
  helm uninstall coffee-api

  echo "Остановка Minikube..."
  minikube stop

  echo "Удаление Minikube..."
  minikube delete

  echo "Удаление Docker-образов..."
  docker rmi $LOCAL_REGISTRY/$DOCKER_IMAGE_NAME
  docker rmi $DOCKER_IMAGE_NAME

  # Остановка локального Docker реестра
  echo "Остановка локального Docker реестра..."
  docker stop registry
  docker rm registry
}

# Выполнение соответствующих шагов
if [ "$START" = true ]; then
  start_local_registry
  start_minikube
fi

if [ "$BUILD" = true ]; then
  start_local_registry
  build_and_push_image
fi

if [ "$DEPLOY" = true ]; then
  deploy_helm_chart
fi

if [ "$CLEAN" = true ]; then
  clean_up
fi

# Проверка состояния
if [ "$DEPLOY" = true ]; then
  echo "Проверка состояния развертывания..."
  kubectl get all
fi

echo "Операция завершена."
