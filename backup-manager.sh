#!/bin/bash
# Backup Manager Script
# Simple backup management with rotation and compression

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

BACKUP_DIR="${HOME}/backups"
RETENTION_DAYS=7
COMPRESSION=true

show_help() {
    echo -e "${CYAN}Backup Manager Script${NC}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  backup [source] [name]    Create a new backup"
    echo "  list                      List all backups"
    echo "  restore [name] [target]   Restore a backup"
    echo "  cleanup                   Remove old backups"
    echo "  status                    Show backup status"
    echo ""
    echo "Options:"
    echo "  -n, --name NAME       Backup name (defaults to source directory)"
    echo "  -d, --dir DIR         Backup directory (default: ~/backups)"
    echo "  -r, --retention DAYS  Retention period (default: 7 days)"
    echo "  -z, --no-compress     Disable compression"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 backup /home/user/documents"
    echo "  $0 backup /home/user/projects project-backup"
    echo "  $0 list"
    echo "  $0 cleanup --retention 30"
}

create_backup() {
    local source="${1:-.}"
    local name="${2:-$(basename "$source")}"
    
    # Check if source exists
    if [[ ! -e "$source" ]]; then
        echo -e "${RED}Error: Source '$source' does not exist${NC}"
        exit 1
    fi
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Generate backup filename with timestamp
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${name}_${timestamp}"
    
    echo -e "${BOLD}${BLUE}━━━ CREATING BACKUP ━━━${NC}"
    echo -e "${CYAN}Source:${NC} $source"
    echo -e "${CYAN}Name:${NC} $backup_name"
    
    # Create backup
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ -d "$source" ]]; then
        if [[ "$COMPRESSION" == true ]]; then
            echo -e "${YELLOW}Compressing...${NC}"
            tar -czf "${backup_path}.tar.gz" -C "$(dirname "$source")" "$(basename "$source")"
        else
            echo -e "${YELLOW}Copying...${NC}"
            cp -r "$source" "$backup_path"
        fi
    else
        if [[ "$COMPRESSION" == true ]]; then
            echo -e "${YELLOW}Compressing...${NC}"
            gzip -c "$source" > "${backup_path}.gz"
        else
            echo -e "${YELLOW}Copying...${NC}"
            cp "$source" "$backup_path"
        fi
    fi
    
    # Check if backup was successful
    if [[ -e "${backup_path}.tar.gz" || -e "${backup_path}.gz" || -d "$backup_path" ]]; then
        echo -e "${GREEN}Backup created successfully!${NC}"
        
        # Show backup info
        local size=$(du -sh "${backup_path}"* 2>/dev/null | head -1 | awk '{print $1}')
        echo -e "${CYAN}Size:${NC} $size"
        echo -e "${CYAN}Location:${NC} ${backup_path}.*"
    else
        echo -e "${RED}Backup failed!${NC}"
        exit 1
    fi
}

