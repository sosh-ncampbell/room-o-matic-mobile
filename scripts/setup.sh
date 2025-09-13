#!/bin/bash

# 🚀 Ultimate GitHub Copilot Workspace Setup Script
# This script initializes the complete "G.O.A.T" GitHub Copilot development environment

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis for better UX
ROCKET="🚀"
CHECK="✅"
WARNING="⚠️"
INFO="ℹ️"
GEAR="⚙️"
STAR="⭐"
FIRE="🔥"
BRAIN="🧠"

echo -e "${CYAN}${ROCKET} Ultimate GitHub Copilot Workspace Setup${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""

# Function to print colored output
print_step() {
    echo -e "${BLUE}${GEAR} $1${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} $1${NC}"
}

print_info() {
    echo -e "${CYAN}${INFO} $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [[ ! -f ".vscode/settings.json" ]]; then
    print_error "This doesn't appear to be the copilot workspace directory!"
    print_info "Please run this script from the root of the Ultimate Copilot workspace."
    exit 1
fi

# Step 1: Check Prerequisites
print_step "Checking prerequisites..."

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_warning "$1 is not installed"
        return 1
    fi
}

# Essential tools
MISSING_TOOLS=0

if ! check_command "git"; then
    print_error "Git is required but not installed. Please install Git first."
    ((MISSING_TOOLS++))
fi

if ! check_command "code"; then
    print_warning "VS Code CLI not found. Install VS Code and ensure 'code' is in PATH."
    ((MISSING_TOOLS++))
fi

if ! check_command "node"; then
    print_warning "Node.js not found. Some features may not work."
fi

if ! check_command "npm"; then
    print_warning "npm not found. Node.js package management unavailable."
fi

if ! check_command "go"; then
    print_info "Go not found. Go-specific features will be unavailable."
fi

if ! check_command "python3" && ! check_command "python"; then
    print_info "Python not found. Python-specific features will be unavailable."
fi

if [[ $MISSING_TOOLS -gt 0 ]]; then
    print_error "Please install missing essential tools before continuing."
    exit 1
fi

# Step 2: Install VS Code Extensions
print_step "Installing essential VS Code extensions..."

EXTENSIONS=(
    "GitHub.copilot"
    "GitHub.copilot-chat"
    "GitHub.vscode-pull-request-github"
    "ms-vscode.vscode-json"
    "redhat.vscode-yaml"
    "ms-python.python"
    "golang.Go"
    "rust-lang.rust-analyzer"
    "ms-vscode.cpptools"
    "ms-dotnettools.csharp"
    "bradlc.vscode-tailwindcss"
    "esbenp.prettier-vscode"
    "ms-vscode.theme-tomorrowkit"
    "PKief.material-icon-theme"
    "streetsidesoftware.code-spell-checker"
    "ms-vsliveshare.vsliveshare"
    "GitHub.vscode-github-actions"
    "ms-vscode.vscode-typescript-next"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-wsl"
)

print_info "Installing ${#EXTENSIONS[@]} essential extensions..."

for ext in "${EXTENSIONS[@]}"; do
    if code --list-extensions | grep -q "$ext"; then
        print_success "$ext already installed"
    else
        print_step "Installing $ext..."
        if code --install-extension "$ext" --force; then
            print_success "Installed $ext"
        else
            print_warning "Failed to install $ext"
        fi
    fi
done

# Step 3: Setup Git Configuration (if needed)
print_step "Checking Git configuration..."

if [[ -z "$(git config --global user.name)" ]]; then
    print_warning "Git user.name not set. Please configure:"
    echo "git config --global user.name 'Your Name'"
fi

if [[ -z "$(git config --global user.email)" ]]; then
    print_warning "Git user.email not set. Please configure:"
    echo "git config --global user.email 'your.email@example.com'"
fi

# Step 4: Initialize Git Repository (if not already)
if [[ ! -d ".git" ]]; then
    print_step "Initializing Git repository..."
    git init
    git add .
    git commit -m "🚀 Initial commit: Ultimate GitHub Copilot workspace setup"
    print_success "Git repository initialized"
else
    print_success "Git repository already exists"
fi

# Step 5: Set up enhanced Git hooks
print_step "Setting up Git hooks..."

