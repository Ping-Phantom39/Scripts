#!/bin/bash
# Log Analyzer Script
# Analyze system logs for errors, warnings, and suspicious activity

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

LOG_DIRS=(
    "/var/log"
    "/home/ubuntu/.openclaw/logs"
)

# Time filter (default: today)
TIME_FILTER=$(date '+%b %d')

show_help() {
    echo -e "${CYAN}Log Analyzer Script${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  errors     Show recent errors from system logs"
    echo "  auth       Show authentication logs (logins, sudo)"
    echo "  docker     Show Docker container logs (errors only)"
    echo "  kernel     Show kernel messages (dmesg)"
    echo "  security   Show potential security issues"
    echo "  summary    Show summary of all log types"
    echo "  follow     Follow a specific log file (prompted)"
    echo ""
}

show_errors() {
    echo -e "${BOLD}${RED}━━━ RECENT ERRORS ━━━${NC}\n"
    
    # Syslog errors
    if [ -f /var/log/syslog ]; then
        echo -e "${CYAN}System Log Errors (last 20):${NC}"
        grep -i "error\|fail\|critical" /var/log/syslog | \
            grep "$TIME_FILTER" | tail -20 | while read line; do
            echo -e "  ${RED}$line${NC}"
        done
    fi
    
    # Journal errors
    echo -e "\n${CYAN}Journal Errors (last 15):${NC}"
    journalctl -p err --no-pager -n 15 --since today 2>/dev/null | while read line; do
        echo -e "  ${YELLOW}$line${NC}"
    done
}

show_auth() {
    echo -e "${BOLD}${PURPLE}━━━ AUTHENTICATION LOGS ━━━${NC}\n"
    
    if [ -f /var/log/auth.log ]; then
        echo -e "${CYAN}Successful sudo commands:${NC}"
        grep "sudo:" /var/log/auth.log | grep "COMMAND" | \
            grep "$TIME_FILTER" | tail -10 | while read line; do
            echo "  $line"
        done
        
        echo -e "\n${CYAN}Failed login attempts:${NC}"
        grep "Failed password" /var/log/auth.log | \
            grep "$TIME_FILTER" | tail -10 | while read line; do
            echo -e "  ${RED}$line${NC}"
        done
        
        echo -e "\n${CYAN}Successful logins:${NC}"
        grep "Accepted password\|session opened" /var/log/auth.log | \
            grep "$TIME_FILTER" | tail -10 | while read line; do
            echo -e "  ${GREEN}$line${NC}"
        done
    fi
}

show_docker_logs() {
    echo -e "${BOLD}${BLUE}━━━ DOCKER LOGS ━━━${NC}\n"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker not installed${NC}"
        return
    fi
    
    for container in $(docker ps --format "{{.Names}}"); do
        echo -e "${CYAN}Container: $container${NC}"
        
        # Get last 10 error lines
        docker logs --tail 100 "$container" 2>&1 | \
            grep -i "error\|fail\|exception\|fatal" | tail -5 | while read line; do
            echo -e "  ${YELLOW}$line${NC}"
        done
        
        echo ""
    done
}

show_kernel() {
    echo -e "${BOLD}${YELLOW}━━━ KERNEL MESSAGES ━━━${NC}\n"
    
    echo -e "${CYAN}Recent kernel errors/warnings:${NC}"
    dmesg --level err,warn -T 2>/dev/null | tail -20 | while read line; do
        echo "  $line"
    done
}

show_security() {
    echo -e "${BOLD}${RED}━━━ SECURITY ANALYSIS ━━━${NC}\n"
    
    if [ -f /var/log/auth.log ]; then
        # Failed login attempts by IP
        echo -e "${CYAN}Failed login attempts by IP (top 5):${NC}"
        grep "Failed password" /var/log/auth.log | \
            grep "$TIME_FILTER" | \
            awk '{for(i=1;i<=NF;i++) if($i ~ /rhost/) print $(i+1)}' | \
            sort | uniq -c | sort -rn | head -5 | while read count ip; do
            echo -e "  ${RED}$count${NC} attempts from ${YELLOW}$ip${NC}"
        done
        
        # Invalid users
        echo -e "\n${CYAN}Invalid user attempts:${NC}"
        grep "Invalid user" /var/log/auth.log | \
            grep "$TIME_FILTER" | tail -10 | while read line; do
            echo -e "  ${RED}$line${NC}"
        done
    fi
    
    # Check for suspicious cron jobs
    echo -e "\n${CYAN}Recent cron activity:${NC}"
    grep "CRON" /var/log/syslog 2>/dev/null | \
        grep "$TIME_FILTER" | tail -10 | while read line; do
        echo "  $line"
    done
}

show_summary() {
    echo -e "${BOLD}${CYAN}━━━ LOG SUMMARY ━━━${NC}\n"
    
    # Error counts
    ERROR_COUNT=0
    FAILED_LOGINS=0
    
    if [ -f /var/log/syslog ]; then
        ERROR_COUNT=$(grep -ic "error\|fail" /var/log/syslog | head -1 || echo 0)
    fi
    
    if [ -f /var/log/auth.log ]; then
        FAILED_LOGINS=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo 0)
    fi
    
    echo -e "  Errors today:         ${YELLOW}${ERROR_COUNT}${NC}"
    echo -e "  Failed logins today:  ${RED}${FAILED_LOGINS}${NC}"
    
    # Docker status
    if command -v docker &> /dev/null; then
        RUNNING=$(docker ps -q | wc -l)
        UNHEALTHY=$(docker ps --filter "health=unhealthy" -q | wc -l)
        echo -e "  Docker containers:    ${GREEN}${RUNNING} running${NC}"
        [ $UNHEALTHY -gt 0 ] && echo -e "                       ${RED}${UNHEALTHY} unhealthy${NC}"
    fi
    
    # Disk usage
    echo -e "\n${CYAN}Log file sizes:${NC}"
    du -sh /var/log 2>/dev/null
}

follow_log() {
    echo -e "${CYAN}Available log files:${NC}\n"
    
    select file in /var/log/syslog /var/log/auth.log /var/log/kern.log /var/log/docker.log "Custom path"; do
        if [ "$file" = "Custom path" ]; then
            read -p "Enter log file path: " file
        fi
        
        if [ -f "$file" ]; then
            echo -e "\n${GREEN}Following $file (Ctrl+C to stop)${NC}\n"
            tail -f "$file"
        else
            echo -e "${RED}File not found: $file${NC}"
        fi
        break
    done
}

# Main
case "$1" in
    errors)   show_errors ;;
    auth)     show_auth ;;
    docker)   show_docker_logs ;;
    kernel)   show_kernel ;;
    security) show_security ;;
    summary)  show_summary ;;
    follow)   follow_log ;;
    *)        show_help ;;
esac