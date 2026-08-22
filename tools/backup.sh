#!/bin/bash
# ==========================================
# Utilitas Backup VPS - Nindy VPS
# ==========================================

clear
echo -e "\033[0;36m==========================================\033[0m"
echo -e "\033[0;32m            SISTEM BACKUP VPS             \033[0m"
echo -e "\033[0;36m==========================================\033[0m"
echo -e "\033[0;33m[*] Memproses pencadangan data sistem...\033[0m"

# Tentukan direktori backup
BACKUP_DIR="/root/backup"
mkdir -p $BACKUP_DIR
DATE=$(date +"%Y-%m-%d")
FILE_NAME="backup-$DATE.zip"

# Kompres folder konfigurasi penting
zip -r "$BACKUP_DIR/$FILE_NAME" /etc/xray /etc/default/dropbear /root/nindy/config > /dev/null 2>&1

if [ -f "$BACKUP_DIR/$FILE_NAME" ]; then
    echo -e "\033[0;32m[✓] Backup berhasil disimpan di: $BACKUP_DIR/$FILE_NAME\033[0m"
else
    echo -e "\033[0;31m[X] Gagal melakukan backup data!\033[0m"
fi

read -p "Tekan [Enter] untuk kembali..."
