#!/bin/bash
# User Manager Script
# Simple user management utilities for Linux

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
    echo -e "${CYAN}User Manager Script${NC}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list               List all users"
    echo "  show USER          Show user details"
    echo "  add USER           Add a new user"
    echo "  del USER           Delete a user"
    echo "  lock USER          Lock a user account"
    echo "  unlock USER        Unlock a user account"
    echo "  passwd USER        Change user password"
    echo "  groups USER        Show user groups"
    echo "  lastlog            Show last logins"
    echo "  active             Show currently logged in users"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 add john --shell /bin/bash"
    echo "  $0 del john --remove-home"
    echo "  $0 lock john"
    echo "  $0 passwd john"
}

get_valid_users() {
    # Get valid users (uid >= 1000, excluding nobody)
    awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd
}

get_all_users() {
    # Get all users (uid >= 0)
    awk -F: '$3 >= 0 {print $1}' /etc/passwd
}

list_users() {
    echo -e "${BOLD}${BLUE}━━━ SYSTEM USERS ━━━${NC}"
    
    local count=0
    printf "%-20s %-15s %-15s %-30s\n" "Username" "UID" "Home Directory" "Shell"
    printf "%-20s %-15s %-15s %-30s\n" "--------" "---" "--------------" "-----"
    
    while IFS=: read -r user pass uid gid desc home shell; do
        if [[ $uid -ge 1000 ]] || [[ $uid -eq 0 ]]; then
            printf "%-20s %-15s %-15s %-30s\n" "$user" "$uid" "$home" "$shell"
            ((count++))
        fi
    done < /etc/passwd
    
    echo ""
    echo -e "${CYAN}Total users:${NC} $count"
}

show_user() {
    local user="$1"
    
    if [[ -z "$user" ]]; then
        echo -e "${RED}Error: Please specify a username${NC}"
        exit 1
    fi
    
    local user_info=$(getent passwd "$user" 2>/dev/null)
    
    if [[ -z "$user_info" ]]; then
        echo -e "${RED}Error: User '$user' does not exist${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ USER DETAILS: $user ━━━${NC}"
    echo -e "${CYAN}Username:${NC} $(echo "$user_info" | cut -d: -f1)"
    echo -e "${CYAN}UID:${NC} $(echo "$user_info" | cut -d: -f3)"
    echo -e "${CYAN}GID:${NC} $(echo "$user_info" | cut -d: -f4)"
    echo -e "${CYAN}Home:${NC} $(echo "$user_info" | cut -d: -f6)"
    echo -e "${CYAN}Shell:${NC} $(echo "$user_info" | cut -d: -f7)"
    echo -e "${CYAN}Description:${NC} $(echo "$user_info" | cut -d: -f5)"
    
    # User groups
    echo -e "\n${BOLD}${PURPLE}Groups:${NC}"
    groups "$user"
    
    # Last login
    echo -e "\n${BOLD}${PURPLE}Last Login:${NC}"
    lastlog -u "$user" | grep "$user" || echo -e "${YELLOW}No login records${NC}"
    
    # Account status
    local status=$(passwd -S "$user" 2>/dev/null | awk '{print $2}')
    echo -e "\n${BOLD}${PURPLE}Account Status:${NC} ${CYAN}${status}${NC}"
    
    # Login hours
    if [[ -f "/etc/login.defs" ]]; then
        echo -e "\n${BOLD}${PURPLE}Login Hours:${NC}"
        if command -v login &> /dev/null; then
            login --help 2>&1 | grep -A 10 "login hours" || echo -e "${YELLOW}Not configured${NC}"
        fi
    fi
}

add_user() {
    local user="$1"
    shift
    local options=""
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --shell)
                options="$options -s $2"
                shift 2
                ;;
            --home)
                options="$options -d $2"
                shift 2
                ;;
            --create-home)
                options="$options -m"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [[ -z "$user" ]]; then
        echo -e "${RED}Error: Please specify a username${NC}"
        exit 1
    fi
    
    if id "$user" &>/dev/null; then
        echo -e "${RED}Error: User '$user' already exists${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ ADDING USER: $user ━━━${NC}"
    
    if command -v useradd &>/dev/null; then
        sudo useradd $options "$user" && echo -e "${GREEN}User created successfully!${NC}"
        echo -e "${YELLOW}You can now set a password with: sudo passwd $user${NC}"
    else
        echo -e "${RED}Error: useradd command not found${NC}"
        exit 1
    fi
}