mkdir -p .git/hooks

# Pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Enhanced pre-commit hook with Copilot optimization

echo "🔍 Running pre-commit checks..."

# Check for TODO/FIXME with AI assistance
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME\|XXX" 2>/dev/null; then
    echo "⚠️  Found TODO/FIXME comments. Consider resolving with GitHub Copilot."
fi

# Check for hardcoded secrets
if git diff --cached | grep -E "(password|secret|key|token)" | grep -v "example\|template\|placeholder"; then
    echo "🚨 Potential hardcoded secrets detected! Review before committing."
    exit 1
fi

# Format code if formatters are available
if command -v prettier &> /dev/null; then
    echo "🎨 Running Prettier..."
    npx prettier --write . || true
fi

if command -v go &> /dev/null && find . -name "*.go" | head -1 | grep -q .; then
    echo "🎨 Running Go fmt..."
    go fmt ./...
fi

if command -v black &> /dev/null && find . -name "*.py" | head -1 | grep -q .; then
    echo "🎨 Running Black..."
    black . || true
fi

echo "✅ Pre-commit checks completed"
EOF

chmod +x .git/hooks/pre-commit

# Commit message template
cat > .git/hooks/prepare-commit-msg << 'EOF'
#!/bin/bash
# Enhanced commit message template with AI guidance

if [ "$2" = "" ]; then  # Not an amend, merge, etc.
    echo "# 🚀 Commit Message Guidelines:" >> "$1"
    echo "# Use emojis for better visual communication:" >> "$1"
    echo "# 🚀 feat: New features" >> "$1"
    echo "# 🐛 fix: Bug fixes" >> "$1"
    echo "# 📚 docs: Documentation" >> "$1"
    echo "# 🎨 style: Formatting/style" >> "$1"
    echo "# ♻️  refactor: Code restructuring" >> "$1"
    echo "# ⚡ perf: Performance improvements" >> "$1"
    echo "# 🧪 test: Testing" >> "$1"
    echo "# 🔧 chore: Maintenance" >> "$1"
    echo "#" >> "$1"
    echo "# 🧠 Pro tip: Use GitHub Copilot Chat to help write descriptive commit messages!" >> "$1"
fi
EOF

chmod +x .git/hooks/prepare-commit-msg

print_success "Git hooks configured"

# Step 6: Setup dual memory systems
print_step "Setting up AI memory systems..."

# Template memory system (always present)
if [[ -f ".vscode/memory.json" ]]; then
    print_info "Template memory system already configured"
else
    print_info "Template memory system not found - using default configuration"
fi

# MCP memory system (if MCP is configured)
if [[ -f ".vscode/mcp.json" ]] && [[ -f ".vscode/mcp-memory.json" ]]; then
    print_success "Dual memory systems configured (Template + MCP)"
    print_info "Memory systems will enhance AI context across sessions"
else
    print_info "MCP memory system available but not configured"
    print_info "Check docs/goat/MEMORY_SYSTEMS_GUIDE.md for setup instructions"
fi

print_success "AI memory systems validated"

# Step 8: Setup project-specific configurations
print_step "Customizing workspace configuration..."

# Detect primary language and customize accordingly
PROJECT_LANG="unknown"

if [[ -f "go.mod" ]]; then
    PROJECT_LANG="go"
    print_info "Go project detected"
elif [[ -f "package.json" ]]; then
    PROJECT_LANG="javascript"
    print_info "JavaScript/TypeScript project detected"
elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    PROJECT_LANG="python"
    print_info "Python project detected"
elif [[ -f "Cargo.toml" ]]; then
    PROJECT_LANG="rust"
    print_info "Rust project detected"
elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
    PROJECT_LANG="java"
    print_info "Java project detected"
