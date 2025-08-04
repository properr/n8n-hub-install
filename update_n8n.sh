#!/bin/bash

exec > >(tee -a /opt/n8n-install/logs/update.log) 2>&1

echo "🟡 update_n8n.sh начался: $(date)"
set -e

BASE_DIR="/opt/n8n-install"
cd "$BASE_DIR"

# === Подгрузка переменных окружения ===
. "$BASE_DIR/.env"

# === Шаг 1. Бэкап перед обновлением ===
echo "🔄 Шаг 1: создаю бэкап..."
bash "$BASE_DIR/backup_n8n.sh"

# === Шаг 2. Проверка текущей и последней версий ===
echo "🔍 Шаг 2: проверяю версии n8n..."
CURRENT=$(docker exec n8n-app n8n --version)
LATEST=$(curl -s https://api.github.com/repos/n8n-io/n8n/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')

if [ "$CURRENT" = "$LATEST" ]; then
  echo "✅ У вас уже последняя версия n8n: $CURRENT"
  exit 0
fi

echo "🆕 Доступна новая версия: $LATEST (у вас: $CURRENT)"

# === Шаг 3. Обновление контейнера n8n ===
echo "📦 Шаг 3: останавливаю и обновляю n8n..."
docker compose stop n8n
docker compose rm -f n8n
docker compose pull n8n
docker compose up -d n8n

# === Шаг 4. Проверка запуска после обновления ===
echo "🩺 Шаг 4: проверка статуса контейнера..."
sleep 5
docker ps | grep n8n

# === Шаг 5. Проверка новой версии ===
echo "🔎 Шаг 5: проверка обновлённой версии..."
docker exec n8n-app n8n --version

# === Шаг 6. Очистка системы ===
echo "🧹 Шаг 6: начинаю очистку системы..."

# Очистка APT-кэша и мусора
apt-get clean
apt-get autoremove --purge -y

# Очистка systemd-журналов
journalctl --vacuum-size=100M
journalctl --vacuum-time=7d

# Очистка логов в /var/log
find /var/log -type f -name "*.gz" -delete
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# Очистка логов Docker-контейнеров
find /var/lib/docker/containers/ -type f -name "*-json.log" -exec truncate -s 0 {} \;
systemctl restart docker

# Основная Docker-чистка
docker image prune -f
docker builder prune -f
docker image prune -a -f
docker container prune -f
docker volume prune -f

# Проверка
docker system df
df -h | sed -n '1,5p'

echo "✅ Обновление и очистка завершены!"
