#!/bin/bash
# Service Control Script
# Easy service management with status monitoring

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
    echo -e "${CYAN}Service Control Script${NC}"
    echo ""
    echo "Usage: $0 [command] [service]"
    echo ""
    echo "Commands:"
    echo "  start SERVICE         Start a service"
    echo "  stop SERVICE          Stop a service"
    echo "  restart SERVICE       Restart a service"
    echo "  status SERVICE        Show service status"
    echo "  enable SERVICE        Enable service at boot"
    echo "  disable SERVICE       Disable service at boot"
    echo "  list                  List all services"
    echo "  status-all            Show status of all services"
    echo "  top-cpu               Show top CPU-consuming services"
    echo "  top-mem               Show top memory-consuming services"
    echo ""
    echo "Examples:"
    echo "  $0 start nginx"
    echo "  $0 status-all"
    echo "  $0 restart docker"
}

get_system_manager() {
    if command -v systemctl &>/dev/null; then
        echo "systemd"
    elif command -v service &>/dev/null; then
        echo "sysv"
    elif command -v docker &>/dev/null; then
        echo "docker"
    else
        echo "unknown"
    fi
}

list_services() {
    echo -e "${BOLD}${BLUE}━━━ SYSTEM SERVICES ━━━${NC}"
    
    local manager=$(get_system_manager)
    
    case "$manager" in
        systemd)
            echo -e "${CYAN}System Manager:${NC} systemd"
            echo -e "\n${BOLD}Active Services:${NC}"
            sudo systemctl list-units --type=service --state=active 2>/dev/null | tail -n +2 | head -20
            
            echo -e "\n${BOLD}All Services:${NC}"
            sudo systemctl list-units --type=service --all 2>/dev/null | tail -n +2 | head -30
            ;;
        sysv)
            echo -e "${CYAN}System Manager:${NC} sysvinit"
            echo -e "\n${BOLD}Service Status:${NC}"
            service --status-all 2>/dev/null
            ;;
        docker)
            echo -e "${CYAN}System Manager:${NC} docker"
            echo -e "\n${BOLD}Running Containers:${NC}"
            docker ps
            ;;
        *)
            echo -e "${YELLOW}Unknown system manager${NC}"
            echo -e "${YELLOW}Trying common service commands...${NC}"
            echo -e "\n${BOLD}Services:${NC}"
            ls /etc/init.d/ 2>/dev/null | sed 's/^/  /'
            ;;
    esac
}

service_action() {
    local action="$1"
    local service="$2"
    
    if [[ -z "$service" ]]; then
        echo -e "${RED}Error: Please specify a service name${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ $action SERVICE: $service ━━━${NC}"
    
    local manager=$(get_system_manager)
    
    case "$manager" in
        systemd)
            case "$action" in
                start)
                    sudo systemctl start "$service" && echo -e "${GREEN}Service started!${NC}"
                    ;;
                stop)
                    sudo systemctl stop "$service" && echo -e "${GREEN}Service stopped!${NC}"
                    ;;
                restart)
                    sudo systemctl restart "$service" && echo -e "${GREEN}Service restarted!${NC}"
                    ;;
                status)
                    sudo systemctl status "$service"
                    ;;
                enable)
                    sudo systemctl enable "$service" && echo -e "${GREEN}Service enabled at boot!${NC}"
                    ;;
                disable)
                    sudo systemctl disable "$service" && echo -e "${GREEN}Service disabled at boot!${NC}"
                    ;;
            esac
            ;;
        sysv)
            case "$action" in
                start)
                    sudo service "$service" start && echo -e "${GREEN}Service started!${NC}"
                    ;;
                stop)
                    sudo service "$service" stop && echo -e "${GREEN}Service stopped!${NC}"
                    ;;
                restart)
                    sudo service "$service" restart && echo -e "${GREEN}Service restarted!${NC}"
                    ;;
                status)
                    sudo service "$service" status
                    ;;
                enable)
                    echo -e "${YELLOW}Use update-rc.d or chkconfig to enable services${NC}"
                    ;;
                disable)
                    echo -e "${YELLOW}Use update-rc.d or chkconfig to disable services${NC}"
                    ;;
            esac
            ;;
        docker)
            case "$action" in
                start)
                    docker start "$service" && echo -e "${GREEN}Container started!${NC}"
                    ;;
                stop)
                    docker stop "$service" && echo -e "${GREEN}Container stopped!${NC}"
                    ;;
                restart)
                    docker restart "$service" && echo -e "${GREEN}Container restarted!${NC}"
                    ;;
                status)
                    docker ps -a --filter "name=$service"
                    ;;
                enable|disable)
                    echo -e "${YELLOW}Docker containers don't support enable/disable${NC}"
                    echo -e "${YELLOW}Use docker-compose or systemd for auto-start${NC}"
                    ;;
            esac
            ;;
        *)
            echo -e "${YELLOW}Cannot determine system manager${NC}"
            echo -e "${YELLOW}Attempting generic service command...${NC}"
            case "$action" in
                start)
                    sudo service "$service" start 2>/dev/null && echo -e "${GREEN}Service started!${NC}"
                    ;;
                stop)
                    sudo service "$service" stop 2>/dev/null && echo -e "${GREEN}Service stopped!${NC}"
                    ;;
                restart)
                    sudo service "$service" restart 2>/dev/null && echo -e "${GREEN}Service restarted!${NC}"
                    ;;
                status)
                    sudo service "$service" status 2>/dev/null
                    ;;
            esac
            ;;
    esac
}

