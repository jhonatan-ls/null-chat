#!/bin/bash
set -euo pipefail

# Configurações
DB_NAME="${DB_NAME:-nullchat}"
DB_USER="${DB_USER:-postgres}"
DB_HOST="${DB_HOST:-localhost}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="$BACKUP_DIR/backup_$DATE.zip"
DUMP_FILE="$BACKUP_DIR/db_$DATE.dump"

if [ -z "${PGPASSWORD:-}" ]; then
  echo "ERRO: PGPASSWORD não definida. Carregue o .env antes de rodar:" >&2
  echo "  set -a; source .env; set +a" >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

echo "Iniciando backup em $DATE..."

pg_dump -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" -F c -f "$DUMP_FILE"

if [ -d "./uploads" ] && [ "$(ls -A ./uploads 2>/dev/null)" ]; then
  zip -r "$FILENAME" "$DUMP_FILE" "./uploads/" > /dev/null
else
  echo "Aviso: ./uploads vazio ou inexistente, backup só do banco." >&2
  zip -r "$FILENAME" "$DUMP_FILE" > /dev/null
fi

chmod 600 "$FILENAME"
rm -f "$DUMP_FILE"

if [ ! -s "$FILENAME" ]; then
  echo "ERRO: backup não foi criado ou está vazio." >&2
  exit 1
fi

find "$BACKUP_DIR" -name "backup_*.zip" -mtime +"$RETENTION_DAYS" -delete

echo "Backup concluído: $FILENAME ($(du -h "$FILENAME" | cut -f1))"
