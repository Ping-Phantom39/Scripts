#!/bin/bash
# Configuration Backup Script
# Backs up important system and application configurations

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config
BACKUP_DIR="/home/ubuntu/Backups/configs"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}    CONFIGURATION BACKUP SCRIPT${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""

BACKUP_FILE="$BACKUP_DIR/config_backup_$DATE.tar.gz"
TEMP_DIR=$(mktemp -d)

echo -e "${BLUE}Creating backup at: ${BACKUP_FILE}${NC}\n"

# System configs
echo -e "${YELLOW}Backing up system configurations...${NC}"
mkdir -p "$TEMP_DIR/system"

[ -d /etc/nginx ] && cp -r /etc/nginx "$TEMP_DIR/system/" 2>/dev/null && echo "  ✓ nginx"
[ -d /etc/ssh ] && cp -r /etc/ssh "$TEMP_DIR/system/" 2>/dev/null && echo "  ✓ ssh"
[ -d /etc/systemd ] && cp -r /etc/systemd "$TEMP_DIR/system/" 2>/dev/null && echo "  ✓ systemd"
[ -d /etc/docker ] && cp -r /etc/docker "$TEMP_DIR/system/" 2>/dev/null && echo "  ✓ docker"
[ -f /etc/fstab ] && cp /etc/fstab "$TEMP_DIR/system/" 2>/dev/null && echo "  ✓ fstab"
[ -f /etc/hosts ] && cp /etc/hosts "$TEMP_DIR/system/" 2>/dev/null && echo "  ✓ hosts"
[ -f /etc/crontab ] && cp /etc/crontab "$TEMP_DIR/system/" 2>/dev/null && echo "  ✓ crontab"

# User configs
echo -e "\n${YELLOW}Backing up user configurations...${NC}"
mkdir -p "$TEMP_DIR/user"

[ -f ~/.bashrc ] && cp ~/.bashrc "$TEMP_DIR/user/" && echo "  ✓ .bashrc"
[ -f ~/.zshrc ] && cp ~/.zshrc "$TEMP_DIR/user/" && echo "  ✓ .zshrc"
[ -f ~/.vimrc ] && cp ~/.vimrc "$TEMP_DIR/user/" && echo "  ✓ .vimrc"
[ -f ~/.gitconfig ] && cp ~/.gitconfig "$TEMP_DIR/user/" && echo "  ✓ .gitconfig"
[ -f ~/.ssh/config ] && cp ~/.ssh/config "$TEMP_DIR/user/" 2>/dev/null && echo "  ✓ ssh config"
[ -d ~/.openclaw ] && cp -r ~/.openclaw "$TEMP_DIR/user/" 2>/dev/null && echo "  ✓ openclaw"

# Docker compose files
echo -e "\n${YELLOW}Backing up Docker configurations...${NC}"
mkdir -p "$TEMP_DIR/docker"

for compose in $(find /home/ubuntu -name "docker-compose.yml" -o -name "docker-compose.yaml" 2>/dev/null); do
    project=$(dirname "$compose" | xargs basename)
    mkdir -p "$TEMP_DIR/docker/$project"
    cp "$compose" "$TEMP_DIR/docker/$project/"
    echo "  ✓ $project"
done

# Projects (important configs only)
echo -e "\n${YELLOW}Backing up project configs...${NC}"
mkdir -p "$TEMP_DIR/projects"

for project in /home/ubuntu/*/; do
    if [ -d "$project" ]; then
        name=$(basename "$project")
        
        # Backup specific config files
        [ -f "$project.env" ] && cp "$project.env" "$TEMP_DIR/projects/$name.env"
        [ -f "$project/.env" ] && cp "$project/.env" "$TEMP_DIR/projects/$name.env"
        [ -f "$project/config.yml" ] && cp "$project/config.yml" "$TEMP_DIR/projects/$name.yml"
        [ -f "$project/package.json" ] && cp "$project/package.json" "$TEMP_DIR/projects/$name-package.json"
    fi
done

# Cron jobs
echo -e "\n${YELLOW}Backing up cron jobs...${NC}"
crontab -l > "$TEMP_DIR/user/crontab" 2>/dev/null && echo "  ✓ user crontab"

# Create metadata
cat > "$TEMP_DIR/metadata.txt" << EOF
Backup Created: $(date)
Hostname: $(hostname)
User: $(whoami)
Kernel: $(uname -r)
EOF

# Create archive
echo -e "\n${YELLOW}Creating archive...${NC}"
tar -czf "$BACKUP_FILE" -C "$TEMP_DIR" . 2>/dev/null
rm -rf "$TEMP_DIR"

# Get file size
SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo -e "${GREEN}✓ Backup created: ${BACKUP_FILE} (${SIZE})${NC}"

# Clean old backups
echo -e "\n${YELLOW}Cleaning old backups (older than $RETENTION_DAYS days)...${NC}"
DELETED=$(find "$BACKUP_DIR" -name "config_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)
echo -e "  Removed ${DELETED} old backup(s)"

# List current backups
echo -e "\n${CYAN}Current backups:${NC}"
ls -lht "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -5

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Backup complete!${NC}"