show_service_status() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        echo -e "${RED}Error: Please specify a service name${NC}"
        exit 1
    fi
    
    service_action "status" "$service"
    
    # Additional information
    echo -e "\n${BOLD}${BLUE}━━━ SERVICE DETAILS: $service ━━━${NC}"
    
    # Check if service is enabled
    if command -v systemctl &>/dev/null; then
        if sudo systemctl is-enabled "$service" &>/dev/null; then
            echo -e "${GREEN}Enabled at boot${NC}"
        else
            echo -e "${YELLOW}Not enabled at boot${NC}"
        fi
    fi
    
    # Show service file location
    if command -v systemctl &>/dev/null; then
        local unit_file=$(systemctl list-unit-files "$service*" 2>/dev/null | grep "$service" | awk '{print $NF}')
        if [[ -n "$unit_file" ]]; then
            echo -e "${CYAN}Unit file:${NC} $unit_file"
        fi
    fi
    
    # Show process info
    echo -e "\n${BOLD}${PURPLE}Process Info:${NC}"
    pgrep -a -f "$service" | head -5 || echo -e "${YELLOW}No running processes found${NC}"
}

show_all_status() {
    echo -e "${BOLD}${BLUE}━━━ ALL SERVICE STATUS ━━━${NC}"
    
    local manager=$(get_system_manager)
    
    case "$manager" in
        systemd)
            echo -e "${CYAN}System Manager:${NC} systemd"
            echo ""
            
            # Get all services with their status
            sudo systemctl list-units --type=service --all 2>/dev/null | tail -n +2 | while read line; do
                local service=$(echo "$line" | awk '{print $1}')
                local active=$(echo "$line" | awk '{print $3}')
                
                if [[ "$active" == "active" ]]; then
                    echo -e "${GREEN}●${NC} $service"
                elif [[ "$active" == "inactive" ]]; then
                    echo -e "${BLUE}○${NC} $service"
                elif [[ "$active" == "failed" ]]; then
                    echo -e "${RED}✗${NC} $service"
                else
                    echo -e "${YELLOW}○${NC} $service"
                fi
            done
            ;;
        sysv)
            echo -e "${CYAN}System Manager:${NC} sysvinit"
            echo ""
            service --status-all 2>/dev/null
            ;;
        docker)
            echo -e "${CYAN}System Manager:${NC} docker"
            echo ""
            docker ps -a
            ;;
        *)
            echo -e "${YELLOW}Unknown system manager${NC}"
            ;;
    esac
}

top_cpu_services() {
    echo -e "${BOLD}${BLUE}━━━ TOP CPU-CONSUMING SERVICES ━━━${NC}"
    
    echo -e "${CYAN}PID${NC}  ${YELLOW}CPU%${NC} ${GREEN}Service${NC}"
    echo -e "──── ──── ─────────────────────"
    
    ps aux --sort=-%cpu | head -10 | tail -n +2 | while read line; do
        local pid=$(echo "$line" | awk '{print $2}')
        local cpu=$(echo "$line" | awk '{print $3}')
        local cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
        
        printf "%-5s %-5s %s\n" "$pid" "$cpu%" "$cmd"
    done
}

top_mem_services() {
    echo -e "${BOLD}${BLUE}━━━ TOP MEMORY-CONSUMING SERVICES ━━━${NC}"
    
    echo -e "${CYAN}PID${NC}  ${YELLOW}MEM%${NC} ${GREEN}Service${NC}"
    echo -e "──── ──── ─────────────────────"
    
    ps aux --sort=-%mem | head -10 | tail -n +2 | while read line; do
        local pid=$(echo "$line" | awk '{print $2}')
        local mem=$(echo "$line" | awk '{print $4}')
        local cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
        
        printf "%-5s %-5s %s\n" "$pid" "$mem%" "$cmd"
    done
}

# Parse arguments
case "$1" in
    list)
        list_services
        ;;
    status-all|statusall)
        show_all_status
        ;;
    top-cpu|topcpu)
        top_cpu_services
        ;;
    top-mem|topmem)
        top_mem_services
        ;;
    start|stop|restart|enable|disable)
        shift
        service_action "$1" "$@"
        ;;
    status)
        shift
        show_service_status "$@"
        ;;
    -h|--help|help|"")
        show_help
        ;;
    *)
        show_help
        ;;
esac
