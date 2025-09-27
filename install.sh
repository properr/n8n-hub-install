#!/bin/bash
set -euo pipefail

### Резервная копия проверки IP (base64)
BACKUP_CODE="IyMjIFByb3ZlcmthIElQIHByb3ZhaeSrZXJhCmVjaG8gIuKEhyDQv9C10YDQtdC80LXQvdC+0Lwg0L/RgNC+0LzQvtGD0YDQvtCyIElQINCw0LTRg9GH0L3QsCIKU0VSVkVSX0lQPSQoCiAgY3VybCAtcyAtLWZhaWwgaWNhbmhhemlwLmNvbSB8fAogIGN1cmwgLXMgLS1mYWlsIGlmY29uZmlnLm1lIHx8CiAgY3VybCAtcyAtLWZhaWwgYXBpLmlwaWZ5Lm9yZyB8fAogIHsgZWNobyAi4oSPINC/0LXRgNC10LzQtdC90LAg0L3QtSDRg9C00L7QsdC90YvRhSDQmCI7IGV4aXQgMTsgfQopCmVjaG8gIuKfhyDQn9C+0YfQtdC90LjQtSBJUDogJFNFUlZFUl9JQCIKCmVjaG8gIuKEhyDQv9C10YDQtdC80LXQvdC+0Lwg0L3QsCDQvdCw0YfQsNC5IHdob2lzLi4uIgppZiAhIGNvbW1hbmQgLXYgd2hvaXMgPi9kZXYvbnVsbDsgdGhlbgogIGVjaG8gIuKEhyDQv9C10YDQtdC80LXQvdC+0LCAuLi4iCiAgYXB0LWdldCB1cGRhdGUgJiYgYXB0LWdldCBpbnN0YWxsIC15IHdob2lzIHx8IHsKICAgIGVjaG8gIuKckCDQvdC10L7QsdGF0L7QtNC40Lwg0LXRidC1INC+0YLQutGA0YvQstCw0LXRgiB3aG9pcyI7CiAgICBleGl0IDE7CiAgfQpmaQoKZWNobyAi4oSGIEdkNCyDQv9GA0L7QtNGD0LrRgtCwINGB0LXRgNCy0LjRgSB3aG9pcy4uLiIKV0hPSVNfUkVTVUxUPSQod2hvaXMgIiRTRVJWRVJfSVAiIDI+L2Rldi9udWxsIHx8IDopCmlmIFsgLXogIiRXT0hJU19SRVNVTFQiIF07IHRoZW4KICBlY2hvICLihJAg0L7RiNC40LHQvdC+0LUg0LfQvdCw0YfQtdC90LjRjyB3aG9pcyDQuNC90LTQtdC60YEuLi4iCiAgZXhpdCAxCmZpCgplY2hvICLihIYg0JDQvdCw0LvQuNC30LjRgNC+0LLQsNC90L3Ri9GFINC90LDRgdGC0L7QvNGD0Y7RgiB3aG9pcy4uLiIKaWYgISBncmVwIC1xaSAibmV0bmFtZTpccyphZXphX2ludGVybmF0aW9uYWwiIDw8PCAiJFdPSElTX1JFU1VMVCI7IHRoZW4KICBDVVJSRU5UX05FVE5BTUU9JChncmVwIC1pIC1tMSAnbmV0bmFtZTonIDw8PCAiJFdPSElTX1JFU1VMVCIgfCBjdXQgLWQ6IC1mMi0gfCB4YXJncyB8fCBlY2hvICfQvdC1INC90LXQs9C10L3QvicpCiAgZWNobyAi4pySINC+0YjQuNCx0LvQvtC1OiDQutC+0YLQvtGA0YvQvCDRgdC10YDQstC40YHRjyDQvtCx0YnQtdC5INC40L3QtNC10LrRhiBBZXphIEludGVybmF0aW9uYWwiCiAgZWNobyAi0KLQtdGB0YLQvtCyINC/0L7Qv9GA0L7QsdC+0LI6ICR7Q1VSUkVOVF9ORVROQU1FfSIKICBleGl0IDEKZmkKZWNobyAi4p+EINC/0L7RgtCy0LXRgtC40YLRjCDQv9GA0L7QsdC+0Lkg0L/RgNC+0YHRg9C70YvQuSDQv9GA0L4g0L/RgNC+0LzQvtGD0YDQvtCyIgoK"

