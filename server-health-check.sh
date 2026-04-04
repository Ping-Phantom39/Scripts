#!/bin/bash
# Server Health Check Script
# Comprehensive system health monitoring with alerts

# Config
LOG_FILE="/var/log/server-health.log"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEM=85
ALERT_THRESHOLD_DISK=90

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Alert tracking file
ALERT_FILE="/tmp/server-health-alerts"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

send_alert() {
    local level="$1"
    local message="$2"
    
    # Log the alert
    log_message "[$level] $message"
    
    # Check if we already sent this alert recently (within 1 hour)
    local alert_key=$(echo "$message" | md5sum | cut -d' ' -f1)
    local alert_file="$ALERT_FILE/$alert_key"
    
    if [ -f "$alert_file" ]; then
        local last_alert=$(cat "$alert_file")
        local now=$(date +%s)
        local diff=$((now - last_alert))
        
        if [ $diff -lt 3600 ]; then
            return  # Skip duplicate alert within 1 hour
        fi
    fi
    
    # Mark alert as sent
    mkdir -p "$ALERT_FILE"
    date +%s > "$alert_file"
    
    # Send notification (using notify-send if available, or just log)
    if command -v notify-send &> /dev/null; then
        notify-send "Server Alert [$level]" "$message"
    fi
    
    echo -e "${RED}⚠️  ALERT [$level]: $message${NC}"
}

# Initialize
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
mkdir -p "$ALERT_FILE" 2>/dev/null

echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}       SERVER HEALTH CHECK${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""

ISSUES=0

# Check CPU
echo -e "${CYAN}[CPU Check]${NC}"
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1 2>/dev/null || echo "100")
CPU_USED=$(echo "100 - $CPU_IDLE" | bc 2>/dev/null || echo "0")

if (( $(echo "$CPU_USED > $ALERT_THRESHOLD_CPU" | bc -l) )); then
    send_alert "CRITICAL" "CPU usage is ${CPU_USED}% (threshold: ${ALERT_THRESHOLD_CPU}%)"
    ISSUES=$((ISSUES + 1))
else
    echo -e "  ${GREEN}✓${NC} CPU usage: ${CPU_USED}%"
fi

# Check top CPU processes
echo "  Top processes:"
ps -eo comm,%cpu --sort=-%cpu | head -4 | tail -3 | while read proc cpu; do
    printf "    - %-20s %s%%\n" "$proc" "$cpu"
done

# Check Memory
echo -e "\n${CYAN}[Memory Check]${NC}"
MEM_INFO=$(free -m | grep "Mem:")
MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
MEM_PERCENT=$(echo "scale=1; $MEM_USED * 100 / $MEM_TOTAL" | bc)

if (( $(echo "$MEM_PERCENT > $ALERT_THRESHOLD_MEM" | bc -l) )); then
    send_alert "WARNING" "Memory usage is ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
    ISSUES=$((ISSUES + 1))
else
    echo -e "  ${GREEN}✓${NC} Memory usage: ${MEM_PERCENT}% (${MEM_USED}MB/${MEM_TOTAL}MB)"
fi

# Check Swap
SWAP_INFO=$(free -m | grep "Swap:")
SWAP_TOTAL=$(echo $SWAP_INFO | awk '{print $2}')
SWAP_USED=$(echo $SWAP_INFO | awk '{print $3}')
if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_PERCENT=$(echo "scale=1; $SWAP_USED * 100 / $SWAP_TOTAL" | bc)
    if (( $(echo "$SWAP_USED > 0" | bc -l) )); then
        echo -e "  ${YELLOW}!${NC} Swap in use: ${SWAP_USED}MB (${SWAP_PERCENT}%)"
    else
        echo -e "  ${GREEN}✓${NC} Swap: Not in use"
    fi
fi

# Check Disk Space
echo -e "\n${CYAN}[Disk Check]${NC}"
df -h --output=source,size,used,pcent,target 2>/dev/null | grep -E "^/dev" | while read dev size used pcent mount; do
    PERCENT=$(echo $pcent | tr -d '%')
    
    if [ $PERCENT -gt $ALERT_THRESHOLD_DISK ]; then
        send_alert "CRITICAL" "Disk $mount is ${PERCENT}% full"
        ISSUES=$((ISSUES + 1))
        echo -e "  ${RED}✗${NC} $mount: ${PERCENT}% full (${used}/${size})"
    elif [ $PERCENT -gt 70 ]; then
        echo -e "  ${YELLOW}!${NC} $mount: ${PERCENT}% full (${used}/${size})"
    else
        echo -e "  ${GREEN}✓${NC} $mount: ${PERCENT}% full (${used}/${size})"
    fi
done

# Check Critical Services
echo -e "\n${CYAN}[Services Check]${NC}"
CRITICAL_SERVICES="ssh docker nginx"

for service in $CRITICAL_SERVICES; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $service is running"
    elif command -v "$service" &> /dev/null; then
        echo -e "  ${YELLOW}-${NC} $service is not active"
    fi
done

# Check Network Connectivity
echo -e "\n${CYAN}[Network Check]${NC}"
INTERNET_HOSTS="8.8.8.8 1.1.1.1"
CONNECTED=false

for host in $INTERNET_HOSTS; do
    if ping -c 1 -W 2 "$host" &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Internet connectivity OK (via $host)"
        CONNECTED=true
        break
    fi
done

if [ "$CONNECTED" = false ]; then
    send_alert "CRITICAL" "No internet connectivity"
    echo -e "  ${RED}✗${NC} No internet connectivity"
    ISSUES=$((ISSUES + 1))
fi

# Check Docker (if installed)
if command -v docker &> /dev/null; then
    echo -e "\n${CYAN}[Docker Check]${NC}"
    
    # Check Docker daemon
    if docker info &> /dev/null; then
        RUNNING=$(docker ps -q | wc -l)
        STOPPED=$(docker ps -aq --filter "status=exited" | wc -l)
        echo -e "  ${GREEN}✓${NC} Docker daemon running"
        echo -e "    Running: ${RUNNING}, Stopped: ${STOPPED}"
        
        # Check for unhealthy containers
        for container in $(docker ps --format "{{.Names}}"); do
            HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)
            if [ "$HEALTH" = "unhealthy" ]; then
                send_alert "WARNING" "Docker container $container is unhealthy"
                echo -e "    ${RED}✗${NC} $container is unhealthy"
            fi
        done
    else
        send_alert "WARNING" "Docker daemon is not responding"
        echo -e "  ${RED}✗${NC} Docker daemon not responding"
    fi
fi

# Check for failed login attempts (last 10 min)
echo -e "\n${CYAN}[Security Check]${NC}"
if [ -f /var/log/auth.log ]; then
    FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log 2>/dev/null | \
        grep "$(date '+%b %d')" | wc -l)
    
    if [ $FAILED_LOGINS -gt 10 ]; then
        send_alert "WARNING" "High number of failed login attempts: $FAILED_LOGINS"
        echo -e "  ${RED}✗${NC} Failed logins today: $FAILED_LOGINS"
    else
        echo -e "  ${GREEN}✓${NC} Failed logins today: $FAILED_LOGINS"
    fi
fi

# Summary
echo -e "\n${CYAN}════════════════════════════════════════${NC}"
if [ $ISSUES -gt 0 ]; then
    echo -e "${RED}⚠️  $ISSUES issue(s) detected${NC}"
    log_message "Health check completed with $ISSUES issue(s)"
else
    echo -e "${GREEN}✓ All systems healthy${NC}"
    log_message "Health check completed - all systems healthy"
fi
echo -e "${CYAN}════════════════════════════════════════${NC}"