markdown
# SSL Certificate Expiry Checker

A lightweight Bash script to monitor local SSL certificates, log their status, and send instant alerts to **Telegram** if they are expiring soon or already expired.

## Features
-  **Multi-format support**: Scans `.crt`, `.pem`, and `.cer` files.
-  **Dependency Check**: Automatically verifies if `openssl` is installed.
-  **Error Handling**: Skips corrupted or invalid certificate files without crashing.
-  **Telegram Notifications**: Sends Critical/Warning alerts with emojis.
-  **Detailed Logging**: Keeps track of all checks in `/var/log/check_cert.log`.

## Prerequisites
- Linux OS (Ubuntu, Debian, CentOS, etc.)
- `openssl` installed.
- `curl` installed (for Telegram alerts).

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com
   cd ssl-cert-checker
Используйте код с осторожностью.

Configure the directory:
By default, the script looks for certificates in /root/test/cert/certs/cert/.
Recommendation: Change CERT_DIR in the script to /opt/ssl-monitor/certs/ for better accessibility.
Setup Config:
Create a config/config.conf file:
bash
mkdir config
nano config/config.conf
Используйте код с осторожностью.

Add your Telegram credentials:
bash
TELEGRAM_TOKEN="your_bot_token_here"
TELEGRAM_CHAT_ID="your_chat_id_here"
Используйте код с осторожностью.

Set Permissions:
bash
chmod +x check_certs.sh
Используйте код с осторожностью.

Usage
Run the script manually:
bash
./check_certs.sh
Используйте код с осторожностью.

Automation (Cron)
To check certificates daily at 09:00 AM, add this to your crontab -e:
cron
0 9 * * * /path/to/your/check_certs.sh
Используйте код с осторожностью.


