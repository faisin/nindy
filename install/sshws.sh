#!/bin/bash
# ==========================================
# Install SSH WebSocket Service
# ==========================================

# Pastikan port 8080 terbuka (opsional, tergantung kebutuhan)
# Jika Anda menggunakan Python sebagai proxy sederhana:
cat > /etc/systemd/system/sshws.service <<EOF
[Unit]
Description=SSH WebSocket Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# Jalankan service
systemctl daemon-reload
systemctl enable sshws
systemctl restart sshws

echo "SSH WebSocket (SSH WS) berhasil diinstal."

