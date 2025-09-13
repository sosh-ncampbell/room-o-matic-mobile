# 🚀 Ultimate GitHub Copilot Workspace Setup Script (PowerShell)
# This script initializes the complete "G.O.A.T" GitHub Copilot development environment for Windows

param(
    [switch]$SkipExtensions,
    [switch]$SkipGitSetup,
    [switch]$Verbose,
    [switch]$Help
)

if ($Help) {
    Write-Host "🚀 Ultimate GitHub Copilot Workspace Setup"
    Write-Host "Usage: .\setup.ps1 [-SkipExtensions] [-SkipGitSetup] [-Verbose] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -SkipExtensions  Skip VS Code extension installation"
    Write-Host "  -SkipGitSetup    Skip Git configuration and hooks setup"
    Write-Host "  -Verbose         Enable verbose output"
    Write-Host "  -Help           Show this help message"
    exit 0
}

# Set error action preference
$ErrorActionPreference = "Stop"

if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Colors and emojis
$Colors = @{
    Red    = "Red"
    Green  = "Green"
    Yellow = "Yellow"
    Blue   = "Blue"
    Purple = "Magenta"
    Cyan   = "Cyan"
    White  = "White"
}

$Emojis = @{
    Rocket  = "🚀"
    Check   = "✅"
    Warning = "⚠️"
    Info    = "ℹ️"
    Gear    = "⚙️"
    Star    = "⭐"
    Fire    = "🔥"
    Brain   = "🧠"
    Error   = "❌"
}

Write-Host "$($Emojis.Rocket) Ultimate GitHub Copilot Workspace Setup" -ForegroundColor $Colors.Cyan
Write-Host "===============================================" -ForegroundColor $Colors.Cyan
Write-Host ""

function Write-Step {
    param([string]$Message)
    Write-Host "$($Emojis.Gear) $Message" -ForegroundColor $Colors.Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "$($Emojis.Check) $Message" -ForegroundColor $Colors.Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "$($Emojis.Warning) $Message" -ForegroundColor $Colors.Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "$($Emojis.Info) $Message" -ForegroundColor $Colors.Cyan
}

function Write-Error {
    param([string]$Message)
    Write-Host "$($Emojis.Error) $Message" -ForegroundColor $Colors.Red
}

function Test-Command {
    param([string]$CommandName)
    return Get-Command $CommandName -ErrorAction SilentlyContinue
}

function Test-VSCodeExtension {
    param([string]$ExtensionId)
    try {
        $extensions = & code --list-extensions 2>$null
        return $extensions -contains $ExtensionId
    }
    catch {
        return $false
    }
}

# Check if we're in the right directory
if (-not (Test-Path ".vscode\settings.json")) {
    Write-Error "This doesn't appear to be the copilot workspace directory!"
    Write-Info "Please run this script from the root of the Ultimate Copilot workspace."
    exit 1
}

# Step 1: Check Prerequisites
Write-Step "Checking prerequisites..."

$missingTools = 0

# Essential tools
if (Test-Command "git") {
    Write-Success "git is installed"
}
else {
    Write-Error "Git is required but not installed. Please install Git first."
    $missingTools++
}

if (Test-Command "code") {
    Write-Success "VS Code CLI is installed"
}
else {
    Write-Warning "VS Code CLI not found. Install VS Code and ensure 'code' is in PATH."
    $missingTools++
}

# Optional tools
$optionalTools = @{
    "node"   = "Node.js"
    "npm"    = "npm"
    "go"     = "Go"
    "python" = "Python"
    "dotnet" = ".NET"
    "rustc"  = "Rust"
}

foreach ($tool in $optionalTools.Keys) {
    if (Test-Command $tool) {
        Write-Success "$($optionalTools[$tool]) is installed"
    }
    else {
        Write-Info "$($optionalTools[$tool]) not found. Language-specific features will be unavailable."
    }
}

if ($missingTools -gt 0) {
    Write-Error "Please install missing essential tools before continuing."
    exit 1
}

