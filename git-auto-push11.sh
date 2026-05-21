#!/bin/bash

# ================================
# 🔐 Ultimate Git Auto-Push Script
# ================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Git Auto-Push (Stable) ===${NC}"
echo ""

# -------------------------------
# Check Git
# -------------------------------
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed.${NC}"
    exit 1
fi

# -------------------------------
# Input
# -------------------------------
read -p "📝 Commit message: " COMMIT_MSG
[ -z "$COMMIT_MSG" ] && { echo -e "${RED}❌ Required.${NC}"; exit 1; }

read -p "🌐 Remote URL (leave empty to skip): " REMOTE_URL

read -p "📂 Files to add (default '.'): " FILES
FILES=${FILES:-"."}

echo ""
echo -e "${YELLOW}⚙️ Running...${NC}"
echo ""

# -------------------------------
# Init repo
# -------------------------------
if [ ! -d ".git" ]; then
    echo "[1/7] Initializing..."
    git init
else
    echo "[1/7] Repo exists ✓"
fi

# -------------------------------
# .gitignore
# -------------------------------
if [ ! -f ".gitignore" ]; then
    echo "[2/7] Creating .gitignore..."
    cat > .gitignore << EOF
# Sensitive
git-auto-push.sh
*.env
*.pem
*.key

# OS
.DS_Store
Thumbs.db

# Logs
*.log
EOF
    git add .gitignore
    echo "✓ .gitignore created"
else
    echo "[2/7] .gitignore exists ✓"
fi

# -------------------------------
# Add files
# -------------------------------
echo "[3/7] Staging..."
git add $FILES

# -------------------------------
# Commit
# -------------------------------
if git diff --cached --quiet; then
    echo "[4/7] Nothing to commit ✓"
else
    echo "[4/7] Committing..."
    git commit -m "$COMMIT_MSG"
    echo "✓ Commit done"
fi

# -------------------------------
# Branch detection
# -------------------------------
echo "[5/7] Detecting branch..."

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# If detached HEAD or empty repo
if [ "$CURRENT_BRANCH" = "HEAD" ]; then
    CURRENT_BRANCH="main"
    git checkout -b "$CURRENT_BRANCH"
    echo "✓ Created branch: $CURRENT_BRANCH"
else
    echo "✓ Current branch: $CURRENT_BRANCH"
fi

# -------------------------------
# Remote handling
# -------------------------------
echo "[6/7] Handling remote..."

if [ -n "$REMOTE_URL" ]; then

    # Prevent token in HTTPS URL
    if [[ "$REMOTE_URL" == *"@"*"github.com"* && "$REMOTE_URL" == *"http"* ]]; then
        echo -e "${RED}❌ Token in URL not allowed.${NC}"
        exit 1
    fi

    if git remote get-url origin &>/dev/null; then
        CURRENT_URL=$(git remote get-url origin)

        if [ "$CURRENT_URL" != "$REMOTE_URL" ]; then
            echo "⚠️ Remote mismatch"
            echo "Current: $CURRENT_URL"
            echo "New    : $REMOTE_URL"

            read -p "Update remote? (y/n): " UPDATE
            if [ "$UPDATE" = "y" ]; then
                git remote set-url origin "$REMOTE_URL"
                echo "✓ Remote updated"
            else
                echo "→ Keeping existing remote"
            fi
        else
            echo "✓ Remote correct"
        fi
    else
        git remote add origin "$REMOTE_URL"
        echo "✓ Remote added"
    fi
else
    echo "→ Skipping remote setup"
fi

# -------------------------------
# Push
# -------------------------------
echo "[7/7] Pushing..."

if git remote get-url origin &>/dev/null; then
    if git push -u origin "$CURRENT_BRANCH"; then
        echo -e "${GREEN}✓ Push successful!${NC}"
    else
        echo -e "${RED}❌ Push failed.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️ No remote configured. Skipping push.${NC}"
fi

# -------------------------------
# Done
# -------------------------------
echo ""
echo -e "${GREEN}=== Done ===${NC}"
echo "Commit : $COMMIT_MSG"
echo "Branch : $CURRENT_BRANCH"
echo "Files  : $FILES"
