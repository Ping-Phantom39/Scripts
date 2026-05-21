#!/bin/bash
# Disk Management and Disk Information Script
# Provides comprehensive disk information using lsblk, df, blkid, and more

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ASCII art banner
echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC} ${BOLD}${CYAN}DISK MANAGEMENT & INFORMATION${NC}                        ${PURPLE}║${NC}"
echo -e "${PURPLE}║${NC} $(date '+%Y-%m-%d %H:%M:%S')                                      ${PURPLE}║${NC}"
echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"

# Display block devices in tree format
show_block_devices() {
    echo -e "\n${BOLD}${BLUE}━━━ BLOCK DEVICES (Tree Format) ━━━${NC}"
    echo -e "${CYAN}All block devices with filesystem info:${NC}\n"
    lsblk -o NAME,MAJ:MIN,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL,UUID -P
}

# Display disk usage summary
show_disk_usage() {
    echo -e "\n${BOLD}${BLUE}━━━ DISK USAGE SUMMARY ━━━${NC}"
    echo -e "${CYAN}Filesystem disk space usage:${NC}\n"
    df -hT 2>/dev/null | grep -E "^/dev|Filesystem"
    
    echo -e "\n${CYAN}Detailed filesystem information:${NC}"
    df -i 2>/dev/null | grep -E "^/dev|Filesystem" | head -10
}

# Display partition table info
show_partitions() {
    echo -e "\n${BOLD}${BLUE}━━━ PARTITIONS ━━━${NC}"
    echo -e "${CYAN}Partition information with UUID and labels:${NC}\n"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,PARTTYPE,PARTNUM,PARTUUID,LABEL -P
}

# Display block device tree with filesystem info
show_block_tree() {
    echo -e "\n${BOLD}${BLUE}━━━ BLOCKDEVICE TREE ━━━${NC}"
    echo -e "${CYAN}Hierarchical view of all block devices:${NC}\n"
    lsblk
}

# Display disk I/O statistics
show_io_stats() {
    echo -e "\n${BOLD}${BLUE}━━━ I/O STATISTICS ━━━${NC}"
    if command -v iostat &> /dev/null; then
        echo -e "${CYAN}I/O statistics (last 10 seconds):${NC}\n"
        iostat -x 10 1 2>/dev/null || iostat -x 1
    else
        echo -e "${YELLOW}iostat not available. Install sysstat to see I/O stats.${NC}"
    fi
}

# Display UUID to device mapping
show_uuid_map() {
    echo -e "\n${BOLD}${BLUE}━━━ UUID TO DEVICE MAPPING ━━━${NC}"
    echo -e "${CYAN}All block devices with UUIDs:${NC}\n"
    lsblk -o NAME,UUID,LABEL,FSTYPE,MOUNTPOINT
}

# Display disk SMART info
show_smart_info() {
    echo -e "\n${BOLD}${BLUE}━━━ SMART INFORMATION ━━━${NC}"
    echo -e "${CYAN}Checking SMART status of block devices...${NC}\n"
    
    for device in /dev/sd[a-z] /dev/nvme*; do
        if [ -b "$device" ]; then
            if command -v smartctl &> /dev/null; then
                if smartctl -i "$device" &>/dev/null; then
                    echo -e "${BLUE}=== $device ===${NC}"
                    smartctl -i "$device" 2>/dev/null | grep -E "Device:|Serial|Capacity|SMART"
                    smartctl -H "$device" 2>/dev/null | grep -E "smartctl|overall-health|PASSED|FAILED"
                    echo ""
                fi
            else
                echo -e "${YELLOW}smartctl not available. Install smartmontools for SMART info.${NC}"
                break
            fi
        fi
    done
}

# Display mount options
show_mounts() {
    echo -e "\n${BOLD}${BLUE}━━━ MOUNTED FILESYSTEMS ━━━${NC}"
    echo -e "${CYAN}Current mount points with options:${NC}\n"
    mount | grep -E "^/dev|type" | column -t -s ' ' 2>/dev/null || mount
}

# Display disk space by mount point
show_space_by_mount() {
    echo -e "\n${BOLD}${BLUE}━━━ DISK SPACE BY MOUNT POINT ━━━${NC}"
    
    df -h 2>/dev/null | grep -E "^/dev" | while read line; do
        MOUNT=$(echo "$line" | awk '{print $NF}')
        USAGE=$(echo "$line" | awk '{print $5}' | tr -d '%')
        
        BAR_WIDTH=30
        FILLED=$((USAGE * BAR_WIDTH / 100))
        EMPTY=$((BAR_WIDTH - FILLED))
        
        printf "  ${CYAN}%-20s${NC} [" "$MOUNT"
        for ((i=0; i<FILLED; i++)); do
            if (( USAGE > 85 )); then
                printf "${RED}█${NC}"
            elif (( USAGE > 70 )); then
                printf "${YELLOW}█${NC}"
            else
                printf "${GREEN}█${NC}"
            fi
        done
        for ((i=0; i<EMPTY; i++)); do
            printf "░"
        done
        printf "] ${USAGE}%\n"
    done
}

