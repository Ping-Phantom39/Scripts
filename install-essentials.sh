#!/bin/bash
# Linux Essentials Installer
# Installs the most essential and useful applications for Linux users
# Categories: Terminal, Dev Tools, CLI Utilities, DevOps, Productivity

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Log file
LOG_FILE="/tmp/install-essentials.log"
echo "Install started at $(date)" > "$LOG_FILE"

log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

print_header() {
    echo -e "\n${PURPLE}══════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}║${NC} ${BOLD}${CYAN}$1${NC}"
    echo -e "${PURPLE}══════════════════════════════════════════════════════════${NC}\n"
}

print_category() {
    echo -e "\n${BOLD}${BLUE}━━━ $1 ━━━${NC}"
}

check_install() {
    command -v "$1" &> /dev/null
}

install_apt() {
    local pkg="$1"
    if ! check_install "$pkg"; then
        echo -e "  ${YELLOW}Installing $pkg...${NC}"
        sudo apt install -y "$pkg" &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} $pkg installed" || \
            echo -e "  ${RED}✗${NC} Failed to install $pkg"
    else
        echo -e "  ${GREEN}✓${NC} $pkg (already installed)"
    fi
}

install_via_script() {
    local name="$1"
    local script="$2"
    
    if ! check_install "$name"; then
        echo -e "  ${YELLOW}Installing $name...${NC}"
        eval "$script" &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} $name installed" || \
            echo -e "  ${RED}✗${NC} Failed to install $name"
    else
        echo -e "  ${GREEN}✓${NC} $name (already installed)"
    fi
}

# ============================================
# MAIN INSTALLATION
# ============================================

show_help() {
    echo -e "${CYAN}Linux Essentials Installer${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  all         Install everything"
    echo "  terminal    Terminal & shell enhancements"
    echo "  dev         Development tools"
    echo "  cli         CLI utilities (modern replacements)"
    echo "  devops      DevOps tools (Docker, K8s, Terraform)"
    echo "  security    Security tools"
    echo "  productivity Productivity & documentation"
    echo "  media       Media & download tools"
    echo "  list        Show all packages to install"
    echo ""
}

# ============================================
# TERMINAL & SHELL
# ============================================
install_terminal() {
    print_header "TERMINAL & SHELL ENHANCEMENTS"
    
    print_category "Shell & Prompt"
    install_apt "zsh"
    install_apt "fonts-powerline"
    
    # Starship prompt
    if ! check_install "starship"; then
        echo -e "  ${YELLOW}Installing starship...${NC}"
        curl -sS https://starship.rs/install.sh | sudo sh -s -- -y &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} starship installed" || \
            echo -e "  ${RED}✗${NC} Failed to install starship"
    else
        echo -e "  ${GREEN}✓${NC} starship (already installed)"
    fi
    
    print_category "Terminal Multiplexers"
    install_apt "tmux"
    install_apt "screen"
    
    print_category "Terminal Emulators"
    install_apt "tilix"
    
    print_category "Modern Replacements"
    install_apt "zoxide"       # Smart cd
    install_apt "fzf"          # Fuzzy finder
    install_apt "bat"          # Better cat
    install_apt "eza"          # Better ls
    install_apt "ripgrep"      # Better grep
    install_apt "fd-find"      # Better find
    
    # Link fd
    if [ ! -f /usr/local/bin/fd ]; then
        sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null
    fi
    
    echo -e "\n${CYAN}Note: Add to .bashrc or .zshrc:${NC}"
    echo -e "  eval \"\$(zoxide init bash)\""
    echo -e "  eval \"\$(fzf --bash)\""
}