elif [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
    PROJECT_LANG="csharp"
    print_info "C# project detected"
fi

# Create language-specific .gitignore if it doesn't exist
if [[ ! -f ".gitignore" ]]; then
    print_step "Creating .gitignore for $PROJECT_LANG..."

    case $PROJECT_LANG in
        "go")
            curl -s "https://raw.githubusercontent.com/github/gitignore/main/Go.gitignore" > .gitignore
            ;;
        "javascript")
            curl -s "https://raw.githubusercontent.com/github/gitignore/main/Node.gitignore" > .gitignore
            ;;
        "python")
            curl -s "https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore" > .gitignore
            ;;
        "rust")
            curl -s "https://raw.githubusercontent.com/github/gitignore/main/Rust.gitignore" > .gitignore
            ;;
        "java")
            curl -s "https://raw.githubusercontent.com/github/gitignore/main/Java.gitignore" > .gitignore
            ;;
        *)
            print_info "Creating basic .gitignore"
            cat > .gitignore << EOF
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/settings.json.bak
.idea/
*.swp
*.swo

# Build artifacts
/bin/
/dist/
/build/
*.log
EOF
            ;;
    esac

    # Add common AI/Copilot ignores
    cat >> .gitignore << EOF

# AI/Copilot specific
.copilot/
*.copilot-cache
.ai-context/
coverage.html
coverage.out
*.prof

# Temporary files
.tmp/
temp/
*.temp
EOF

    print_success ".gitignore created for $PROJECT_LANG"
fi

# Step 9: Install development tools
print_step "Installing development tools..."

# Language-specific tool installation
case $PROJECT_LANG in
    "go")
        if command -v go &> /dev/null; then
            print_step "Installing Go tools..."
            go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest || print_warning "Failed to install golangci-lint"
            go install github.com/sonatard/noctx/cmd/noctx@latest || print_warning "Failed to install noctx"
            go install golang.org/x/tools/cmd/goimports@latest || print_warning "Failed to install goimports"
        fi
        ;;
    "javascript")
        if command -v npm &> /dev/null; then
            print_step "Installing JavaScript tools..."
            npm install -g eslint prettier @typescript-eslint/parser @typescript-eslint/eslint-plugin 2>/dev/null || print_warning "Failed to install JS tools globally"
        fi
        ;;
    "python")
        if command -v pip3 &> /dev/null; then
            print_step "Installing Python tools..."
            pip3 install black flake8 mypy pytest bandit safety 2>/dev/null || print_warning "Failed to install Python tools"
        fi
        ;;
esac

# Step 10: Create helpful aliases and shortcuts
print_step "Setting up helpful aliases..."

# Create a .bashrc addition file
cat > .copilot-aliases << 'EOF'
# 🚀 Ultimate GitHub Copilot Workspace Aliases
# Add this to your ~/.bashrc or ~/.zshrc: source /path/to/project/.copilot-aliases

# Quick AI assistance
alias cai='code --command "github.copilot.openChat"'
alias explain='code --command "github.copilot.explain"'
alias fix='code --command "github.copilot.fix"'
alias optimize='code --command "github.copilot.optimize"'

# Development shortcuts
alias dev='code . && npm run dev 2>/dev/null || go run . 2>/dev/null || python main.py'
alias test-all='npm test 2>/dev/null || go test -v ./... 2>/dev/null || python -m pytest'
alias format-all='npm run format 2>/dev/null || go fmt ./... || black .'
alias lint-all='npm run lint 2>/dev/null || golangci-lint run || flake8 .'

# Git shortcuts with Copilot context
alias gac='git add . && git commit -m'  # Usage: gac "🚀 feat: amazing feature"
alias gp='git push'
alias gs='git status'
alias gl='git log --oneline -10'
alias gb='git branch'

# Copilot-optimized development
alias setup-copilot='bash scripts/setup.sh'
alias validate-ai='find .github -name "*.instructions.md" -exec head -5 {} \;'

echo "🧠 Copilot aliases loaded! Use 'cai' to open Copilot Chat, 'dev' to start development"
EOF

print_success "Copilot aliases created in .copilot-aliases"

# Step 11: Generate README with instructions
print_step "Generating comprehensive README..."

cat > README.md << 'EOF'
# 🚀 Ultimate GitHub Copilot Workspace

> **The G.O.A.T (Greatest Of All Time) GitHub Copilot development environment**

This workspace is designed to maximize productivity with GitHub Copilot across any programming language. It includes comprehensive AI instructions, dual memory systems, optimized VS Code settings, and automated workflows.

## 📚 Quick Links

