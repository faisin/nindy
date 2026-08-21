#!/bin/bash
# Install SSH WS
echo "Memasang SSH WS..."

# Membuat file service dropbearws
cat > /etc/systemd/system/dropbearws.service <<EOF
[Unit]
Description=Dropbear WS Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/dropbearws
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Membuat file service stunnelws
cat > /etc/systemd/system/stunnelws.service <<EOF
[Unit]
Description=Stunnel WS Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/stunnelws
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable dropbearws stunnelws
systemctl restart dropbearws stunnelws
echo "SSH WS terpasang dan dijalankan."