# ============================================
# DEVELOPMENT TOOLS
# ============================================
install_dev() {
    print_header "DEVELOPMENT TOOLS"
    
    print_category "Build Essentials"
    sudo apt update -qq
    install_apt "build-essential"
    install_apt "pkg-config"
    install_apt "autoconf"
    install_apt "automake"
    install_apt "libtool"
    install_apt "cmake"
    
    print_category "Version Control"
    install_apt "git"
    install_apt "git-lfs"
    install_apt "tig"           # Text-mode git interface
    install_apt "lazygit"       # Terminal UI for git
    
    # Git-delta (better diff)
    if ! check_install "delta"; then
        echo -e "  ${YELLOW}Installing git-delta...${NC}"
        wget -q https://github.com/dandavison/delta/releases/download/v0.16.5/git-delta_0.16.5_amd64.deb -O /tmp/delta.deb
        sudo dpkg -i /tmp/delta.deb &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} git-delta installed" || \
            echo -e "  ${RED}✗${NC} Failed to install git-delta"
        rm -f /tmp/delta.deb
    else
        echo -e "  ${GREEN}✓${NC} git-delta (already installed)"
    fi
    
    print_category "Editors & IDEs"
    install_apt "neovim"
    install_apt "vim"
    
    # VS Code CLI
    if ! check_install "code"; then
        echo -e "  ${YELLOW}Installing VS Code...${NC}"
        sudo snap install code --classic &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} VS Code installed" || \
            echo -e "  ${RED}✗${NC} Failed to install VS Code"
    else
        echo -e "  ${GREEN}✓${NC} VS Code (already installed)"
    fi
    
    print_category "Languages & Runtimes"
    # Node.js
    if ! check_install "node"; then
        echo -e "  ${YELLOW}Installing Node.js LTS...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - &>> "$LOG_FILE"
        sudo apt install -y nodejs &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} Node.js installed" || \
            echo -e "  ${RED}✗${NC} Failed to install Node.js"
    else
        echo -e "  ${GREEN}✓${NC} Node.js $(node -v) (already installed)"
    fi
    
    # Python
    install_apt "python3"
    install_apt "python3-pip"
    install_apt "python3-venv"
    install_apt "python3-dev"
    
    # pip packages
    pip3 install --user httpie requests beautifulsoup4 &>> "$LOG_FILE"
    
    # Go
    if ! check_install "go"; then
        echo -e "  ${YELLOW}Installing Go...${NC}"
        sudo snap install go --classic &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} Go installed" || \
            echo -e "  ${RED}✗${NC} Failed to install Go"
    else
        echo -e "  ${GREEN}✓${NC} Go $(go version | awk '{print $3}') (already installed)"
    fi
    
    print_category "JSON/YAML Tools"
    install_apt "jq"            # JSON processor
    install_apt "yq"            # YAML processor
    
    print_category "Other Dev Tools"
    install_apt "make"
    install_apt "jq"
    install_apt "shellcheck"    # Shell script linter
    install_apt "shfmt"         # Shell formatter
}

# ============================================
# CLI UTILITIES
# ============================================
install_cli() {
    print_header "CLI UTILITIES"
    
    print_category "System Monitoring"
    install_apt "htop"
    install_apt "btop"
    install_apt "atop"
    install_apt "iotop"
    install_apt "ncdu"          # Disk usage
    install_apt "duf"           # Disk usage (modern)
    install_apt "glances"
    install_apt "nethogs"        # Network per process
    
    print_category "File Management"
    install_apt "ranger"        # File manager
    install_apt "nnn"           # Minimal file manager
    install_apt "trash-cli"      # Trash instead of rm
    install_apt "zip"
    install_apt "unzip"
    install_apt "p7zip-full"
    install_apt "rsync"
    
    print_category "Text Processing"
    install_apt "ripgrep"       # grep alternative
    install_apt "silversearcher-ag"  # ag - code search
    install_apt "ack"
    install_apt "sd"            # sed alternative (if available)
    
    print_category "Network Tools"
    install_apt "curl"
    install_apt "wget"
    install_apt "nmap"
    install_apt "net-tools"
    install_apt "dnsutils"
    install_apt "iptraf-ng"
    install_apt "mtr"           # Better traceroute
    install_apt "socat"
    install_apt "netcat-openbsd"
    
    print_category "Process Management"
    install_apt "procs"         # Better ps
    install_apt "htop"
    install_apt "killall"
    
    print_category "Miscellaneous"
    install_apt "tree"
    install_apt "file"
    install_apt "xxd"
    install_apt "xxd"
    install_apt "strace"
    install_apt "ltrace"
    install_apt "time"
}

