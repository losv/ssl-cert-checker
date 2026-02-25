#!/bin/bash
set -euo pipefail

CERT_DIR="/opt/ssl-monitor/certs"
LOG_FILE="/var/log/check_cert.log"
# Get current date in seconds (Unix timestamp)
NOW_SECONDS=$(date +%s)
TW=30 # Threshold Warning (days)
TC=0  # Threshold Critical (days)

# === LOGGING FUNCTION ===
log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

# Check if the certificate directory exists
if [ ! -d "$CERT_DIR" ]; then
    echo "[ERROR] Directory $CERT_DIR was not found!!"
    log_message "[ERROR] Directory $CERT_DIR was not found!"
    exit 1
fi

# === PATH TO CONFIG ===
CONFIG_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config/config.conf"

# 1. Check if the config object exists and is a regular FILE (-f)
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] Config file not found: $CONFIG_FILE !"
    log_message "[ERROR] Config file not found: $CONFIG_FILE"
    exit 1
fi

# 2. Check for READ permissions (-r)
if [ ! -r "$CONFIG_FILE" ]; then
    echo "[ERROR] No rights to read the file: $CONFIG_FILE"
    log_message "[ERROR] No rights to read the file: $CONFIG_FILE"
    exit 1
fi

# Load configuration variables (TELEGRAM_TOKEN, etc.)
source "$CONFIG_FILE"

# Alerting function: send_alert
send_alert() {
    local level="$1"
    local NameSite="$2"
    local Days="$3"

    local emoji
    case "$level" in
        CRITICAL) emoji="🔴" ;;
        WARNING)  emoji="🟡" ;;
    esac

    local message=""
    message="${emoji} [${level}] ${emoji} %0A%0A"
    message+="Time: $(date '+%Y-%m-%d %H:%M:%S') %0A%0A"
    message+="NAME site: $NameSite %0A%0A"
    message+="DETAILS: $Days %0A%0A"
    message+="Server: $(hostname)%0A" 

    curl -s --max-time 10 \
        "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=HTML" > /dev/null 2>&1
}

log_message "=== Check certs started ==="

# 1. Check if openssl is installed
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is not installed."
    log_message "Error: openssl is not installed!"
    exit 1
fi

echo "Checking certificates in $CERT_DIR:"
echo "------------------------------------"

# 2. Main validation loop
shopt -s nullglob
for cert in "$CERT_DIR"/*.{crt,pem,cer}; do

    # Attempt to read certificate data and verify its validity
    if DATA=$(openssl x509 -in "$cert" -noout -subject -enddate -nameopt RFC2253 2>/dev/null); then
        # Extract CN (Common Name) from the first line
        SUBJECT=$(echo "$DATA" | sed -n 's/.*CN=\([^,]*\).*/\1/p')
        # Extract expiration date from the output (remove "notAfter=")
        END_DATE=$(echo "$DATA" | grep "notAfter" | cut -d= -f2)
        # Convert expiration date to seconds
        END_SECONDS=$(date -d "$END_DATE" +%s)
        
        # Calculate the difference in days
        DIFF_SECONDS=$((END_SECONDS - NOW_SECONDS))
        DIFF_DAYS=$((DIFF_SECONDS / 86400))
    
        if [ "$DIFF_SECONDS" -lt "$TC" ]; then
            STATUS="[CRITICAL] Certificate ${DIFF_DAYS#-} days overdue."
            echo "[CRITICAL] : $SUBJECT"
            log_message "[CRITICAL] Certificate ${SUBJECT} ${DIFF_DAYS#-} days overdue."
            send_alert "CRITICAL" "$SUBJECT" "days overdue: ${DIFF_DAYS#-}"
            
        elif [ "$DIFF_DAYS" -lt "$TW" ]; then
            STATUS="[WARNING] Certificate $DIFF_DAYS days validity left."
            echo "[WARNING] Certificate ${SUBJECT} $DIFF_DAYS days validity left."
            log_message "[WARNING] Certificate ${SUBJECT} $DIFF_DAYS days validity left."
            send_alert "WARNING" "$SUBJECT" "days left: $DIFF_DAYS"
        else
            echo "[OK] Certificate $SUBJECT is valid for $DIFF_DAYS days."
        fi
        
    else
        # Handle invalid or corrupted certificate files
        log_message "[CRITICAL] Certificate ${cert} cannot be read!"
        echo "[CRITICAL] Certificate ${cert} cannot be read!"
        send_alert "CRITICAL" "$(basename "$cert")" "File is corrupted or not a certificate" 
    fi
    
done

log_message "=== Check certs completed ==="