list_backups() {
    echo -e "${BOLD}${BLUE}━━━ AVAILABLE BACKUPS ━━━${NC}"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backups directory found. Create one with 'backup' command.${NC}"
        return
    fi
    
    local count=0
    echo -e "${CYAN}Location:${NC} $BACKUP_DIR"
    echo ""
    
    for backup in "$BACKUP_DIR"/*; do
        [[ ! -e "$backup" ]] && continue
        ((count++))
        
        local name=$(basename "$backup")
        local size=$(du -sh "$backup" 2>/dev/null | awk '{print $1}')
        local mtime=$(stat -c %y "$backup" 2>/dev/null | cut -d'.' -f1)
        
        echo -e "${PURPLE}[$count]${NC} ${CYAN}$name${NC}"
        echo -e "    ${YELLOW}Size:${NC} $size  ${YELLOW}Modified:${NC} $mtime"
        echo ""
    done
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No backups found.${NC}"
    else
        echo -e "${GREEN}Total: $count backup(s)${NC}"
    fi
}

restore_backup() {
    local name="$1"
    local target="${2:-.}"
    
    if [[ -z "$name" ]]; then
        echo -e "${RED}Error: Please specify a backup name${NC}"
        list_backups
        exit 1
    fi    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${RED}Error: Backup directory does not exist${NC}"
        exit 1
    fi
    
    # Find backup file
    local backup_file=""
    if [[ -e "$BACKUP_DIR/$name" ]]; then
        backup_file="$BACKUP_DIR/$name"
    elif [[ -e "$BACKUP_DIR/$name.tar.gz" ]]; then
        backup_file="$BACKUP_DIR/$name.tar.gz"
    elif [[ -e "$BACKUP_DIR/$name.gz" ]]; then
        backup_file="$BACKUP_DIR/$name.gz"
    else
        echo -e "${RED}Error: Backup '$name' not found${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ RESTORING BACKUP ━━━${NC}"
    echo -e "${CYAN}Backup:${NC} $backup_file"
    echo -e "${CYAN}Target:${NC} $target"
    
    # Restore based on type
    if [[ -d "$backup_file" ]]; then
        echo -e "${YELLOW}Copying...${NC}"
        cp -r "$backup_file"/* "$target"/
    elif [[ "$backup_file" == *.tar.gz ]]; then
        echo -e "${YELLOW}Extracting...${NC}"
        mkdir -p "$target"
        tar -xzf "$backup_file" -C "$target"
    elif [[ "$backup_file" == *.gz ]]; then
        echo -e "${YELLOW}Decompressing...${NC}"
        gunzip -c "$backup_file" > "$target"
    fi
    
    echo -e "${GREEN}Restore completed!${NC}"
}

cleanup_backups() {
    echo -e "${BOLD}${BLUE}━━━ CLEANUP OLD BACKUPS ━━━${NC}"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo -e "${YELLOW}No backups directory found.${NC}"
        return
    fi
    
    local deleted=0
    local freed=""
    
    for backup in "$BACKUP_DIR"/*; do
        [[ ! -e "$backup" ]] && continue
        
        local age=$(find "$backup" -mtime +$RETENTION_DAYS 2>/dev/null)
        if [[ -n "$age" ]]; then
            local size=$(du -sh "$backup" 2>/dev/null | awk '{print $1}')
            rm -rf "$backup"
            ((deleted++))
            echo -e "${YELLOW}Deleted:${NC} $(basename "$backup") ($size)"
        fi
    done
    
    if [[ $deleted -eq 0 ]]; then
        echo -e "${GREEN}No backups older than $RETENTION_DAYS days found.${NC}"
    else
        echo -e "${GREEN}Cleaned up $deleted old backup(s)${NC}"
    fi
}

show_status() {
    echo -e "${BOLD}${BLUE}━━━ BACKUP STATUS ━━━${NC}"
    
    echo -e "\n${BOLD}${CYAN}Configuration:${NC}"
    echo -e "  Backup Directory: $BACKUP_DIR"
    echo -e "  Retention: $RETENTION_DAYS days"
    echo -e "  Compression: $([ "$COMPRESSION" == true ] && echo "Enabled" || echo "Disabled")"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        local count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
        local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
        
        echo -e "\n${BOLD}${CYAN}Statistics:${NC}"
        echo -e "  Total Backups: $count"
        echo -e "  Total Size: $total_size"
        
        # Show recent backups
        if [[ $count -gt 0 ]]; then
            echo -e "\n${BOLD}${CYAN}Recent Backups:${NC}"
            ls -lt "$BACKUP_DIR" 2>/dev/null | head -5 | tail -5 | while read line; do
                echo "  $line"
            done
        fi
    else
        echo -e "\n${YELLOW}No backups directory found. Create one with 'backup' command.${NC}"
    fi
}

# Parse global options
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -r|--retention)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        -z|--no-compress)
            COMPRESSION=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# Main command dispatcher
case "$1" in
    backup)
        shift
        create_backup "$@"
        ;;
    list)
        list_backups
        ;;
    restore)
        shift
        restore_backup "$@"
        ;;
    cleanup)
        shift
        cleanup_backups
        ;;
    status)
        show_status
        ;;
    *)
        show_help
        ;;
esac