# ============================================
# DEVOPS TOOLS
# ============================================
install_devops() {
    print_header "DEVOPS TOOLS"
    
    print_category "Containerization"
    # Docker
    if ! check_install "docker"; then
        echo -e "  ${YELLOW}Installing Docker...${NC}"
        sudo apt install -y ca-certificates curl gnupg &>> "$LOG_FILE"
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt update -qq
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} Docker installed" || \
            echo -e "  ${RED}✗${NC} Failed to install Docker"
        
        sudo usermod -aG docker $USER 2>/dev/null
    else
        echo -e "  ${GREEN}✓${NC} Docker (already installed)"
    fi
    
    print_category "Kubernetes"
    # kubectl
    if ! check_install "kubectl"; then
        echo -e "  ${YELLOW}Installing kubectl...${NC}"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm -f kubectl
        echo -e "  ${GREEN}✓${NC} kubectl installed"
    else
        echo -e "  ${GREEN}✓${NC} kubectl (already installed)"
    fi
    
    # Helm
    if ! check_install "helm"; then
        echo -e "  ${YELLOW}Installing Helm...${NC}"
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sudo bash &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} Helm installed" || \
            echo -e "  ${RED}✗${NC} Failed to install Helm"
    else
        echo -e "  ${GREEN}✓${NC} Helm (already installed)"
    fi
    
    # k9s
    if ! check_install "k9s"; then
        echo -e "  ${YELLOW}Installing k9s...${NC}"
        curl -sS https://webinstall.dev/k9s | bash &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} k9s installed" || \
            echo -e "  ${RED}✗${NC} Failed to install k9s"
    else
        echo -e "  ${GREEN}✓${NC} k9s (already installed)"
    fi
    
    print_category "Infrastructure as Code"
    # Terraform
    if ! check_install "terraform"; then
        echo -e "  ${YELLOW}Installing Terraform...${NC}"
        wget -q https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip -O /tmp/terraform.zip
        sudo unzip -o /tmp/terraform.zip -d /usr/local/bin/
        rm -f /tmp/terraform.zip
        echo -e "  ${GREEN}✓${NC} Terraform installed"
    else
        echo -e "  ${GREEN}✓${NC} Terraform (already installed)"
    fi
    
    # Ansible
    install_apt "ansible"
    
    print_category "CI/CD"
    install_apt "gh"            # GitHub CLI
    
    print_category "Cloud Tools"
    install_apt "awscli"
    # Google Cloud SDK
    if ! check_install "gcloud"; then
        echo -e "  ${YELLOW}Installing Google Cloud SDK...${NC}"
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        sudo apt update -qq
        sudo apt install -y google-cloud-sdk &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} gcloud installed" || \
            echo -e "  ${YELLOW}-${NC} gcloud installation skipped"
    else
        echo -e "  ${GREEN}✓${NC} gcloud (already installed)"
    fi
}

# ============================================
# SECURITY TOOLS
# ============================================
install_security() {
    print_header "SECURITY TOOLS"
    
    print_category "Encryption"
    install_apt "gnupg"
    install_apt "age"           # Modern encryption
    install_apt "pass"          # Password manager
    install_apt "openssl"
    
    print_category "SSH Tools"
    install_apt "openssh-client"
    install_apt "sshpass"
    install_apt "keychain"
    
    print_category "Scanning"
    install_apt "nmap"
    install_apt "nikto"         # Web scanner
    install_apt "lynis"         # Security auditing
    
    print_category "Network Security"
    install_apt "tcpdump"
    install_apt "wireshark"     # Network analyzer (CLI: tshark)
    install_apt "dsniff"
    
    print_category "Password Tools"
    install_apt "john"          # John the Ripper
    install_apt "hashcat"
    
    print_category "Other Security"
    install_apt "fail2ban"
    install_apt "ufw"           # Firewall
}

