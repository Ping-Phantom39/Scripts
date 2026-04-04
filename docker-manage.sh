#!/bin/bash
# Docker Management Script
# Various Docker maintenance and monitoring operations

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

show_help() {
    echo -e "${CYAN}Docker Management Script${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  status    Show running containers status"
    echo "  logs      Show logs for all containers (last 50 lines)"
    echo "  prune     Remove unused images, containers, networks"
    echo "  deepclean Full cleanup (unused + dangling + volumes)"
    echo "  stats     Live resource usage of containers"
    echo "  backup    Export running containers to tar files"
    echo "  health    Check container health status"
    echo "  sizes     Show disk usage by Docker"
    echo ""
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Cannot connect to Docker daemon${NC}"
        exit 1
    fi
}

show_status() {
    echo -e "${BOLD}${BLUE}━━━ DOCKER CONTAINERS ━━━${NC}"
    
    RUNNING=$(docker ps --format "{{.Names}}" | wc -l)
    STOPPED=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | wc -l)
    
    echo -e "Running: ${GREEN}${RUNNING}${NC} | Stopped: ${RED}${STOPPED}${NC}"
    echo ""
    
    if [ $RUNNING -gt 0 ]; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}" | \
            awk 'NR==1 {print; for(i=0;i<80;i++) printf "-"; print ""} NR>1 {print}'
    else
        echo -e "${YELLOW}No running containers${NC}"
    fi
}

show_logs() {
    echo -e "${BOLD}${BLUE}━━━ CONTAINER LOGS (last 50 lines) ━━━${NC}"
    
    for container in $(docker ps --format "{{.Names}}"); do
        echo -e "\n${CYAN}=== $container ===${NC}"
        docker logs --tail 50 "$container" 2>&1 | tail -20
    done
}

prune_unused() {
    echo -e "${YELLOW}Cleaning unused Docker resources...${NC}"
    docker system prune -f
    echo -e "${GREEN}Done!${NC}"
}

deep_clean() {
    echo -e "${RED}⚠️  This will remove ALL unused data including volumes!${NC}"
    read -p "Are you sure? (y/N): " confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo -e "${YELLOW}Performing deep cleanup...${NC}"
        docker system prune -a -f --volumes
        echo -e "${GREEN}Deep cleanup complete!${NC}"
    else
        echo -e "${YELLOW}Cancelled${NC}"
    fi
}

show_stats() {
    echo -e "${BOLD}${BLUE}━━━ LIVE CONTAINER STATS ━━━${NC}"
    echo -e "${YELLOW}(Press Ctrl+C to exit)${NC}\n"
    docker stats --no-stream
}

check_health() {
    echo -e "${BOLD}${BLUE}━━━ CONTAINER HEALTH CHECK ━━━${NC}"
    
    for container in $(docker ps --format "{{.Names}}"); do
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)
        
        if [ -z "$HEALTH" ]; then
            STATUS="${YELLOW}N/A${NC}"
        elif [ "$HEALTH" = "healthy" ]; then
            STATUS="${GREEN}HEALTHY${NC}"
        else
            STATUS="${RED}${HEALTH^^}${NC}"
        fi
        
        printf "  %-30s %s\n" "$container" "$STATUS"
    done
}

show_sizes() {
    echo -e "${BOLD}${BLUE}━━━ DOCKER DISK USAGE ━━━${NC}"
    docker system df
    
    echo -e "\n${BOLD}Top 10 largest images:${NC}"
    docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | \
        sort -hr -k2 | head -10 | \
        awk '{printf "  %-40s %s\n", $1, $2}'
}

backup_containers() {
    BACKUP_DIR="/home/ubuntu/Backups/docker"
    DATE=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${BLUE}Exporting running containers to $BACKUP_DIR${NC}"
    
    for container in $(docker ps --format "{{.Names}}"); do
        echo -e "  Exporting ${CYAN}$container${NC}..."
        docker export "$container" > "$BACKUP_DIR/${container}_${DATE}.tar"
    done
    
    echo -e "${GREEN}Backup complete!${NC}"
    ls -lh "$BACKUP_DIR" | tail -5
}

# Main
check_docker

case "$1" in
    status)    show_status ;;
    logs)      show_logs ;;
    prune)     prune_unused ;;
    deepclean) deep_clean ;;
    stats)     show_stats ;;
    health)    check_health ;;
    sizes)     show_sizes ;;
    backup)    backup_containers ;;
    *)         show_help ;;
esac