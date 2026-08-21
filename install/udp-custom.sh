#!/bin/bash
# ==========================================
# Install UDP Custom Service - by znandev
# ==========================================
echo "Memasang UDP Custom..."

mkdir -p /etc/udp-custom

if [[ -f "./udp-custom" ]]; then
    cp ./udp-custom /usr/local/bin/udp-custom
    chmod +x /usr/local/bin/udp-custom
fi

if [[ ! -f /etc/udp-custom/config.json ]]; then
    cat > /etc/udp-custom/config.json <<EOF
{
  "listen": ":36712",
  "stream_buffer": 2097152,
  "receive_buffer": 1048576
}
EOF
fi

cat > /etc/systemd/system/udp-custom.service <<EOF
[Unit]
Description=UDP Custom Service - by znandev
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-custom
ExecStart=/usr/local/bin/udp-custom server -c /etc/udp-custom/config.json -exclude 7300
Restart=always
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl restart udp-custom

echo "UDP Custom berhasil dipasang."
