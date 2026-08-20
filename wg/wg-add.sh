#!/bin/bash
# Tambah akun WireGuard - by znandev
set -e

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m       Add WireGuard Account       \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

[[ -f /etc/wireguard/wg0.conf ]] || {
    echo -e "\033[1;31m❌ WireGuard is not installed!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
}

# Input username dengan validasi
until [[ $user =~ ^[a-zA-Z0-9_-]+$ ]]; do
    read -rp "Masukkan nama user : " user
done

if grep -q "^# $user$" /etc/wireguard/wg0.conf; then
    echo -e "\n\033[1;31m❌ User already exists!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
fi

priv_key=$(wg genkey)
pub_key=$(echo "$priv_key" | wg pubkey)
psk=$(wg genpsk)

last_ip=$(grep "^AllowedIPs = 10\.66\.66\." /etc/wireguard/wg0.conf \
    | tail -n1 \
    | awk '{print $3}' \
    | cut -d'.' -f4 \
    | cut -d'/' -f1)

if [[ -z "$last_ip" ]]; then
    last_ip=1
fi

next_ip=$((last_ip + 1))

if (( next_ip > 254 )); then
    echo -e "\n\033[1;31m❌ IP pool exhausted!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
fi

client_ip="10.66.66.${next_ip}/32"

# Buat folder klien
mkdir -p /etc/wireguard/clients
client_config="/etc/wireguard/clients/$user.conf"

# Ambil info server
server_ip=$(curl -s --max-time 5 ipv4.icanhazip.com || curl -s --max-time 5 ifconfig.me)

[[ -z "$server_ip" ]] && {
    echo -e "\n\033[1;31m❌ Failed to get server IP!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
}

server_port=$(grep ListenPort /etc/wireguard/wg0.conf | awk '{print $3}')
server_pubkey=$(wg show wg0 public-key)

# Tambah ke config server
echo -e "\n# $user\n[Peer]\nPublicKey = $pub_key\nPresharedKey = $psk\nAllowedIPs = $client_ip" >> /etc/wireguard/wg0.conf

# Buat config klien
cat > "$client_config" <<EOF
[Interface]
PrivateKey = $priv_key
Address = $client_ip
DNS = 1.1.1.1

[Peer]
PublicKey = $server_pubkey
PresharedKey = $psk
Endpoint = $server_ip:$server_port
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

if command -v qrencode &> /dev/null; then
    qrencode -o "/etc/wireguard/clients/${user}.png" < "$client_config"
fi

wg-quick strip wg0 >/dev/null 2>&1 || {
    echo -e "\n\033[1;31m❌ Invalid WireGuard configuration!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
}

# Apply config
systemctl restart wg-quick@wg0
sleep 2

systemctl is-active --quiet wg-quick@wg0 || {
    echo -e "\n\033[1;31m❌ WireGuard failed to restart!\033[0m"
    echo ""
    read -n 1 -s -r -p "Tekan apa saja untuk kembali..."
    m-wg
}

clear
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[44;1;39m      WireGuard Account Created    \E[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\n\033[1;32m✅ Akun WireGuard '$user' berhasil dibuat!\033[0m"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "📄 Config Path : ${client_config}\n"
cat "$client_config"

echo -e "\n\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "📷 QR Code (scan via WireGuard app):"
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
if command -v qrencode &> /dev/null; then
    qrencode -t ansiutf8 < "$client_config"
else
    echo "qrencode tidak terinstall."
fi
echo -e "\033[0;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""

read -n 1 -s -r -p "Tekan apa saja untuk kembali ke menu..."

# Kembali ke menu WireGuard
m-wg