- **[Getting Started Guide](./docs/goat/QUICK_REFERENCE_CARD.md)**: Fast setup and usage patterns
- **[Memory Systems Guide](./docs/goat/MEMORY_SYSTEMS_GUIDE.md)**: AI memory configuration
- **[Customization Guide](./docs/goat/TEMPLATE_CUSTOMIZATION_GUIDE.md)**: Tailor for your project
- **[Helpful Prompts](./docs/goat/HELPFUL_PROMPTS.md)**: 50+ ready-to-use AI prompts
- **[MCP Setup Guide](./docs/goat/MCP_SERVER_SETUP_GUIDE.md)**: Model Context Protocol configuration

## ⚡ Quick Start

```bash
# 1. Clone or create your project
git clone <your-repo> or mkdir my-awesome-project && cd my-awesome-project

# 2. Copy this workspace template
cp -r /path/to/copilot-goat/* .

# 3. Run the setup script
./scripts/setup.sh

# 4. Open in VS Code
code .

# 5. Start developing with AI superpowers! 🧠
```

## 🎯 Features

### 🧠 AI-Powered Development
- **Comprehensive Copilot Instructions**: Multi-language development patterns
- **Smart Code Generation**: Context-aware suggestions for any language
- **Automated Testing**: AI-generated test patterns and coverage
- **Security-First**: Built-in security patterns and vulnerability scanning
- **Performance Optimization**: AI-assisted performance improvements

### 🛠️ Developer Experience
- **Universal Language Support**: Go, Python, JavaScript/TypeScript, Java, C#, Rust
- **One-Command Setup**: Automated workspace initialization
- **Smart Git Hooks**: AI-enhanced pre-commit checks
- **VS Code Optimization**: Perfect settings for Copilot effectiveness
- **MCP Integration**: Enhanced AI capabilities through Model Context Protocol

### 🔒 Security & Quality
- **Automated Security Scanning**: Multi-layer security validation
- **Code Quality Gates**: Linting, formatting, and best practices
- **Dependency Management**: Automated vulnerability scanning
- **Test Coverage**: Comprehensive testing strategies

### 📊 Monitoring & Analytics
- **Performance Benchmarking**: Automated performance testing
- **Coverage Reports**: Visual test coverage analysis
- **CI/CD Integration**: GitHub Actions workflows
- **Documentation Generation**: Auto-generated docs

## 🚀 Available Tasks

Use VS Code's Command Palette (`Cmd/Ctrl + Shift + P`) and search for "Tasks: Run Task":

| Task | Description | Shortcut |
|------|-------------|----------|
| 🚀 Setup: Initialize Project | Full project initialization | |
| 🧪 Test: Run All Tests | Universal test runner | `Cmd+Shift+T` |
| 🔧 Build: Development Build | Language-aware building | `Cmd+Shift+B` |
| 🔒 Security: Run Security Scan | Vulnerability scanning | |
| ⚡ Performance: Run Benchmarks | Performance testing | |
| 🧹 Format: All Code | Multi-language formatting | |
| 📚 Docs: Generate Documentation | Auto-documentation | |
| 🎯 AI: Validate Instruction Files | AI instruction validation | |

## 📁 Project Structure

```
.
├── .github/                          # GitHub configurations
│   ├── copilot-instructions.md      # Main AI instructions
│   ├── instructions/                # Specialized AI instructions
│   ├── security/                    # Security patterns
│   ├── team-standards/              # Code review standards
│   └── workflows/                   # CI/CD pipelines
├── .vscode/                         # VS Code optimization
│   ├── settings.json               # Copilot-optimized settings
│   ├── mcp.json                   # Model Context Protocol config
│   └── tasks.json                 # Development tasks
├── scripts/                        # Setup and utility scripts
│   └── setup.sh                   # Main setup script
└── docs/                          # Documentation
```

## 🎨 Customization

### For Your Language

1. **Detect Your Language**: The setup script auto-detects your primary language
2. **Customize Instructions**: Edit `.github/copilot-instructions.md`
3. **Update Settings**: Modify `.vscode/settings.json` for your preferences
4. **Add Tools**: Install language-specific tools in `scripts/setup.sh`

### For Your Team