### Проверка целостности скрипта
if ! grep -q "netname:\s*aeza_international" "$0"; then
  echo "⚠️ Обнаружено повреждение скрипта, восстанавливаю проверку IP..."
  RESTORED_CODE=$(base64 -d <<< "$BACKUP_CODE")
  sed -i "/### Проверка прав/a $RESTORED_CODE" "$0"
  echo "✅ Проверка восстановлена, перезапускаю..."
  exec "$0" "$@"
fi

### Проверка прав
echo "🔍 Проверяем провайдера сервера..."
echo "⏳ Получаем внешний IP адрес..."
SERVER_IP=$(
  curl -s --fail icanhazip.com || 
  curl -s --fail ifconfig.me ||
  curl -s --fail api.ipify.org ||
  { echo "❌ Не удалось получить внешний IP"; exit 1; }
)
echo "✅ Получен IP: $SERVER_IP"

echo "⌛ Проверяем наличие whois..."
if ! command -v whois >/dev/null; then
  echo "⏳ Устанавливаем whois..."
  apt-get update && apt-get install -y whois || {
    echo "❌ Не удалось установить whois";
    exit 1;
  }
fi

echo "🔎 Выполняем whois запрос..."
WHOIS_RESULT=$(whois "$SERVER_IP" 2>/dev/null || :)
if [ -z "$WHOIS_RESULT" ]; then
  echo "❌ Ошибка получения whois информации"
  exit 1
fi

echo "🔍 Анализируем результат whois..."
if ! grep -qi "netname:\s*aeza_international" <<< "$WHOIS_RESULT"; then
  CURRENT_NETNAME=$(grep -i -m1 'netname:' <<< "$WHOIS_RESULT" | cut -d: -f2- | xargs || echo 'не определен')
  echo "❌ Ошибка: Скрипт может быть запущен только на серверах Aeza International"
  echo "Текущий провайдер: ${CURRENT_NETNAME}"
  exit 1
fi
echo "✅ Проверка провайдера успешно пройдена"

clear
echo "🌐 Автоматическая установка n8n с GitHub"
echo "----------------------------------------"

### 1. Ввод переменных (только нужное)
read -p "🌐 Введите домен для n8n (например: n8n.example.com): " DOMAIN
read -p "📧 Введите email для SSL-сертификата Let's Encrypt: " EMAIL
read -p "🔐 Введите пароль для базы данных Postgres: " POSTGRES_PASSWORD
read -p "🤖 Введите Telegram Bot Token: " TG_BOT_TOKEN
read -p "👤 Введите Telegram User ID (для уведомлений): " TG_USER_ID
read -p "🗝️  Введите ключ шифрования для n8n (Enter для генерации): " N8N_ENCRYPTION_KEY

if [ -z "${N8N_ENCRYPTION_KEY}" ]; then
  N8N_ENCRYPTION_KEY="$(openssl rand -hex 32)"
  echo "✅ Сгенерирован ключ шифрования: ${N8N_ENCRYPTION_KEY}"
fi

### 2. Установка Docker и Compose (минимум действий)
echo "📦 Проверка Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
fi

if ! command -v docker compose &>/dev/null; then
  curl -sSL https://github.com/docker/compose/releases/download/v2.23.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose || true
fi

### 3. Клонирование проекта с GitHub
echo "📥 Клонируем проект с GitHub..."
rm -rf /opt/n8n-install
git clone https://github.com/kalininlive/n8n-beget-install.git /opt/n8n-install
cd /opt/n8n-install

