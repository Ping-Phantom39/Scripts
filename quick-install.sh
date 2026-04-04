#!/bin/bash
# Quick Install Script
# Install essential DevOps tools in one go

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

show_help() {
    echo -e "${CYAN}Quick Install Script for DevOps Tools${NC}"
    echo ""
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  all       Install all essential tools"
    echo "  terminal  Install terminal enhancements (zoxide, fzf, btop, bat, exa, ripgrep)"
    echo "  dev       Install development tools (git, node, python, terraform)"
    echo "  docker    Install Docker and Docker Compose"
    echo "  k8s       Install Kubernetes tools (kubectl, k9s, helm)"
    echo "  monitoring Install monitoring tools (htop, iotop, ncdu)"
    echo "  list      Show what would be installed"
    echo ""
}

check_install() {
    local pkg=$1
    if command -v $pkg &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $pkg (already installed)"
        return 0
    else
        echo -e "  ${YELLOW}+${NC} $pkg"
        return 1
    fi
}

install_terminal() {
    echo -e "${BOLD}${BLUE}Installing terminal enhancements...${NC}\n"
    
    sudo apt update -qq
    
    # Tools to install
    TOOLS="zoxide fzf btop bat exa ripgrep fd-find jq tldr"
    
    for tool in $TOOLS; do
        if check_install $tool; then
            continue
        fi
        sudo apt install -y $tool
    done
    
    # Setup fzf keybindings
    if [ ! -f ~/.fzf.bash ]; then
        echo -e "\n${CYAN}Setting up fzf keybindings...${NC}"
        /usr/share/doc/fzf/examples/key-bindings.bash &>/dev/null || true
    fi
    
    echo -e "\n${GREEN}✓ Terminal tools installed!${NC}"
    echo -e "${YELLOW}Note: Add 'eval \"$(zoxide init bash)\"' to your .bashrc${NC}"
}

install_dev() {
    echo -e "${BOLD}${BLUE}Installing development tools...${NC}\n"
    
    sudo apt update -qq
    
    # Git and build essentials
    sudo apt install -y git build-essential
    
    # Node.js (using NodeSource)
    if ! command -v node &> /dev/null; then
        echo -e "${CYAN}Installing Node.js...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
    fi
    
    # Python and pip
    sudo apt install -y python3 python3-pip python3-venv
    
    # Terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${CYAN}Installing Terraform...${NC}"
        wget -q https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
        sudo unzip -o terraform_1.7.0_linux_amd64.zip -d /usr/local/bin/
        rm terraform_1.7.0_linux_amd64.zip
    fi
    
    echo -e "\n${GREEN}✓ Development tools installed!${NC}"
}

install_docker() {
    echo -e "${BOLD}${BLUE}Installing Docker...${NC}\n"
    
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✓ Docker already installed${NC}"
        return
    fi
    
    # Add Docker's official GPG key
    sudo apt update -qq
    sudo apt install -y ca-certificates curl gnupg
    
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update -qq
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    echo -e "\n${GREEN}✓ Docker installed!${NC}"
    echo -e "${YELLOW}Note: Log out and back in for docker group to take effect${NC}"
}

install_k8s() {
    echo -e "${BOLD}${BLUE}Installing Kubernetes tools...${NC}\n"
    
    # kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${CYAN}Installing kubectl...${NC}"
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi
    
    # Helm
    if ! command -v helm &> /dev/null; then
        echo -e "${CYAN}Installing Helm...${NC}"
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | sudo bash
    fi
    
    # k9s
    if ! command -v k9s &> /dev/null; then
        echo -e "${CYAN}Installing k9s...${NC}"
        curl -sS https://webinstall.dev/k9s | bash
    fi
    
    echo -e "\n${GREEN}✓ Kubernetes tools installed!${NC}"
}

install_monitoring() {
    echo -e "${BOLD}${BLUE}Installing monitoring tools...${NC}\n"
    
    sudo apt update -qq
    sudo apt install -y htop iotop ncdu nethogs glances
    
    echo -e "\n${GREEN}✓ Monitoring tools installed!${NC}"
}

show_list() {
    echo -e "${BOLD}${CYAN}Tools that can be installed:${NC}\n"
    
    echo -e "${BLUE}Terminal Enhancements:${NC}"
    echo "  zoxide    - Smart cd command"
    echo "  fzf       - Fuzzy finder"
    echo "  btop      - System monitor"
    echo "  bat       - Cat with syntax highlighting"
    echo "  exa       - Modern ls replacement"
    echo "  ripgrep   - Fast grep"
    echo "  fd-find   - Fast find"
    echo "  jq        - JSON processor"
    
    echo -e "\n${BLUE}Development:${NC}"
    echo "  git       - Version control"
    echo "  node      - Node.js runtime"
    echo "  python3   - Python runtime"
    echo "  terraform - Infrastructure as code"
    
    echo -e "\n${BLUE}Docker:${NC}"
    echo "  docker    - Container runtime"
    echo "  docker-compose - Container orchestration"
    
    echo -e "\n${BLUE}Kubernetes:${NC}"
    echo "  kubectl   - K8s CLI"
    echo "  helm      - K8s package manager"
    echo "  k9s       - K8s terminal UI"
    
    echo -e "\n${BLUE}Monitoring:${NC}"
    echo "  htop      - Process viewer"
    echo "  iotop     - I/O monitor"
    echo "  ncdu      - Disk usage"
    echo "  nethogs   - Network usage per process"
    echo "  glances   - System monitoring"
}

# Main
case "$1" in
    all)
        install_terminal
        install_dev
        install_docker
        install_k8s
        install_monitoring
        ;;
    terminal)   install_terminal ;;
    dev)        install_dev ;;
    docker)     install_docker ;;
    k8s)        install_k8s ;;
    monitoring) install_monitoring ;;
    list)       show_list ;;
    *)          show_help ;;
esac