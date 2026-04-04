#!/bin/bash
# System Resources Monitor
# Displays CPU, Memory, Disk, and Network usage in a clean format

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

clear
echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC} ${BOLD}${CYAN}SYSTEM RESOURCES MONITOR${NC}                              ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} $(date '+%Y-%m-%d %H:%M:%S')                                      ${PURPLE}║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"

# Hostname and Uptime
echo -e "\n${BOLD}${BLUE}━━━ SYSTEM INFO ━━━${NC}"
echo -e "  ${CYAN}Hostname:${NC} $(hostname)"
echo -e "  ${CYAN}Uptime:${NC} $(uptime -p | sed 's/up //')"

# CPU Usage
echo -e "\n${BOLD}${BLUE}━━━ CPU ━━━${NC}"
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)
CPU_USED=$(echo "100 - $CPU_IDLE" | bc)
CPU_CORES=$(nproc)
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')

# CPU bar
CPU_BAR_WIDTH=30
CPU_FILLED=$(echo "scale=0; $CPU_USED * $CPU_BAR_WIDTH / 100" | bc)
CPU_EMPTY=$((CPU_BAR_WIDTH - CPU_FILLED))

printf "  Usage: ["
for ((i=0; i<CPU_FILLED; i++)); do
    if (( CPU_USED > 80 )); then
        printf "${RED}█${NC}"
    elif (( CPU_USED > 50 )); then
        printf "${YELLOW}█${NC}"
    else
        printf "${GREEN}█${NC}"
    fi
done
for ((i=0; i<CPU_EMPTY; i++)); do
    printf "░"
done
printf "] ${CPU_USED}%\n"

echo -e "  Cores: ${GREEN}${CPU_CORES}${NC}"
echo -e "  Load Avg:${LOAD_AVG}"

# Memory Usage
echo -e "\n${BOLD}${BLUE}━━━ MEMORY ━━━${NC}"
MEM_INFO=$(free -m | grep "Mem:")
MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
MEM_FREE=$(echo $MEM_INFO | awk '{print $4}')
MEM_AVAIL=$(echo $MEM_INFO | awk '{print $7}')
MEM_PERCENT=$(echo "scale=1; $MEM_USED * 100 / $MEM_TOTAL" | bc)

# Memory bar
MEM_BAR_WIDTH=30
MEM_FILLED=$(echo "scale=0; $MEM_USED * $MEM_BAR_WIDTH / $MEM_TOTAL" | bc)
MEM_EMPTY=$((MEM_BAR_WIDTH - MEM_FILLED))

printf "  Usage: ["
for ((i=0; i<MEM_FILLED; i++)); do
    if (( $(echo "$MEM_PERCENT > 80" | bc -l) )); then
        printf "${RED}█${NC}"
    elif (( $(echo "$MEM_PERCENT > 50" | bc -l) )); then
        printf "${YELLOW}█${NC}"
    else
        printf "${GREEN}█${NC}"
    fi
done
for ((i=0; i<MEM_EMPTY; i++)); do
    printf "░"
done
printf "] ${MEM_PERCENT}%\n"

echo -e "  Used: ${YELLOW}${MEM_USED}MB${NC} / Total: ${GREEN}${MEM_TOTAL}MB${NC}"
echo -e "  Available: ${GREEN}${MEM_AVAIL}MB${NC}"

# Swap
SWAP_INFO=$(free -m | grep "Swap:")
SWAP_TOTAL=$(echo $SWAP_INFO | awk '{print $2}')
SWAP_USED=$(echo $SWAP_INFO | awk '{print $3}')
if [ "$SWAP_TOTAL" -gt 0 ]; then
    SWAP_PERCENT=$(echo "scale=1; $SWAP_USED * 100 / $SWAP_TOTAL" | bc)
    echo -e "  Swap: ${SWAP_USED}MB / ${SWAP_TOTAL}MB (${SWAP_PERCENT}%)"
else
    echo -e "  Swap: ${GREEN}Disabled${NC}"
fi

# Disk Usage
echo -e "\n${BOLD}${BLUE}━━━ DISK ━━━${NC}"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E "^/dev" | while read line; do
    DISK_NAME=$(echo $line | awk '{print $1}')
    DISK_SIZE=$(echo $line | awk '{print $2}')
    DISK_USED=$(echo $line | awk '{print $3}')
    DISK_AVAIL=$(echo $line | awk '{print $4}')
    DISK_PERCENT=$(echo $line | awk '{print $5}' | tr -d '%')
    DISK_MOUNT=$(echo $line | awk '{print $6}')

    # Disk bar
    DISK_BAR_WIDTH=20
    DISK_FILLED=$((DISK_PERCENT * DISK_BAR_WIDTH / 100))
    DISK_EMPTY=$((DISK_BAR_WIDTH - DISK_FILLED))

    printf "  ${CYAN}%-12s${NC} [" "$DISK_MOUNT"
    for ((i=0; i<DISK_FILLED; i++)); do
        if (( DISK_PERCENT > 85 )); then
            printf "${RED}█${NC}"
        elif (( DISK_PERCENT > 70 )); then
            printf "${YELLOW}█${NC}"
        else
            printf "${GREEN}█${NC}"
        fi
    done
    for ((i=0; i<DISK_EMPTY; i++)); do
        printf "░"
    done
    printf "] ${DISK_PERCENT}% (${DISK_USED}/${DISK_SIZE})\n"
done

# Docker (if installed)
if command -v docker &> /dev/null; then
    echo -e "\n${BOLD}${BLUE}━━━ DOCKER ━━━${NC}"
    DOCKER_RUNNING=$(docker ps -q 2>/dev/null | wc -l)
    DOCKER_TOTAL=$(docker ps -aq 2>/dev/null | wc -l)
    DOCKER_IMAGES=$(docker images -q 2>/dev/null | wc -l)
    echo -e "  Containers Running: ${GREEN}${DOCKER_RUNNING}${NC} / Total: ${YELLOW}${DOCKER_TOTAL}${NC}"
    echo -e "  Images: ${CYAN}${DOCKER_IMAGES}${NC}"
fi

# Network (top interfaces)
echo -e "\n${BOLD}${BLUE}━━━ NETWORK ━━━${NC}"
ip -brief addr show 2>/dev/null | head -5 | while read iface status addr; do
    if [ "$iface" != "lo" ]; then
        echo -e "  ${CYAN}${iface}:${NC} ${addr%%/*}"
    fi
done

# Top processes by CPU/Memory
echo -e "\n${BOLD}${BLUE}━━━ TOP PROCESSES (by CPU) ━━━${NC}"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -6 | tail -5 | while read pid comm cpu mem; do
    printf "  ${PURPLE}%-6s${NC} %-20s CPU: ${YELLOW}%5s%%${NC} MEM: ${CYAN}%5s%%${NC}\n" "$pid" "$comm" "$cpu" "$mem"
done

echo -e "\n${PURPLE}════════════════════════════════════════════════════════════${NC}"