# Step 2: Install VS Code Extensions
if (-not $SkipExtensions) {
    Write-Step "Installing essential VS Code extensions..."

    $extensions = @(
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "GitHub.vscode-pull-request-github",
        "ms-vscode.vscode-json",
        "redhat.vscode-yaml",
        "ms-python.python",
        "golang.Go",
        "rust-lang.rust-analyzer",
        "ms-vscode.cpptools",
        "ms-dotnettools.csharp",
        "bradlc.vscode-tailwindcss",
        "esbenp.prettier-vscode",
        "ms-vscode.theme-tomorrowkit",
        "PKief.material-icon-theme",
        "streetsidesoftware.code-spell-checker",
        "ms-vsliveshare.vsliveshare",
        "GitHub.vscode-github-actions",
        "ms-vscode.vscode-typescript-next",
        "ms-vscode-remote.remote-containers",
        "ms-vscode-remote.remote-wsl"
    )

    Write-Info "Installing $($extensions.Count) essential extensions..."

    foreach ($ext in $extensions) {
        if (Test-VSCodeExtension $ext) {
            Write-Success "$ext already installed"
        }
        else {
            Write-Step "Installing $ext..."
            try {
                & code --install-extension $ext --force 2>$null
                Write-Success "Installed $ext"
            }
            catch {
                Write-Warning "Failed to install $ext"
            }
        }
    }
}
else {
    Write-Info "Skipping VS Code extension installation"
}