# Display swap information
show_swap() {
    echo -e "\n${BOLD}${BLUE}━━━ SWAP SPACE ━━━${NC}"
    echo -e "${CYAN}Swap partition/file information:${NC}\n"
    
    swapon --show -f 2>/dev/null | column -t -s ' ' 2>/dev/null
    free -h | grep -E "Mem|Swap"
}

# Display partition tables
show_partition_tables() {
    echo -e "\n${BOLD}${BLUE}━━━ PARTITION TABLES ━━━${NC}"
    echo -e "${CYAN}Parsing partition tables for all block devices:${NC}\n"
    
    for device in /dev/sd[a-z] /dev/nvme*; do
        if [ -b "$device" ]; then
            echo -e "${BLUE}=== $device ===${NC}"
            fdisk -l "$device" 2>/dev/null | head -5
            echo ""
        fi
    done
}

# Display detailed block device info
show_detailed_info() {
    echo -e "\n${BOLD}${BLUE}━━━ DETAILED BLOCK DEVICE INFO ━━━${NC}"
    echo -e "${CYAN}Comprehensive device information:${NC}\n"
    lsblk -i -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL,UUID,MODEL,TRAN,DISC-GRPN,ROTA
}

# Display disk model and serial info
show_disk_models() {
    echo -e "\n${BOLD}${BLUE}━━━ DISK MODEL & SERIAL INFO ━━━${NC}"
    echo -e "${CYAN}Physical disk identifying information:${NC}\n"
    
    for device in /dev/sd[a-z] /dev/nvme*; do
        if [ -b "$device" ]; then
            if command -v smartctl &> /dev/null; then
                MODEL=$(smartctl -i "$device" 2>/dev/null | grep "Device:" | cut -d: -f2 | sed 's/^[ \t]*//')
                SERIAL=$(smartctl -i "$device" 2>/dev/null | grep "Serial Number:" | cut -d: -f2 | sed 's/^[ \t]*//')
                if [ -n "$MODEL" ] || [ -n "$SERIAL" ]; then
                    echo -e "${BLUE}=== $device ===${NC}"
                    echo -e "  Model: ${CYAN}${MODEL}${NC}"
                    echo -e "  Serial: ${CYAN}${SERIAL}${NC}"
                    echo ""
                fi
            fi
        fi
    done
}

# Display unmounted disks
show_unmounted() {
    echo -e "\n${BOLD}${BLUE}━━━ UNMOUNTED DISKS & PARTITIONS ━━━${NC}"
    echo -e "${CYAN}Block devices not currently mounted:${NC}\n"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT | grep -E "disk|part" | grep -v "Mounted"
}

# Display filesystem types
show_filesystem_types() {
    echo -e "\n${BOLD}${BLUE}━━━ FILESYSTEM TYPES ━━━${NC}"
    echo -e "${CYAN}Discovering all filesystem types on block devices:${NC}\n"
    lsblk -r -o FSTYPE | grep -v "^$" | sort | uniq -c | sort -rn
}

# Quick disk overview
show_quick() {
    echo -e "\n${BOLD}${BLUE}━━━ QUICK OVERVIEW ━━━${NC}"
    echo -e "${CYAN}Fast disk information:${NC}\n"
    lsblk -o NAME,SIZE,MOUNTPOINT,FSTYPE
}

# Show help menu
show_help() {
    echo -e "${CYAN}Disk Management and Information Script${NC}"
    echo ""
    echo -e "${BOLD}Usage:${NC} $0 [option]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo "  devices   Show block devices in tree format"
    echo "  usage     Show disk usage summary"
    echo "  partitions Show partition information"
    echo "  tree      Display block device tree"
    echo "  iostat    Show I/O statistics"
    echo "  uuids     Show UUID to device mapping"
    echo "  smart     Show SMART disk health information"
    echo "  mounts    Show mounted filesystems"
    echo "  mountpoints Show disk space by mount point"
    echo "  swap      Show swap space information"
    echo "  tables    Show partition tables"
    echo "  detailed  Show detailed block device info"
    echo "  models    Show disk model and serial info"
    echo "  unmounted Show unmounted disks and partitions"
    echo "  fstypes   Show filesystem types on devices"
    echo "  quick     Quick overview of disk information"
    echo "  help      Show this help message"
    echo ""
    echo -e "${YELLOW}Note: Some features require root privileges for full output.${NC}"
}

# Main function
case "$1" in
    devices|disk|block)
        show_block_devices
        ;;
    usage|df|space)
        show_disk_usage
        show_space_by_mount
        ;;
    partitions|part)
        show_partitions
        ;;
    tree)
        show_block_tree
        ;;
    iostat|io)
        show_io_stats
        ;;
    uuids|uuid)
        show_uuid_map
        ;;
    smart|health)
        show_smart_info
        ;;
    mounts|mount)
        show_mounts
        ;;
    mountpoints|mountpoint)
        show_space_by_mount
        ;;
    swap)
        show_swap
        ;;
    tables|partition-tables)
        show_partition_tables
        ;;
    detailed|info)
        show_detailed_info
        ;;
    models|model|serial)
        show_disk_models
        ;;
    unmounted|unmount)
        show_unmounted
        ;;
    fstypes|filesystem)
        show_filesystem_types
        ;;
    quick)
        show_quick
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        show_quick
        ;;
esac

echo -e "\n${PURPLE}════════════════════════════════════════════════════════════${NC}"