del_user() {
    local user="$1"
    
    if [[ -z "$user" ]]; then
        echo -e "${RED}Error: Please specify a username${NC}"
        exit 1
    fi
    
    if ! id "$user" &>/dev/null; then
        echo -e "${RED}Error: User '$user' does not exist${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ DELETING USER: $user ━━━${NC}"
    echo -e "${YELLOW}Warning: This will permanently delete the user account${NC}"
    
    # Remove user
    if command -v userdel &>/dev/null; then
        sudo userdel "$user" && echo -e "${GREEN}User deleted successfully!${NC}"
    else
        echo -e "${RED}Error: userdel command not found${NC}"
        exit 1
    fi
}

lock_user() {
    local user="$1"
    
    if [[ -z "$user" ]]; then
        echo -e "${RED}Error: Please specify a username${NC}"
        exit 1
    fi
    
    if ! id "$user" &>/dev/null; then
        echo -e "${RED}Error: User '$user' does not exist${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ LOCKING USER: $user ━━━${NC}"
    
    if command -v usermod &>/dev/null; then
        sudo usermod -L "$user" && echo -e "${GREEN}User locked successfully!${NC}"
    else
        echo -e "${RED}Error: usermod command not found${NC}"
        exit 1
    fi
}

unlock_user() {
    local user="$1"
    
    if [[ -z "$user" ]]; then
        echo -e "${RED}Error: Please specify a username${NC}"
        exit 1
    fi
    
    if ! id "$user" &>/dev/null; then
        echo -e "${RED}Error: User '$user' does not exist${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ UNLOCKING USER: $user ━━━${NC}"
    
    if command -v usermod &>/dev/null; then
        sudo usermod -U "$user" && echo -e "${GREEN}User unlocked successfully!${NC}"
    else
        echo -e "${RED}Error: usermod command not found${NC}"
        exit 1
    fi
}

change_password() {
    local user="$1"
    
    if [[ -z "$user" ]]; then
        echo -e "${RED}Error: Please specify a username${NC}"
        exit 1
    fi
    
    if ! id "$user" &>/dev/null; then
        echo -e "${RED}Error: User '$user' does not exist${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ CHANGING PASSWORD FOR: $user ━━━${NC}"
    
    if command -v passwd &>/dev/null; then
        sudo passwd "$user" && echo -e "${GREEN}Password changed successfully!${NC}"
    else
        echo -e "${RED}Error: passwd command not found${NC}"
        exit 1
    fi
}

show_groups() {
    local user="$1"
    
    if [[ -z "$user" ]]; then
        echo -e "${RED}Error: Please specify a username${NC}"
        exit 1
    fi
    
    if ! id "$user" &>/dev/null; then
        echo -e "${RED}Error: User '$user' does not exist${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}━━━ GROUP MEMBERSHIP: $user ━━━${NC}"
    groups "$user"
}

show_lastlogins() {
    echo -e "${BOLD}${BLUE}━━━ LAST LOGINS ━━━${NC}"
    
    if command -v lastlog &>/dev/null; then
        lastlog | grep -v "Never" | head -20
    else
        echo -e "${YELLOW}lastlog command not available${NC}"
        # Fallback: show wtmp
        last -20 2>/dev/null || echo -e "${YELLOW}No login records available${NC}"
    fi
}

show_active() {
    echo -e "${BOLD}${BLUE}━━━ ACTIVE USERS ━━━${NC}"
    
    if command -v who &>/dev/null; then
        who -u
    elif command -v users &>/dev/null; then
        echo -e "${YELLOW}Currently logged in:${NC}"
        users
    else
        echo -e "${YELLOW}No command available to show active users${NC}"
    fi
}

# Parse arguments
case "$1" in
    list)
        list_users
        ;;
    show)
        shift
        show_user "$@"
        ;;
    add)
        shift
        add_user "$@"
        ;;
    del)
        shift
        del_user "$@"
        ;;
    lock)
        shift
        lock_user "$@"
        ;;
    unlock)
        shift
        unlock_user "$@"
        ;;
    passwd)
        shift
        change_password "$@"
        ;;
    groups)
        shift
        show_groups "$@"
        ;;
    lastlog)
        show_lastlogins
        ;;
    active)
        show_active
        ;;
    -h|--help|help|"")
        show_help
        ;;
    *)
        show_help
        ;;
esac
