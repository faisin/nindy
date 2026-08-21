#!/bin/bash
# Install & Restart Nginx
echo "Memasang Nginx..."

# Update dan Install Nginx
apt-get update -y
apt-get install -y nginx

# Pastikan Nginx berjalan di port 80 dan 443
systemctl stop apache2 >/dev/null 2>&1 || true
systemctl disable apache2 >/dev/null 2>&1 || true

# Aktifkan dan restart Nginx
systemctl enable nginx
systemctl restart nginx

# Cek status
if systemctl is-active --quiet nginx; then
    echo "Nginx berhasil dijalankan."
else
    echo "Nginx gagal dijalankan, cek error dengan: systemctl status nginx"
fi
