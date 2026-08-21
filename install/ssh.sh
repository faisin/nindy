#!/bin/bash
# ==========================================
# Install SSH WS & WSS - by znandev
# ==========================================
echo "Memasang SSH WS dan WSS..."

# 1. Pastikan binary go ws tersedia atau buat service-nya langsung
cat > /etc/systemd/system/dropbearws.service <<EOF
[Unit]
Description=Dropbear WS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dropbearws
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/stunnelws.service <<EOF
[Unit]
Description=Stunnel WS Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/stunnelws
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

# Reload dan jalankan
systemctl daemon-reload
systemctl enable dropbearws stunnelws
systemctl restart dropbearws stunnelws

echo "SSH WS dan WSS berhasil dikonfigurasi."
