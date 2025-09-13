#!/bin/bash

# 🚀 Ultimate GitHub Copilot Workspace - Quick Install Script
# One-command installation of the G.O.A.T Copilot setup

set -e

# Colors and emojis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

ROCKET="🚀"
CHECK="✅"
WARNING="⚠️"
INFO="ℹ️"
GEAR="⚙️"
STAR="⭐"
FIRE="🔥"
BRAIN="🧠"

echo -e "${CYAN}${ROCKET} Ultimate GitHub Copilot Workspace - Quick Install${NC}"
echo -e "${CYAN}======================================================${NC}"
echo ""

print_step() { echo -e "${BLUE}${GEAR} $1${NC}"; }
print_success() { echo -e "${GREEN}${CHECK} $1${NC}"; }
print_warning() { echo -e "${YELLOW}${WARNING} $1${NC}"; }
print_info() { echo -e "${CYAN}${INFO} $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if we're in a project directory
if [[ ! -d ".git" ]] && [[ ! -f "package.json" ]] && [[ ! -f "go.mod" ]] && [[ ! -f "requirements.txt" ]] && [[ ! -f "Cargo.toml" ]]; then
    print_warning "This doesn't look like a project directory."
    print_info "Creating a new project directory: $(basename "$(pwd)")-copilot"
    mkdir -p "$(basename "$(pwd)")-copilot"
    cd "$(basename "$(pwd)")-copilot" || exit 1
    print_success "Created project directory: $(pwd)"
fi

# Step 1: Download the template
print_step "Downloading Ultimate Copilot template..."

TEMP_DIR=$(mktemp -d)
REPO_URL="https://github.com/greysquirr3l/copilot-goat"  # Update with actual repo

if command -v curl &> /dev/null; then
    curl -L "${REPO_URL}/archive/refs/heads/main.zip" -o "${TEMP_DIR}/copilot-goat.zip"
elif command -v wget &> /dev/null; then
    wget "${REPO_URL}/archive/refs/heads/main.zip" -O "${TEMP_DIR}/copilot-goat.zip"
else
    print_error "Neither curl nor wget found. Please install one of them."
    exit 1
fi

# Step 2: Extract template
print_step "Extracting template files..."

if command -v unzip &> /dev/null; then
    unzip -q "${TEMP_DIR}/copilot-goat.zip" -d "${TEMP_DIR}"
elif command -v tar &> /dev/null; then
    (cd "${TEMP_DIR}" && tar -xzf copilot-goat.zip)
else
    print_error "Neither unzip nor tar found. Please install unzip."
    exit 1
fi

# Step 3: Copy template files (excluding existing source code)
print_step "Installing template files..."

TEMPLATE_DIR="${TEMP_DIR}/copilot-goat-main"

# Copy .github directory
if [[ -d "${TEMPLATE_DIR}/.github" ]]; then
    cp -r "${TEMPLATE_DIR}/.github" .
    print_success "AI instructions installed"
fi

# Copy .vscode directory
if [[ -d "${TEMPLATE_DIR}/.vscode" ]]; then
    cp -r "${TEMPLATE_DIR}/.vscode" .
    print_success "VS Code configuration installed"
fi

# Copy scripts directory
if [[ -d "${TEMPLATE_DIR}/scripts" ]]; then
    cp -r "${TEMPLATE_DIR}/scripts" .
    chmod +x scripts/*.sh
    print_success "Automation scripts installed"
fi

# Copy docs directory if it doesn't exist
if [[ ! -d "docs" ]] && [[ -d "${TEMPLATE_DIR}/docs" ]]; then
    cp -r "${TEMPLATE_DIR}/docs" .
    print_success "Documentation templates installed (including docs/goat/ guides)"
fi

# Copy README if it doesn't exist or is very basic
if [[ ! -f "README.md" ]] || [[ $(wc -l < "README.md") -lt 10 ]]; then
    if [[ -f "${TEMPLATE_DIR}/README.md" ]]; then
        cp "${TEMPLATE_DIR}/README.md" .
        print_success "Enhanced README installed"
    fi
fi

# Step 4: Clean up
rm -rf "${TEMP_DIR}"

# Step 5: Run the main setup script
print_step "Running main setup script..."

if [[ -f "scripts/setup.sh" ]]; then
    ./scripts/setup.sh
else
    print_error "Setup script not found!"
    exit 1
fi

# Success message
echo ""
echo -e "${GREEN}${STAR}${STAR}${STAR} QUICK INSTALL COMPLETE! ${STAR}${STAR}${STAR}${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo -e "${FIRE} ${YELLOW}Your Ultimate Copilot workspace is ready in $(pwd)!${NC}"
echo ""
echo -e "${BRAIN} ${BLUE}Next steps:${NC}"
echo -e "  1. ${CYAN}Open VS Code: code .${NC}"
echo -e "  2. ${CYAN}Open Copilot Chat: Ctrl+Alt+I (Cmd+Alt+I on Mac)${NC}"
echo -e "  3. ${CYAN}Try a task: Cmd+Shift+P > 'Tasks: Run Task'${NC}"
echo -e "  4. ${CYAN}Start coding with AI superpowers!${NC}"
echo ""
echo -e "${ROCKET} ${PURPLE}Welcome to the G.O.A.T Copilot experience!${NC}"
