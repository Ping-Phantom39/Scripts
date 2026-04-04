#!/bin/bash
# Network Tools Script
# Various network diagnostics and monitoring utilities

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

show_help() {
    echo -e "${CYAN}Network Tools Script${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  info        Show network interfaces and IPs"
    echo "  ports       Show open ports and listening services"
    echo "  connections Show active network connections"
    echo "  dns         Test DNS resolution"
    echo "  speed       Run internet speed test (requires speedtest-cli)"
    echo "  ping        Ping multiple hosts"
    echo "  scan        Port scan a host (nmap required)"
    echo "  traffic     Show network traffic in real-time"
    echo ""
}

show_interfaces() {
    echo -e "${BOLD}${BLUE}━━━ NETWORK INTERFACES ━━━${NC}\n"
    
    ip -brief addr show | while read iface status addr; do
        if [ "$iface" = "lo" ]; then
            continue
        fi
        
        if [ "$status" = "UP" ]; then
            STATUS="${GREEN}UP${NC}"
        else
            STATUS="${RED}DOWN${NC}"
        fi
        
        echo -e "${CYAN}$iface${NC} [$STATUS] $addr"
    done
    
    # Show default gateway
    echo -e "\n${BOLD}Default Gateway:${NC}"
    ip route | grep default | awk '{print "  " $3}'
    
    # Show DNS servers
    echo -e "\n${BOLD}DNS Servers:${NC}"
    grep "nameserver" /etc/resolv.conf | awk '{print "  " $2}'
}

show_ports() {
    echo -e "${BOLD}${PURPLE}━━━ OPEN PORTS ━━━${NC}\n"
    
    echo -e "${CYAN}Listening TCP ports:${NC}"
    sudo ss -tlnp 2>/dev/null | grep LISTEN | \
        awk '{printf "  %-8s %-20s %s\n", $4, $1, $6}'
    
    echo -e "\n${CYAN}Listening UDP ports:${NC}"
    sudo ss -ulnp 2>/dev/null | grep -v "State\|^$" | \
        awk '{printf "  %-8s %-20s %s\n", $4, $1, $5}'
}

show_connections() {
    echo -e "${BOLD}${YELLOW}━━━ ACTIVE CONNECTIONS ━━━${NC}\n"
    
    echo -e "${CYAN}Established connections:${NC}"
    ss -tnp state established 2>/dev/null | \
        awk 'NR>1 {printf "  %-22s -> %-22s %s\n", $4, $5, $6}'
    
    echo -e "\n${CYAN}Connection summary by state:${NC}"
    ss -tn | awk 'NR>1 {print $1}' | sort | uniq -c | \
        awk '{printf "  %-15s %s\n", $2, $1}'
}

test_dns() {
    echo -e "${BOLD}${GREEN}━━━ DNS RESOLUTION TEST ━━━${NC}\n"
    
    DOMAINS=("google.com" "github.com" "amazon.com" "cloudflare.com")
    
    for domain in "${DOMAINS[@]}"; do
        start=$(date +%s%N)
        IP=$(dig +short "$domain" A 2>/dev/null | head -1)
        end=$(date +%s%N)
        
        duration=$(( (end - start) / 1000000 ))
        
        if [ -n "$IP" ]; then
            echo -e "${GREEN}✓${NC} $domain -> $IP (${duration}ms)"
        else
            echo -e "${RED}✗${NC} $domain -> FAILED"
        fi
    done
}

run_speedtest() {
    echo -e "${BOLD}${CYAN}━━━ INTERNET SPEED TEST ━━━${NC}\n"
    
    if ! command -v speedtest-cli &> /dev/null && ! command -v speedtest &> /dev/null; then
        echo -e "${YELLOW}Speedtest not installed. Installing...${NC}"
        sudo apt install -y speedtest-cli 2>/dev/null || pip3 install speedtest-cli 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Could not install speedtest${NC}"
            return
        fi
    fi
    
    if command -v speedtest &> /dev/null; then
        speedtest --simple
    else
        speedtest-cli --simple
    fi
}

ping_hosts() {
    echo -e "${BOLD}${BLUE}━━━ PING TEST ━━━${NC}\n"
    
    HOSTS=("8.8.8.8" "1.1.1.1" "google.com" "github.com")
    
    for host in "${HOSTS[@]}"; do
        result=$(ping -c 3 -W 2 "$host" 2>&1)
        
        if echo "$result" | grep -q "bytes from"; then
            avg=$(echo "$result" | tail -1 | awk -F'/' '{print $5}')
            loss=$(echo "$result" | grep "packet loss" | awk -F',' '{print $3}' | awk '{print $1}')
            
            echo -e "${GREEN}✓${NC} $host - avg: ${avg}ms, loss: ${loss}"
        else
            echo -e "${RED}✗${NC} $host - FAILED"
        fi
    done
}

port_scan() {
    read -p "Enter host to scan: " host
    
    if ! command -v nmap &> /dev/null; then
        echo -e "${YELLOW}nmap not installed. Installing...${NC}"
        sudo apt install -y nmap 2>/dev/null
    fi
    
    echo -e "\n${CYAN}Scanning $host...${NC}\n"
    nmap -sS -T4 -F "$host" 2>/dev/null
}

show_traffic() {
    echo -e "${BOLD}${PURPLE}━━━ NETWORK TRAFFIC ━━━${NC}"
    echo -e "${YELLOW}(Press Ctrl+C to exit)${NC}\n"
    
    if command -v iftop &> /dev/null; then
        sudo iftop
    elif command -v nload &> /dev/null; then
        nload
    else
        # Fallback: show packet counts
        echo -e "${CYAN}Using basic traffic monitor...${NC}\n"
        watch -n 1 'cat /proc/net/dev | grep -E \"eth|ens|wlan|enp\"'
    fi
}

# Main
case "$1" in
    info)        show_interfaces ;;
    ports)       show_ports ;;
    connections) show_connections ;;
    dns)         test_dns ;;
    speed)       run_speedtest ;;
    ping)        ping_hosts ;;
    scan)        port_scan ;;
    traffic)     show_traffic ;;
    *)           show_help ;;
esac