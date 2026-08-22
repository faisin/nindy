#!/bin/bash
# ==========================================
# Installer Nginx Web Server
# ==========================================

echo -e "\033[0;34m[*] Menginstal Nginx Web Server...\033[0m"

apt update && apt install -y nginx

# Buat folder web root jika belum ada
mkdir -p /var/www/html

# Konfigurasi service Nginx
systemctl daemon-reload
systemctl enable nginx
systemctl start nginx

echo -e "\033[0;32m[✓] Nginx berhasil diinstal dan dijalankan!\033[0m"