# ============================================
# PRODUCTIVITY
# ============================================
install_productivity() {
    print_header "PRODUCTIVITY & DOCUMENTATION"
    
    print_category "Documentation"
    install_apt "tldr"          # Simplified man pages
    install_apt "man-db"
    install_apt "cheat"         # Cheat sheets (if available)
    
    # tealdeer (fast tldr)
    if ! check_install "tldr"; then
        echo -e "  ${YELLOW}Installing tealdeer (fast tldr)...${NC}"
        sudo snap install tealdeer &>> "$LOG_FILE" && \
            echo -e "  ${GREEN}✓${NC} tealdeer installed" || \
            echo -e "  ${YELLOW}-${NC} tealdeer skipped"
    fi
    
    print_category "Notes & Organization"
    install_apt "taskwarrior"    # Task management
    install_apt "timewarrior"   # Time tracking
    install_apt "jrnl"          # Journal
    
    print_category "Calendar & Time"
    install_apt "calcurse"      # Calendar
    install_apt "remind"        # Reminders
    
    print_category "File Conversion"
    install_apt "pandoc"        # Document converter
    
    print_category "PDF Tools"
    install_apt "poppler-utils" # PDF tools
    install_apt "pdftk"
    
    print_category "Multimedia CLI"
    install_apt "ffmpeg"
    install_apt "imagemagick"
    install_apt "yt-dlp"        # YouTube downloader
    
    print_category "Fun Stuff"
    install_apt "cowsay"
    install_apt "fortune"
    install_apt "figlet"
    install_apt "lolcat"
    install_apt "neofetch"
    install_apt "fastfetch"     # Faster neofetch
}

# ============================================
# SHOW PACKAGES LIST
# ============================================
show_list() {
    print_header "PACKAGES TO INSTALL"
    
    echo -e "${BOLD}${CYAN}Terminal & Shell:${NC}"
    echo "  zsh, starship, tmux, screen, zoxide, fzf, bat, eza, ripgrep, fd-find"
    
    echo -e "\n${BOLD}${CYAN}Development:${NC}"
    echo "  build-essential, git, lazygit, neovim, node.js, python3, go, jq, yq"
    
    echo -e "\n${BOLD}${CYAN}CLI Utilities:${NC}"
    echo "  htop, btop, ncdu, duf, glances, nethogs, ranger, trash-cli, curl, wget"
    echo "  nmap, mtr, procs, tree, shellcheck"
    
    echo -e "\n${BOLD}${CYAN}DevOps:${NC}"
    echo "  docker, kubectl, helm, k9s, terraform, ansible, gh, awscli"
    
    echo -e "\n${BOLD}${CYAN}Security:${NC}"
    echo "  gnupg, age, pass, nmap, wireshark, fail2ban, ufw"
    
    echo -e "\n${BOLD}${CYAN}Productivity:${NC}"
    echo "  tldr, taskwarrior, pandoc, ffmpeg, yt-dlp, neofetch"
    
    echo -e "\n${YELLOW}Run './install-essentials.sh all' to install everything${NC}"
}

# ============================================
# SETUP FUNCTIONS
# ============================================
setup_starship() {
    echo -e "\n${BOLD}${BLUE}━━━ SETTING UP STARSHIP ━━━${NC}"
    
    if check_install "starship"; then
        # Add to bashrc if not already there
        if ! grep -q "starship init bash" ~/.bashrc; then
            echo -e "\n# Starship prompt" >> ~/.bashrc
            echo 'eval "$(starship init bash)"' >> ~/.bashrc
            echo -e "  ${GREEN}✓${NC} Added starship to .bashrc"
        else
            echo -e "  ${GREEN}✓${NC} Starship already configured"
        fi
        
        # Create starship config
        mkdir -p ~/.config
        cat > ~/.config/starship.toml << 'STARSHIP'
# Starship config
add_newline = false

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = " "

[git_status]
conflicted = "⚔ "
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕"
untracked = "?"
stashed = "*"
modified = "!"
staged = "+"
renamed = "»"
deleted = "✘"

[docker_context]
symbol = "🐳 "

[nodejs]
symbol = "⬢ "

[python]
symbol = "🐍 "

[rust]
symbol = "🦀 "
STARSHIP
        echo -e "  ${GREEN}✓${NC} Created starship config"
    fi
}

