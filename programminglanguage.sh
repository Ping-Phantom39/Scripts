#!/bin/bash
# Script to download and install the latest versions of Go, Node.js, and C/C++ compilers
# This script works on Ubuntu/Debian-based Linux systems

set -e  # Exit on error

echo "=== Programming Language Installation Script ==="
echo "This script will install: Go, Node.js (with npm), and C/C++ compilers"
echo ""

# Detect OS and architecture
ARCH=$(uname -m)
OS=$(uname -s)
echo "Detected system: $OS on $ARCH"

# Function to check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# ============================================
# 1. INSTALL C/C++ COMPILERS (GCC)
# ============================================
echo ""
echo "=== Installing C/C++ Compilers (GCC) ==="

# Check if gcc is already installed
if command_exists gcc && command_exists g++; then
    echo "GCC is already installed:"
    gcc --version | head -1
    g++ --version | head -1
else
    echo "Installing GCC via apt..."
    
    # Update package lists
    sudo apt-get update -y
    
    # Install build-essential (includes gcc, g++, make, etc.)
    sudo apt-get install -y build-essential
    
    # Verify installation
    echo "GCC installation verified:"
    gcc --version | head -1
    g++ --version | head -1
fi

# ============================================
# 2. INSTALL GO (Golang)
# ============================================
echo ""
echo "=== Installing Go (Golang) ==="

# Check if Go is already installed
if command_exists go; then
    echo "Go is already installed:"
    go version
else
    echo "Downloading the latest version of Go..."
    
    # Get the latest Go version from the official API
    LATEST_GO_VERSION=$(curl -s https://go.dev/downloads | grep -oP 'go\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    
    if [ -z "$LATEST_GO_VERSION" ]; then
        # Fallback: try the release notes page
        LATEST_GO_VERSION=$(curl -s https://go.dev/wiki/Installation | grep -oP 'go\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi
    
    if [ -z "$LATEST_GO_VERSION" ]; then
        echo "Could not determine latest Go version, using a recent version..."
        LATEST_GO_VERSION="1.22.0"
    fi
    
    echo "Latest Go version: $LATEST_GO_VERSION"
    
    # Download Go (Linux amd64)
    DOWNLOAD_URL="https://go.dev/dl/go$LATEST_GO_VERSION.linux-${ARCH}.tar.gz"
    echo "Downloading from: $DOWNLOAD_URL"
    
    # Download to /tmp
    DOWNLOAD_FILE="/tmp/go$LATEST_GO_VERSION.linux-${ARCH}.tar.gz"
    curl -L "$DOWNLOAD_URL" -o "$DOWNLOAD_FILE"
    
    # Remove existing Go installation if present
    if [ -d /usr/local/go ]; then
        sudo rm -rf /usr/local/go
    fi
    
    # Extract to /usr/local
    sudo tar -C /usr/local -xzf "$DOWNLOAD_FILE"
    
    # Clean up download
    rm -f "$DOWNLOAD_FILE"
    
    # Add Go to PATH for current session
    export PATH=$PATH:/usr/local/go/bin
    
    # Add Go to system-wide PATH (permanent)
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile.d/go.sh
    sudo chmod +x /etc/profile.d/go.sh
    
    # Verify installation
    echo "Go installation verified:"
    go version
fi

# ============================================
# 3. INSTALL NODE.JS AND NPM
# ============================================
echo ""
echo "=== Installing Node.js and npm ==="

# Check if Node.js is already installed
if command_exists node && command_exists npm; then
    echo "Node.js and npm are already installed:"
    node --version
    npm --version
else
    echo "Setting up Node.js installation..."
    
    # Add Node.js repository
    # Using the official NodeSource repository for latest LTS version
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    
    # Install Node.js
    echo "Installing Node.js from NodeSource repository..."
    sudo apt-get install -y nodejs
    
    # Verify installation
    echo "Node.js installation verified:"
    node --version
    npm --version
    
    # Optional: Install nvm for managing multiple Node.js versions
    echo "Installing nvm (Node Version Manager) for easy version management..."
    if [ ! -d ~/.nvm ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        echo "nvm installed successfully"
    fi
fi

# ============================================
# 4. VERIFY ALL INSTALLATIONS
# ============================================
echo ""
echo "=== Final Verification ==="
echo ""
echo "GCC/G++ version:"
gcc --version | head -1
g++ --version | head -1

echo ""
echo "Go version:"
go version

echo ""
echo "Node.js version:"
node --version

echo ""
echo "npm version:"
npm --version

echo ""
echo "=== Installation Complete ==="
echo "All programming languages have been successfully installed!"
echo ""
echo "To use the languages, you may need to restart your shell or run:"
echo "  source /etc/profile.d/go.sh"
echo ""
echo "Test examples:"
echo "  go version"
echo "  node --version"
echo "  gcc --version"
