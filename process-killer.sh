#!/bin/bash
# Process Killer Script
# Find and kill resource-hogging processes

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

show_help() {
    echo -e "${CYAN}Process Killer Script${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  top       Show top CPU consuming processes"
    echo "  mem       Show top memory consuming processes"
    echo "  killcpu   Kill processes using >50% CPU (with confirmation)"
    echo "  killmem   Kill processes using >30% memory (with confirmation)"
    echo "  zombie    Find zombie processes"
    echo "  port      Find process using a specific port (prompted)"
    echo "  find      Search for process by name (prompted)"
    echo ""
}

show_top_cpu() {
    echo -e "${BOLD}${RED}━━━ TOP CPU CONSUMERS ━━━${NC}"
    echo ""
    ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%cpu | head -15 | \
        awk 'NR==1 {print $0; for(i=0;i<80;i++) printf "-"; print ""} NR>1 {printf "%-8s %-8s %-12s %5s%%  %5s%%  %s\n", $1, $2, $3, $4, $5, $6}'
}

show_top_mem() {
    echo -e "${BOLD}${YELLOW}━━━ TOP MEMORY CONSUMERS ━━━${NC}"
    echo ""
    ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%mem | head -15 | \
        awk 'NR==1 {print $0; for(i=0;i<80;i++) printf "-"; print ""} NR>1 {printf "%-8s %-8s %-12s %5s%%  %5s%%  %s\n", $1, $2, $3, $4, $5, $6}'
}

kill_high_cpu() {
    echo -e "${YELLOW}Finding processes using >50% CPU...${NC}\n"
    
    HIGH_CPU=$(ps -eo pid,%cpu,comm --sort=-%cpu | awk '$2 > 50 && $1 > 1 {print $1, $2, $3}')
    
    if [ -z "$HIGH_CPU" ]; then
        echo -e "${GREEN}✓ No high CPU processes found${NC}"
        return
    fi
    
    echo "$HIGH_CPU" | while read pid cpu comm; do
        echo -e "  ${RED}PID: ${pid}${NC}  CPU: ${cpu}%  Process: ${comm}"
    done
    
    echo ""
    read -p "Kill these processes? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "$HIGH_CPU" | while read pid cpu comm; do
            kill -9 "$pid" 2>/dev/null && echo -e "${GREEN}✓ Killed $pid ($comm)${NC}"
        done
    else
        echo "Cancelled"
    fi
}

kill_high_mem() {
    echo -e "${YELLOW}Finding processes using >30% memory...${NC}\n"
    
    HIGH_MEM=$(ps -eo pid,%mem,comm --sort=-%mem | awk '$2 > 30 && $1 > 1 {print $1, $2, $3}')
    
    if [ -z "$HIGH_MEM" ]; then
        echo -e "${GREEN}✓ No high memory processes found${NC}"
        return
    fi
    
    echo "$HIGH_MEM" | while read pid mem comm; do
        echo -e "  ${YELLOW}PID: ${pid}${NC}  MEM: ${mem}%  Process: ${comm}"
    done
    
    echo ""
    read -p "Kill these processes? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "$HIGH_MEM" | while read pid mem comm; do
            kill -9 "$pid" 2>/dev/null && echo -e "${GREEN}✓ Killed $pid ($comm)${NC}"
        done
    else
        echo "Cancelled"
    fi
}

find_zombies() {
    echo -e "${BOLD}${PURPLE}━━━ ZOMBIE PROCESSES ━━━${NC}"
    echo ""
    
    ZOMBIES=$(ps -eo pid,ppid,stat,comm | grep -E "Z|defunct")
    
    if [ -z "$ZOMBIES" ]; then
        echo -e "${GREEN}✓ No zombie processes found${NC}"
    else
        echo "$ZOMBIES" | while read line; do
            echo -e "  ${PURPLE}$line${NC}"
        done
    fi
}

find_by_port() {
    read -p "Enter port number: " port
    
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid port number${NC}"
        return
    fi
    
    echo -e "\n${CYAN}Processes using port $port:${NC}\n"
    
    PROCESS=$(sudo lsof -i :$port 2>/dev/null | tail -n +2)
    
    if [ -z "$PROCESS" ]; then
        echo -e "${YELLOW}No process found using port $port${NC}"
    else
        echo "$PROCESS"
        
        PID=$(echo "$PROCESS" | awk '{print $2}' | head -1)
        echo ""
        read -p "Kill process $PID? (y/N): " confirm
        
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            sudo kill -9 $PID 2>/dev/null && echo -e "${GREEN}✓ Killed process $PID${NC}"
        fi
    fi
}

find_by_name() {
    read -p "Enter process name: " name
    
    echo -e "\n${CYAN}Processes matching '$name':${NC}\n"
    
    ps aux | grep -i "$name" | grep -v grep | while read line; do
        echo "  $line"
    done
    
    PIDS=$(pgrep -i "$name" 2>/dev/null)
    
    if [ -n "$PIDS" ]; then
        echo ""
        read -p "Kill all matching processes? (y/N): " confirm
        
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            for pid in $PIDS; do
                kill -9 $pid 2>/dev/null && echo -e "${GREEN}✓ Killed $pid${NC}"
            done
        fi
    fi
}

# Main
case "$1" in
    top)      show_top_cpu ;;
    mem)      show_top_mem ;;
    killcpu)  kill_high_cpu ;;
    killmem)  kill_high_mem ;;
    zombie)   find_zombies ;;
    port)     find_by_port ;;
    find)     find_by_name ;;
    *)        show_help ;;
esac