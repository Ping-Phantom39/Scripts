#!/bin/bash
# SSL Certificate Monitor
# Checks SSL certificates and alerts before expiration

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Config
ALERT_DAYS=30
LOG_FILE="/var/log/ssl-monitor.log"

# Domains to check - add your domains here
DOMAINS=(
    "google.com"
    "github.com"
    # Add your domains:
    # "yourdomain.com"
    # "api.yourdomain.com"
)

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

get_expiry_days() {
    local domain="$1"
    local expiry
    
    # Try to get certificate expiry date
    expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
        openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    
    if [ -z "$expiry" ]; then
        echo "-1"
        return
    fi
    
    # Calculate days until expiry
    expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null)
    now_epoch=$(date +%s)
    days=$(( (expiry_epoch - now_epoch) / 86400 ))
    
    echo "$days"
}

get_cert_info() {
    local domain="$1"
    
    echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
        openssl x509 -noout -subject -issuer 2>/dev/null
}

# Main
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}     SSL CERTIFICATE MONITOR${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}Alert threshold: ${ALERT_DAYS} days${NC}\n"

ISSUES=0

for domain in "${DOMAINS[@]}"; do
    echo -e "${BOLD}Checking: ${domain}${NC}"
    
    days=$(get_expiry_days "$domain")
    
    if [ "$days" -eq "-1" ]; then
        echo -e "  ${RED}✗ Could not fetch certificate${NC}"
        log_message "ERROR: Could not fetch certificate for $domain"
        ISSUES=$((ISSUES + 1))
        continue
    fi
    
    # Status based on days remaining
    if [ $days -lt 0 ]; then
        echo -e "  ${RED}✗ EXPIRED!${NC}"
        log_message "CRITICAL: Certificate for $domain has EXPIRED"
        ISSUES=$((ISSUES + 1))
    elif [ $days -lt 7 ]; then
        echo -e "  ${RED}✗ CRITICAL: ${days} days remaining${NC}"
        log_message "CRITICAL: Certificate for $domain expires in $days days"
        ISSUES=$((ISSUES + 1))
    elif [ $days -lt $ALERT_DAYS ]; then
        echo -e "  ${YELLOW}! WARNING: ${days} days remaining${NC}"
        log_message "WARNING: Certificate for $domain expires in $days days"
    else
        echo -e "  ${GREEN}✓ OK: ${days} days remaining${NC}"
    fi
    
    # Show cert details
    if [ "$days" -gt -1 ]; then
        subject=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
            openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')
        issuer=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
            openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')
        
        echo "  Subject: $subject"
        echo "  Issuer: $issuer"
    fi
    
    echo ""
done

# Summary
echo -e "${CYAN}════════════════════════════════════════${NC}"
if [ $ISSUES -gt 0 ]; then
    echo -e "${RED}⚠️  $ISSUES certificate(s) need attention${NC}"
else
    echo -e "${GREEN}✓ All certificates are valid${NC}"
fi
echo -e "${CYAN}════════════════════════════════════════${NC}"

# To add cron job (weekly check):
# 0 0 * * 0 /home/ubuntu/Scripts/ssl-monitor.sh