#!/bin/bash
# ==========================================
# REBUILD ZIVPN CONFIG - by znandev
# ==========================================
set -e

DB="/etc/zivpn/users.db"
CONFIG="/etc/zivpn/config.json"

# Pastikan direktori config dan database tersedia
mkdir -p /etc/zivpn
touch "$DB"

# Ambil daftar user dari database dan format menjadi array JSON strings
USERS=$(awk '{print "\"" $1 "\""}' "$DB" 2>/dev/null | paste -sd "," -)

if [[ -z "$USERS" ]]; then
    USERS='"testuser"'
fi

# Tulis ulang berkas konfigurasi JSON
cat > "$CONFIG" <<EOF
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": [ $USERS ]
  }
}
EOF

# Validasi file config sebelum restart layanan
if command -v jq &> /dev/null; then
    if ! jq empty "$CONFIG" >/dev/null 2>&1; then
        echo "ERROR: Generated ZIVPN config is invalid JSON!"
        exit 1
    fi
fi

# Restart layanan ZIVPN
systemctl restart zivpn

if systemctl is-active --quiet zivpn; then
    echo "✅ ZIVPN configuration rebuilt and service restarted successfully."
else
    echo "❌ ERROR: ZIVPN service failed to start after rebuilding config!"
    exit 1
fi

