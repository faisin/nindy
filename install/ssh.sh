#!/bin/bash
# ==========================================
# Installer Modul SSH & Dropbear
# ==========================================

# Sumber helper warna (jika dijalankan terpisah)
[ -f "../tools/helper.sh" ] && source ../tools/helper.sh

echo -e "\033[0;34m[*] Mengonfigurasi SSH dan Dropbear...\033[0m"

# Update dan instal Dropbear
apt update && apt install -y dropbear

# Konfigurasi port Dropbear (Port 443 dan 109)
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=""/DROPBEAR_EXTRA_ARGS="-p 109 -p 443"/g' /etc/default/dropbear

# Buat banner / issue.net jika ada di config
if [ -f "./config/issue.net" ]; then
    cp ./config/issue.net /etc/issue.net
    sed -i 's/^Banner.*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config
fi

# Restart layanan SSH dan Dropbear
systemctl restart ssh
systemctl restart dropbear
systemctl enable dropbear

echo -e "\033[0;32m[✓] SSH & Dropbear berhasil dikonfigurasi!\033[0m"