# Step 3: Setup Git Configuration (if needed)
if (-not $SkipGitSetup) {
    Write-Step "Checking Git configuration..."

    try {
        $gitUserName = & git config --global user.name 2>$null
        if (-not $gitUserName) {
            Write-Warning "Git user.name not set. Please configure:"
            Write-Host "git config --global user.name 'Your Name'" -ForegroundColor $Colors.Yellow
        }

        $gitUserEmail = & git config --global user.email 2>$null
        if (-not $gitUserEmail) {
            Write-Warning "Git user.email not set. Please configure:"
            Write-Host "git config --global user.email 'your.email@example.com'" -ForegroundColor $Colors.Yellow
        }
    }
    catch {
        Write-Warning "Could not check Git configuration"
    }

    # Step 4: Initialize Git Repository (if not already)
    if (-not (Test-Path ".git")) {
        Write-Step "Initializing Git repository..."
        & git init
        & git add .
        & git commit -m "🚀 Initial commit: Ultimate GitHub Copilot workspace setup"
        Write-Success "Git repository initialized"
    }
    else {
        Write-Success "Git repository already exists"
    }

    # Step 5: Set up enhanced Git hooks
    Write-Step "Setting up Git hooks..."

    $hooksDir = ".git\hooks"
    if (-not (Test-Path $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    }

    # Pre-commit hook (Windows batch file)
    $preCommitHook = @'
@echo off
echo 🔍 Running pre-commit checks...

REM Check for TODO/FIXME with AI assistance
git diff --cached --name-only | xargs grep -l "TODO\|FIXME\|XXX" 2>nul
if %errorlevel% equ 0 (
    echo ⚠️ Found TODO/FIXME comments. Consider resolving with GitHub Copilot.
)

REM Check for hardcoded secrets
git diff --cached | findstr /i "password secret key token" | findstr /v "example template placeholder" >nul
if %errorlevel% equ 0 (
    echo 🚨 Potential hardcoded secrets detected! Review before committing.
    exit 1
)

REM Format code if formatters are available
where prettier >nul 2>&1
if %errorlevel% equ 0 (
    echo 🎨 Running Prettier...
    npx prettier --write . 2>nul
)

where go >nul 2>&1
if %errorlevel% equ 0 (
    for /r %%i in (*.go) do (
        echo 🎨 Running Go fmt...
        go fmt ./...
        goto :gofmtdone
    )
    :gofmtdone
)

where black >nul 2>&1
if %errorlevel% equ 0 (
    for /r %%i in (*.py) do (
        echo 🎨 Running Black...
        black . 2>nul
        goto :blackdone
    )
    :blackdone
)

echo ✅ Pre-commit checks completed
'@

    Set-Content -Path "$hooksDir\pre-commit.bat" -Value $preCommitHook -Encoding ASCII

    # Commit message template (Windows batch file)
    $commitMsgHook = @'
@echo off
if "%2"=="" (
    echo # 🚀 Commit Message Guidelines: >> %1
    echo # Use emojis for better visual communication: >> %1
    echo # 🚀 feat: New features >> %1
    echo # 🐛 fix: Bug fixes >> %1
    echo # 📚 docs: Documentation >> %1
    echo # 🎨 style: Formatting/style >> %1
    echo # ♻️ refactor: Code restructuring >> %1
    echo # ⚡ perf: Performance improvements >> %1
    echo # 🧪 test: Testing >> %1
    echo # 🔧 chore: Maintenance >> %1
    echo # >> %1
    echo # 🧠 Pro tip: Use GitHub Copilot Chat to help write descriptive commit messages! >> %1
)
'@

    Set-Content -Path "$hooksDir\prepare-commit-msg.bat" -Value $commitMsgHook -Encoding ASCII

    Write-Success "Git hooks configured"
}
else {
    Write-Success "AI memory systems validated"

    # Step 7: Setup dual memory systems
    Write-Step "Setting up AI memory systems..."

    # Template memory system (always present)
    if (Test-Path ".vscode\memory.json") {
        Write-Info "Template memory system already configured"
    }
    else {
        Write-Info "Template memory system not found - using default configuration"
    }

    # MCP memory system (if MCP is configured)
    if ((Test-Path ".vscode\mcp.json") -and (Test-Path ".vscode\mcp-memory.json")) {
        Write-Success "Dual memory systems configured (Template + MCP)"
        Write-Info "Memory systems will enhance AI context across sessions"
    }
    else {
        Write-Info "MCP memory system available but not configured"
        Write-Info "Check docs/goat/MEMORY_SYSTEMS_GUIDE.md for setup instructions"
    }

    Write-Success "AI memory systems validated"

    # Step 7: Setup project-specific configurations
    Write-Step "Customizing workspace configuration..."

    # Detect primary language and customize accordingly
    $projectLang = "unknown"

    if (Test-Path "go.mod") {
        $projectLang = "go"
        Write-Info "Go project detected"
    }
    elseif (Test-Path "package.json") {
        $projectLang = "javascript"
        Write-Info "JavaScript/TypeScript project detected"
    }
    elseif ((Test-Path "requirements.txt") -or (Test-Path "pyproject.toml")) {
        $projectLang = "python"
        Write-Info "Python project detected"
    }
    elseif (Test-Path "Cargo.toml") {
        $projectLang = "rust"
        Write-Info "Rust project detected"
    }
    elseif ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
        $projectLang = "java"
        Write-Info "Java project detected"
    }
    elseif ((Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue) -or (Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue)) {
        $projectLang = "csharp"
        Write-Info "C# project detected"
    }

    # Step 8: Install development tools
    Write-Step "Installing development tools..."

    switch ($projectLang) {
        "go" {
            if (Test-Command "go") {
                Write-Step "Installing Go tools..."
                try {
                    & go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
                    & go install github.com/sonatard/noctx/cmd/noctx@latest
                    & go install golang.org/x/tools/cmd/goimports@latest
                    Write-Success "Go tools installed"
                }
                catch {
                    Write-Warning "Some Go tools failed to install"
                }
            }
        }
        "javascript" {
            if (Test-Command "npm") {
                Write-Step "Installing JavaScript tools..."
                try {
                    & npm install -g eslint prettier @typescript-eslint/parser @typescript-eslint/eslint-plugin 2>$null
                    Write-Success "JavaScript tools installed"
                }
                catch {
                    Write-Warning "Some JavaScript tools failed to install"
                }
            }
        }
        "python" {
            if (Test-Command "pip") {
                Write-Step "Installing Python tools..."
                try {
                    & pip install black flake8 mypy pytest bandit safety 2>$null
                    Write-Success "Python tools installed"
                }
                catch {
                    Write-Warning "Some Python tools failed to install"
                }
            }
        }
        "csharp" {
            if (Test-Command "dotnet") {
                Write-Step "Installing .NET tools..."
                try {
                    & dotnet tool install --global dotnet-format 2>$null
                    & dotnet tool install --global dotnet-outdated-tool 2>$null
                    Write-Success ".NET tools installed"
                }
                catch {
                    Write-Warning "Some .NET tools failed to install"
                }
            }
        }
    }

    # Step 9: Create helpful aliases and shortcuts
    Write-Step "Setting up helpful aliases..."

    # Create a PowerShell profile addition
    $profileContent = @'
# 🚀 Ultimate GitHub Copilot Workspace Aliases (PowerShell)
# Add this to your PowerShell profile: notepad $PROFILE

# Quick AI assistance
function cai { code --command "github.copilot.openChat" }
function explain { code --command "github.copilot.explain" }
function fix { code --command "github.copilot.fix" }
function optimize { code --command "github.copilot.optimize" }

# Development shortcuts
function dev {
    code .
    if (Test-Path "package.json") { npm run dev }
    elseif (Test-Path "go.mod") { go run . }
    elseif (Test-Path "main.py") { python main.py }
    elseif (Get-ChildItem -Filter "*.csproj") { dotnet run }
}

function test-all {
    if (Test-Path "package.json") { npm test }
    elseif (Test-Path "go.mod") { go test -v ./... }
    elseif (Test-Path "requirements.txt") { python -m pytest }
    elseif (Get-ChildItem -Filter "*.csproj") { dotnet test }
}

function format-all {
    if (Test-Path "package.json") { npm run format }
    elseif (Test-Path "go.mod") { go fmt ./... }
    elseif (Test-Path "requirements.txt") { black . }
    elseif (Get-ChildItem -Filter "*.csproj") { dotnet format }
}

function lint-all {
    if (Test-Path "package.json") { npm run lint }
    elseif (Test-Path "go.mod") { golangci-lint run }
    elseif (Test-Path "requirements.txt") { flake8 . }
}

# Git shortcuts with Copilot context
function gac { param($message) git add .; git commit -m $message }
function gp { git push }
function gs { git status }
function gl { git log --oneline -10 }
function gb { git branch }

# Copilot-optimized development
function setup-copilot { .\scripts\setup.ps1 }
function validate-ai { Get-ChildItem -Path ".github" -Filter "*.instructions.md" | ForEach-Object { Get-Content $_.FullName | Select-Object -First 5 } }
function validate-memory {
    if (Test-Path ".vscode\memory.json") { Write-Host "✅ Template memory system configured" -ForegroundColor Green }
    if (Test-Path ".vscode\mcp-memory.json") { Write-Host "✅ MCP memory system configured" -ForegroundColor Green }
    Write-Host "📚 Memory guide: docs/goat/MEMORY_SYSTEMS_GUIDE.md" -ForegroundColor Cyan
}

Write-Host "🧠 Copilot aliases loaded! Use 'cai' to open Copilot Chat, 'dev' to start development" -ForegroundColor Green
'@

    Set-Content -Path ".copilot-aliases.ps1" -Value $profileContent -Encoding UTF8
    Write-Success "Copilot aliases created in .copilot-aliases.ps1"

    # Step 10: Generate or update README with Windows-specific instructions
    Write-Step "Updating README with Windows-specific instructions..."

    if (-not (Test-Path "README.md")) {
        # Create a comprehensive README if it doesn't exist
        $readmeContent = @'
# 🚀 Ultimate GitHub Copilot Workspace

> **The G.O.A.T (Greatest Of All Time) GitHub Copilot development environment**

This workspace is designed to maximize productivity with GitHub Copilot across any programming language on Windows, macOS, and Linux.

## 📚 Quick Links

- **[Getting Started Guide](./docs/goat/QUICK_REFERENCE_CARD.md)**: Fast setup and usage patterns
- **[Memory Systems Guide](./docs/goat/MEMORY_SYSTEMS_GUIDE.md)**: AI memory configuration
- **[Customization Guide](./docs/goat/TEMPLATE_CUSTOMIZATION_GUIDE.md)**: Tailor for your project
- **[Helpful Prompts](./docs/goat/HELPFUL_PROMPTS.md)**: 50+ ready-to-use AI prompts
- **[MCP Setup Guide](./docs/goat/MCP_SERVER_SETUP_GUIDE.md)**: Model Context Protocol configuration

## ⚡ Quick Start (Windows)

### Using PowerShell (Recommended)
```powershell
# 1. Clone or create your project
git clone <your-repo>
# OR: mkdir my-awesome-project; cd my-awesome-project

# 2. Download and setup the workspace
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/greysquirr3l/copilot-goat/main/scripts/quick-install.ps1" -OutFile "quick-install.ps1"
.\quick-install.ps1

# 3. Open in VS Code
code .

# 4. Start developing with AI superpowers! 🧠
```

### Manual Setup
```powershell
# 1. Download template
Invoke-WebRequest -Uri "https://github.com/greysquirr3l/copilot-goat/archive/refs/heads/main.zip" -OutFile "copilot-goat.zip"
Expand-Archive copilot-goat.zip
Copy-Item copilot-goat-main\* . -Recurse -Force

# 2. Run setup
.\scripts\setup.ps1

# 3. Open VS Code
code .
```

## 🎯 Windows-Specific Features

### PowerShell Integration
- **Native PowerShell scripts** for all automation
- **PowerShell aliases** for common tasks
- **Windows-optimized Git hooks** using batch files
- **.NET Core tool integration** for C# projects

### Cross-Platform Compatibility
- **Universal .gitignore** covering Windows, macOS, and Linux
- **Multi-shell support** (PowerShell, CMD, WSL bash)
- **Windows Terminal** optimized settings
- **WSL2 compatibility** for Linux development

## 🛠️ Available Commands (Windows)

### PowerShell Aliases
```powershell
# AI assistance
cai                    # Open Copilot Chat
explain               # Explain selected code
fix                   # Fix selected code

# Development
dev                   # Start development server
test-all             # Run all tests
format-all           # Format all code
lint-all             # Lint all code

# Git shortcuts
gac "message"        # Git add & commit
gp                   # Git push
gs                   # Git status
```

### VS Code Tasks
- Press `Ctrl+Shift+P` → "Tasks: Run Task"
- Build, test, format, and deploy with one click

## 🔧 Windows Setup Requirements

### Essential Tools
- **Git for Windows** - Version control
- **VS Code** - Code editor with Copilot
- **PowerShell 7+** - Modern shell (recommended)
- **Windows Terminal** - Better terminal experience

### Language-Specific Tools
- **Node.js** - For JavaScript/TypeScript projects
- **.NET SDK** - For C# projects
- **Go** - For Go projects
- **Python** - For Python projects
- **Rust** - For Rust projects

### Optional Enhancements
- **WSL2** - Linux subsystem for cross-platform development
- **Docker Desktop** - Containerized development
- **GitHub CLI** - Enhanced GitHub integration

## 📁 Project Structure

```
.
├── .github\              # GitHub configurations
│   ├── instructions\     # AI instruction files
│   └── workflows\        # CI/CD pipelines
├── .vscode\              # VS Code settings
├── scripts\              # Automation scripts
│   ├── setup.ps1        # PowerShell setup
│   ├── setup.sh         # Bash setup (WSL)
│   └── quick-install.ps1 # Quick installer
└── docs\                 # Documentation
```

## 🚀 Next Steps

1. **Load PowerShell aliases**: `. .\.copilot-aliases.ps1`
2. **Open Copilot Chat**: `Ctrl+Alt+I` in VS Code
3. **Try a task**: `Ctrl+Shift+P` → "Tasks: Run Task"
4. **Start coding** with AI superpowers!

## 🤝 Windows Development Tips

- Use **Windows Terminal** for better PowerShell experience
- Enable **Developer Mode** in Windows Settings
- Configure **PowerShell execution policy**: `Set-ExecutionPolicy RemoteSigned`
- Use **WSL2** for Linux compatibility when needed

---

**🧠 Pro Tip**: After setup, ask GitHub Copilot: "How can I optimize this workspace for my [language] project on Windows?"

**🚀 Happy Coding with AI Superpowers!**
'@

        Set-Content -Path "README.md" -Value $readmeContent -Encoding UTF8
        Write-Success "Windows-optimized README.md created"
    }

    # Step 11: Final validation and summary
    Write-Step "Performing final validation..."

    # Check that key files exist
    $requiredFiles = @(
        ".github\copilot-instructions.md",
        ".vscode\settings.json",
        ".vscode\tasks.json",
        ".vscode\mcp.json",
        ".vscode\memory.json",
        "README.md"
    )

    $allGood = $true
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Success "$file exists"
        }
        else {
            Write-Error "$file is missing!"
            $allGood = $false
        }
    }

    # Success summary
    Write-Host ""
    Write-Host "$($Emojis.Star)$($Emojis.Star)$($Emojis.Star) SETUP COMPLETE! $($Emojis.Star)$($Emojis.Star)$($Emojis.Star)" -ForegroundColor $Colors.Green
    Write-Host "===============================================" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "$($Emojis.Fire) Your Ultimate GitHub Copilot workspace is ready!" -ForegroundColor $Colors.Yellow
    Write-Host ""
    Write-Host "$($Emojis.Brain) Next steps:" -ForegroundColor $Colors.Blue
    Write-Host "  1. Restart VS Code to apply all settings" -ForegroundColor $Colors.Cyan
    Write-Host "  2. Load PowerShell aliases: . .\.copilot-aliases.ps1" -ForegroundColor $Colors.Cyan
    Write-Host "  3. Open Copilot Chat: Ctrl+Alt+I" -ForegroundColor $Colors.Cyan
    Write-Host "  4. Run a task: Ctrl+Shift+P > 'Tasks: Run Task'" -ForegroundColor $Colors.Cyan
    Write-Host "  5. Start coding with AI superpowers!" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "$($Emojis.Info) Useful commands:" -ForegroundColor $Colors.Purple
    Write-Host "  • . .\.copilot-aliases.ps1 - Load helpful aliases" -ForegroundColor $Colors.Cyan
    Write-Host "  • code --command 'github.copilot.openChat' - Open Copilot Chat" -ForegroundColor $Colors.Cyan
    Write-Host "  • code --list-extensions | Select-String copilot - Check Copilot extensions" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "$($Emojis.Rocket) Happy coding with the G.O.A.T Copilot setup!" -ForegroundColor $Colors.Green
    Write-Host ""

    if ($allGood) {
        exit 0
    }
    else {
        Write-Error "Some issues were found. Please check the output above."
        exit 1
    }