setup_zoxide() {
    echo -e "\n${BOLD}${BLUE}━━━ SETTING UP ZOXIDE ━━━${NC}"
    
    if check_install "zoxide"; then
        if ! grep -q "zoxide init" ~/.bashrc; then
            echo -e "\n# Zoxide (smart cd)" >> ~/.bashrc
            echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
            echo -e "  ${GREEN}✓${NC} Added zoxide to .bashrc"
        else
            echo -e "  ${GREEN}✓${NC} Zoxide already configured"
        fi
    fi
}

setup_fzf() {
    echo -e "\n${BOLD}${BLUE}━━━ SETTING UP FZF ━━━${NC}"
    
    if check_install "fzf"; then
        if ! grep -q "fzf --bash" ~/.bashrc; then
            echo -e "\n# FZF key bindings" >> ~/.bashrc
            echo 'eval "$(fzf --bash)"' >> ~/.bashrc
            echo -e "  ${GREEN}✓${NC} Added fzf to .bashrc"
        else
            echo -e "  ${GREEN}✓${NC} FZF already configured"
        fi
    fi
}

setup_aliases() {
    echo -e "\n${BOLD}${BLUE}━━━ SETTING UP ALIASES ━━━${NC}"
    
    if ! grep -q "# Custom aliases" ~/.bashrc; then
        cat >> ~/.bashrc << 'ALIASES'

# ============================================
# Custom Aliases
# ============================================
# Modern replacements
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias cd='z'

# Git shortcuts
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias gf='git fetch'
alias gb='git branch'
alias gco='git checkout'

# Docker shortcuts
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dimg='docker images'
alias dlog='docker logs'
alias drm='docker rm'
alias drmi='docker rmi'
alias dex='docker exec -it'
alias dclean='docker system prune -af'

# Kubernetes shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgn='kubectl get nodes'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs'

# System
alias ports='sudo netstat -tlnp'
alias myip='curl -s ifconfig.me'
alias mem='free -h'
alias disk='df -h'
alias temp='watch -n 1 sensors'
alias ports='ss -tlnp'
alias listen='ss -tulpn'

# Quick scripts
alias sys='~/Scripts/system-resources.sh'
alias health='~/Scripts/server-health-check.sh'
alias dock='~/Scripts/docker-manage.sh'
alias backup='~/Scripts/backup-configs.sh'
alias ssl='~/Scripts/ssl-monitor.sh'
alias logs='~/Scripts/log-analyzer.sh'
ALIASES
        echo -e "  ${GREEN}✓${NC} Added aliases to .bashrc"
    else
        echo -e "  ${GREEN}✓${NC} Aliases already configured"
    fi
}

# ============================================
# MAIN
# ============================================

# Check for root/sudo
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo -e "${YELLOW}Note: This script requires sudo for some installations${NC}"
fi

case "$1" in
    all)
        install_terminal
        install_dev
        install_cli
        install_devops
        install_security
        install_productivity
        setup_starship
        setup_zoxide
        setup_fzf
        setup_aliases
        echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✓ All installations complete!${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
        echo -e "\n${YELLOW}Run 'source ~/.bashrc' to apply changes${NC}"
        ;;
    terminal)
        install_terminal
        setup_starship
        setup_zoxide
        setup_fzf
        ;;
    dev)       install_dev ;;
    cli)       install_cli ;;
    devops)    install_devops ;;
    security)  install_security ;;
    productivity) install_productivity ;;
    list)      show_list ;;
    *)
        show_help
        ;;
esac

echo -e "\n${CYAN}Log file: $LOG_FILE${NC}"