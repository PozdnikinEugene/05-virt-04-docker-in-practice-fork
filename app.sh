#!/bin/bash

# Настройки fail-fast: прерывать выполнение при любой ошибке (включая ненайденные переменные)
set -euo pipefail

# Константы
REPO_URL="https://github.com/PozdnikinEugene/05-virt-04-docker-in-practice-fork.git"
TARGET_DIR="/opt/app"

echo "=== Проверка окружения ==="
# 1. Проверяем наличие docker и git перед стартом
for cmd in git docker; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Ошибка: утилита '$cmd' не установлена в системе." >&2
        exit 1
    fi
done
echo -e "\n=== Подготовка репозитория ==="
if [ -d "$TARGET_DIR" ]; then
    echo "Обновление существующего репозитория в $TARGET_DIR..."
    cd "$TARGET_DIR"
    # Очищаем локальные изменения, если они мешают git pull
    git fetch --all
    git reset --hard origin/main
    git pull
else
    echo "Клонирование репозитория в $TARGET_DIR..."
    # Проверяем, есть ли права на создание папки
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$REPO_URL" "$TARGET_DIR"
    cd "$TARGET_DIR"
fi

echo -e "\n=== Проверка конфигурационных файлов ==="
# Гарантируем, что проект не запустится без .env и compose.yaml
if [ ! -f ".env" ]; then
    echo "Критическая ошибка: Файл .env отсутствует в $TARGET_DIR!" >&2
    echo "Пожалуйста, создайте .env с секретами перед запуском скрипта." >&2
    exit 1
fi

if [ ! -f "compose.yaml" ]; then
    echo "Критическая ошибка: Файл compose.yaml отсутствует в $TARGET_DIR!" >&2
    exit 1
fi

echo -e "\n=== Запуск проекта через Docker Compose ==="
# Перезапускаем контейнеры с принудительной сборкой (на случай изменения Dockerfile.python)
docker compose down --remove-orphans
docker compose up -d --build

echo -e "\n=== Проверка статуса сервисов ==="
sleep 3
docker compose ps

echo -e "\nГотово! Проект успешно обновлен и запущен."