1. **Team Standards**: Customize `.github/team-standards/code-review-checklist.md`
2. **Security Policies**: Update `.github/security/security-instructions.md`
3. **CI/CD Workflows**: Modify `.github/workflows/copilot-optimization.yml`
4. **VS Code Settings**: Share team settings in `.vscode/settings.json`

## 🧠 AI Instructions System

This workspace uses a hierarchical AI instruction system:

```
copilot-instructions.md          # Main project context
├── instructions/
│   ├── testing.instructions.md   # Testing patterns
│   ├── language.instructions.md  # Language-specific patterns
│   └── api.instructions.md       # API development patterns
├── security/
│   └── security-instructions.md  # Security requirements
└── team-standards/
    └── code-review-checklist.md  # Review guidelines
```

## 🔧 Advanced Features

### MCP (Model Context Protocol) Integration

Enhanced AI capabilities through specialized servers:

- **Filesystem**: Deep project understanding
- **Git Integration**: Context-aware version control
- **Memory System**: Persistent AI memory across sessions
- **Search & Analysis**: Advanced code search capabilities
- **Performance Monitoring**: Real-time performance insights

### VS Code Optimization

Perfect settings for maximum Copilot effectiveness:

- **Experimental Features**: All Copilot Labs features enabled
- **Smart Suggestions**: Context-aware completions
- **Multi-Language Support**: Optimized for 6+ languages
- **Performance Tuning**: Reduced latency, improved responsiveness

## 🤝 Contributing

This is a template workspace designed to be customized for your projects. Key principles:

1. **Universal Compatibility**: Works with any programming language
2. **AI-First Development**: Maximize GitHub Copilot effectiveness
3. **Security by Default**: Built-in security patterns
4. **Developer Happiness**: Reduce friction, increase productivity

## 📚 Resources

- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [VS Code Settings Reference](https://code.visualstudio.com/docs/getstarted/settings)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [AI Instruction Best Practices](https://github.com/features/copilot/instructions)

## 📄 License

This workspace template is MIT licensed. Use it for any project, commercial or personal.

---

**🧠 Pro Tip**: After setup, open GitHub Copilot Chat (`Ctrl+Alt+I`) and ask: "How can I use this workspace effectively for my [language] project?"

**🚀 Happy Coding with AI Superpowers!**
EOF

print_success "README.md generated"

# Step 12: Final validation and summary
print_step "Performing final validation..."

# Check that key files exist
REQUIRED_FILES=(
    ".github/copilot-instructions.md"
    ".vscode/settings.json"
    ".vscode/tasks.json"
    ".vscode/mcp.json"
    ".vscode/memory.json"
    "README.md"
)

ALL_GOOD=true
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "$file exists"
    else
        print_error "$file is missing!"
        ALL_GOOD=false
    fi
done

# Success summary
echo ""
echo -e "${GREEN}${STAR}${STAR}${STAR} SETUP COMPLETE! ${STAR}${STAR}${STAR}${NC}"
echo -e "${CYAN}===============================================${NC}"
echo ""
echo -e "${FIRE} ${YELLOW}Your Ultimate GitHub Copilot workspace is ready!${NC}"
echo ""
echo -e "${BRAIN} ${BLUE}Next steps:${NC}"
echo -e "  1. ${CYAN}Restart VS Code to apply all settings${NC}"
echo -e "  2. ${CYAN}Open Copilot Chat: Ctrl+Alt+I (Cmd+Alt+I on Mac)${NC}"
echo -e "  3. ${CYAN}Run a task: Cmd+Shift+P > 'Tasks: Run Task'${NC}"
echo -e "  4. ${CYAN}Start coding with AI superpowers!${NC}"
echo ""
echo -e "${INFO} ${PURPLE}Useful commands:${NC}"
echo -e "  • ${CYAN}source .copilot-aliases${NC} - Load helpful aliases"
echo -e "  • ${CYAN}code --command 'github.copilot.openChat'${NC} - Open Copilot Chat"
echo -e "  • ${CYAN}code --list-extensions | grep copilot${NC} - Check Copilot extensions"
echo ""
echo -e "${ROCKET} ${GREEN}Happy coding with the G.O.A.T Copilot setup!${NC}"
echo ""

if [[ "$ALL_GOOD" == true ]]; then
    exit 0
else
    print_error "Some issues were found. Please check the output above."
    exit 1
fi
