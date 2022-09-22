#/usr/bin/env bash
set -eu

: "${UNIT_NAME:=saturn-monitoring}"

# dependency
sudo apt update
sudo apt install curl

# binary
mkdir -p /opt/bin
sudo cp saturn-monitoring.sh /opt/bin/"${UNIT_NAME}"
sudo chmod ugo+x /opt/bin/"${$UNIT_NAME}"

# service
sudo dd of="/etc/systemd/system/$UNIT_NAME.service" <<EOF
[Unit]
After=network-online.target
Requires=network-online.target
[Service]
Environment=TELEGRAM_API_KEY="${TELEGRAM_API_KEY}"
Environment=TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"
Environment=TARGET_NAME="${TARGET_NAME}"
Environment=TARGET_URL="${TARGET_URL}"
Environment=TARGET_METHOD="${TARGET_METHOD:-GET}"
Environment=TARGET_REQUIRE_2XX="${TARGET_REQUIRE_2XX:-true}"
Environment=CHECK_INTERVAL="${CHECK_INTERVAL:-60}"
Environment=CHECK_DAILY_PING="${CHECK_DAILY_PING:-true}"
User=$USER
Group=$USER
Restart=always
ExecStart=/opt/bin/saturn-monitoring
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "${$UNIT_NAME}"
sudo systemctl stop   "${$UNIT_NAME}"
sudo systemctl start  "${$UNIT_NAME}"