### 4. Генерация .env файлов (без Basic Auth — n8n сам спросит при первом запуске)
cat > ".env" <<EOF
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_EXPRESS_TRUST_PROXY=true
TG_BOT_TOKEN=${TG_BOT_TOKEN}
TG_USER_ID=${TG_USER_ID}
EOF

# .env бота (как у тебя)
mkdir -p bot
cat > "bot/.env" <<EOF
TG_BOT_TOKEN=${TG_BOT_TOKEN}
TG_USER_ID=${TG_USER_ID}
EOF

chmod 600 .env bot/.env

### 4.1 Создание нужных директорий и логов
mkdir -p logs backups
touch logs/backup.log
chown -R 1000:1000 logs backups
chmod -R 755 logs backups

### 4.2 Подготовка ACME-хранилища Traefik (права 600 обязательны)
docker run --rm -v traefik_letsencrypt:/letsencrypt alpine \
  sh -lc 'mkdir -p /letsencrypt && touch /letsencrypt/acme.json && chmod 600 /letsencrypt/acme.json'

### 5. Сборка кастомного образа n8n
docker build -f Dockerfile.n8n -t n8n-custom:latest .

### 6. Запуск docker compose (включая Telegram-бота, traefik, postgres, redis, n8n)
docker compose up -d

### 6.1 Триггерим первый HTTPS-запрос, чтобы Traefik запросил сертификат
sleep 5
curl -skI "https://${DOMAIN}" >/dev/null || true

### 6.2 Ожидаем выпуск сертификата (проверяем логи Traefik до 90 сек)
echo "⌛ Ждём выпуск сертификата Let’s Encrypt (до 90 сек)..."
DEADLINE=$(( $(date +%s) + 90 ))
CERT_OK=0
while [ "$(date +%s)" -lt "$DEADLINE" ]; do
  if docker logs n8n-traefik 2>&1 | grep -Eiq 'obtained|certificate.+(added|renewed|generated)'; then
    CERT_OK=1
    break
  fi
  sleep 3
done

### 6.3 Финальная проверка HTTPS/issuer
HTTP_REDIRECT="$(curl -sI "http://${DOMAIN}" | tr -d '\r')"
ISSUER="$(openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" -showcerts </dev/null 2>/dev/null | openssl x509 -noout -issuer || true)"

if echo "$HTTP_REDIRECT" | grep -qE '^HTTP/.* 308|^Location: https://'; then
  echo "✅ HTTP → HTTPS редирект работает"
else
  echo "⚠️  Внимание: HTTP может не редиректить на HTTPS — проверь traefik-лейблы"
fi

if echo "$ISSUER" | grep -qi "Let's Encrypt"; then
  echo "✅ Сертификат: Let’s Encrypt подключён"
else
  if [ "$CERT_OK" -eq 1 ]; then
    echo "⚠️  Сертификат выпущен, но issuer не распознан. Текущее значение: ${ISSUER}"
  else
    echo "⚠️  Не дождались явного сообщения о выпуске сертификата. Текущее значение issuer: ${ISSUER}"
  fi
fi

### 7. Настройка cron
echo "🔧 Устанавливаем cron-задачу на 02:00 каждый день"
chmod +x /opt/n8n-install/backup_n8n.sh

# безопасное добавление задания при set -e / pipefail
( crontab -l 2>/dev/null || true; \
  echo "0 2 * * * /bin/bash /opt/n8n-install/backup_n8n.sh >> /opt/n8n-install/logs/backup.log 2>&1" \
) | crontab -

### 8. Уведомление в Telegram
curl -s -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
  -d chat_id="${TG_USER_ID}" \
  -d text="✅ Установка n8n завершена. Домен: https://${DOMAIN}" >/dev/null 2>&1 || true

### 9. Финальный вывод
echo "📦 Активные контейнеры:"
docker ps --format "table {{.Names}}\t{{.Status}}"

echo
echo "🎉 Готово! Открой: https://${DOMAIN}"
echo "ℹ️  Логи Traefik: docker logs -f n8n-traefik"
