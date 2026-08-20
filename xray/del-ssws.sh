#!/bin/bash
# Hapus akun SS WS - by znandev
set -e

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m      Delete Shadowsocks Account   \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Input username dengan validasi
until [[ $user =~ ^[a-zA-Z0-9_]+$ ]]; do
    read -rp "Masukkan username yang ingin dihapus: " user
done

config="/etc/xray/config.json"
db_file="/etc/xray/ssws.db"

# Cek apakah user ada di config.json
CLIENT_EXISTS=$(jq -r '.inbounds[].settings.clients[]?.email' "$config" 2>/dev/null | grep -w "$user" | wc -l)

if [[ ${CLIENT_EXISTS} == '0' ]]; then
    echo -e "\n\033[1;31m❌ Akun '$user' tidak ditemukan di dalam konfigurasi!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."
    menu
fi

# Backup config
cp "$config" "${config}.bak"

# Temp file untuk jq
tmpfile=$(mktemp)

# Hapus user dari inbounds Shadowsocks menggunakan jq
if ! jq --arg user "$user" '
(.inbounds[] | select(.tag=="ssws-ws-tls").settings.clients) |= [ .[] | select(.email != $user) ] |
(.inbounds[] | select(.tag=="ssws-ws-nontls").settings.clients) |= [ .[] | select(.email != $user) ] |
(.inbounds[] | select(.tag=="ssws-grpc").settings.clients) |= [ .[] | select(.email != $user) ]
' "$config" > "$tmpfile"; then
    echo -e "\n\033[1;31mERROR: Gagal memproses konfigurasi dengan jq!\033[0m"
    rm -f "$tmpfile"
    exit 1
fi

# Validasi hasil file json sementara
if ! jq empty "$tmpfile" >/dev/null 2>&1; then
    echo -e "\n\033[1;31mERROR: Hasil konfigurasi JSON tidak valid!\033[0m"
    rm -f "$tmpfile"
    exit 1
fi

# Timpa config lama
mv "$tmpfile" "$config"

# Test konfigurasi Xray
if ! xray -test -config "$config" >/dev/null 2>&1; then
    echo -e "\n\033[1;31mERROR: Tes konfigurasi Xray gagal! Mengembalikan cadangan...\033[0m"
    cp "${config}.bak" "$config"
    exit 1
fi

# Restart layanan Xray
systemctl restart xray

# Hapus data dari database lokal jika ada
if [ -f "$db_file" ]; then
    grep -v "^$user " "$db_file" > "${db_file}.tmp" && mv "${db_file}.tmp" "$db_file"
fi

echo -e "\n\033[1;32m✅ Akun '$user' berhasil dihapus dari SS WS!\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu utama
menu

