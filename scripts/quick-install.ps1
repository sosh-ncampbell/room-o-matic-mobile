# 🚀 Ultimate GitHub Copilot Workspace - Quick Install Script (PowerShell)
# One-command installation of the G.O.A.T Copilot setup for Windows

param(
    [string]$RepoUrl = "https://github.com/greysquirr3l/copilot-goat",
    [switch]$Help
)

if ($Help) {
    Write-Host "🚀 Ultimate GitHub Copilot Workspace - Quick Install"
    Write-Host "Usage: .\quick-install.ps1 [-RepoUrl <url>] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -RepoUrl   GitHub repository URL (default: $RepoUrl)"
    Write-Host "  -Help      Show this help message"
    exit 0
}

# Set error action preference
$ErrorActionPreference = "Stop"

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

Write-Host "$($Emojis.Rocket) Ultimate GitHub Copilot Workspace - Quick Install" -ForegroundColor $Colors.Cyan
Write-Host "======================================================" -ForegroundColor $Colors.Cyan
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

# Check if we're in a project directory
$IsProjectDir = $false
$ProjectIndicators = @(".git", "package.json", "go.mod", "requirements.txt", "Cargo.toml", "*.csproj", "*.sln")

foreach ($indicator in $ProjectIndicators) {
    if (Test-Path $indicator) {
        $IsProjectDir = $true
        break
    }
}

if (-not $IsProjectDir) {
    Write-Warning "This doesn't look like a project directory."
    $currentDir = Split-Path -Leaf (Get-Location)
    $newDir = "$currentDir-copilot"
    Write-Info "Creating a new project directory: $newDir"

    New-Item -ItemType Directory -Path $newDir -Force | Out-Null
    Set-Location $newDir
    Write-Success "Created project directory: $(Get-Location)"
}

# Step 1: Download the template
Write-Step "Downloading Ultimate Copilot template..."

$tempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$zipUrl = "$RepoUrl/archive/refs/heads/main.zip"
$zipPath = Join-Path $tempDir "copilot-goat.zip"

try {
    if (Test-Command "curl") {
        & curl -L $zipUrl -o $zipPath
    }
    elseif (Test-Command "wget") {
        & wget $zipUrl -O $zipPath
    }
    else {
        # Use PowerShell's Invoke-WebRequest
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
    }
    Write-Success "Template downloaded successfully"
}
catch {
    Write-Error "Failed to download template: $($_.Exception.Message)"
    exit 1
}

# Step 2: Extract template
Write-Step "Extracting template files..."

try {
    # Use PowerShell's Expand-Archive
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    Write-Success "Template extracted successfully"
}
catch {
    Write-Error "Failed to extract template: $($_.Exception.Message)"
    exit 1
}

# Step 3: Copy template files (excluding existing source code)
Write-Step "Installing template files..."

$templateDir = Join-Path $tempDir "copilot-goat-main"

# Copy .github directory
$githubSource = Join-Path $templateDir ".github"
if (Test-Path $githubSource) {
    Copy-Item -Path $githubSource -Destination "." -Recurse -Force
    Write-Success "AI instructions installed"
}

# Copy .vscode directory
$vscodeSource = Join-Path $templateDir ".vscode"
if (Test-Path $vscodeSource) {
    Copy-Item -Path $vscodeSource -Destination "." -Recurse -Force
    Write-Success "VS Code configuration installed"
}

# Copy scripts directory
$scriptsSource = Join-Path $templateDir "scripts"
if (Test-Path $scriptsSource) {
    Copy-Item -Path $scriptsSource -Destination "." -Recurse -Force
    # Make PowerShell scripts executable (set execution policy if needed)
    $psScripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -ErrorAction SilentlyContinue
    if ($psScripts.Count -gt 0) {
        Write-Info "PowerShell scripts found. You may need to adjust execution policy:"
        Write-Info "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    }
    Write-Success "Automation scripts installed"
}

# Copy docs directory if it doesn't exist
$docsSource = Join-Path $templateDir "docs"
if ((-not (Test-Path "docs")) -and (Test-Path $docsSource)) {
    Copy-Item -Path $docsSource -Destination "." -Recurse -Force
    Write-Success "Documentation templates installed (including docs/goat/ guides)"
}

# Copy README if it doesn't exist or is very basic
$readmeSource = Join-Path $templateDir "README.md"
if ((-not (Test-Path "README.md")) -or ((Get-Content "README.md" -ErrorAction SilentlyContinue | Measure-Object -Line).Lines -lt 10)) {
    if (Test-Path $readmeSource) {
        Copy-Item -Path $readmeSource -Destination "README.md" -Force
        Write-Success "Enhanced README installed"
    }
}

# Copy .gitignore if it doesn't exist
$gitignoreSource = Join-Path $templateDir ".gitignore"
if ((-not (Test-Path ".gitignore")) -and (Test-Path $gitignoreSource)) {
    Copy-Item -Path $gitignoreSource -Destination ".gitignore" -Force
    Write-Success ".gitignore installed"
}

# Copy other important files
$importantFiles = @("LICENSE", "CONTRIBUTING.md", "SECURITY.md", "CHANGELOG.md", "CODE_OF_CONDUCT.md", "HELPFUL_PROMPTS.md")
foreach ($file in $importantFiles) {
    $sourceFile = Join-Path $templateDir $file
    if ((Test-Path $sourceFile) -and (-not (Test-Path $file))) {
        Copy-Item -Path $sourceFile -Destination $file -Force
        Write-Success "$file installed"
    }
}

# Step 4: Clean up
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Step 5: Run the main setup script
Write-Step "Running main setup script..."

$setupScript = "scripts\setup.ps1"
if (Test-Path $setupScript) {
    try {
        & ".\$setupScript"
    }
    catch {
        Write-Error "Setup script failed: $($_.Exception.Message)"
        exit 1
    }
}
else {
    # Try bash version as fallback
    $bashSetup = "scripts/setup.sh"
    if (Test-Path $bashSetup) {
        Write-Warning "PowerShell setup script not found, trying bash version..."
        if (Test-Command "bash") {
            & bash $bashSetup
        }
        else {
            Write-Error "Neither PowerShell nor bash setup script could be executed!"
            exit 1
        }
    }
    else {
        Write-Error "No setup script found!"
        exit 1
    }
}

# Success message
Write-Host ""
Write-Host "$($Emojis.Star)$($Emojis.Star)$($Emojis.Star) QUICK INSTALL COMPLETE! $($Emojis.Star)$($Emojis.Star)$($Emojis.Star)" -ForegroundColor $Colors.Green
Write-Host "============================================" -ForegroundColor $Colors.Cyan
Write-Host ""
Write-Host "$($Emojis.Fire) Your Ultimate Copilot workspace is ready in $(Get-Location)!" -ForegroundColor $Colors.Yellow
Write-Host ""
Write-Host "$($Emojis.Brain) Next steps:" -ForegroundColor $Colors.Blue
Write-Host "  1. Open VS Code: code ." -ForegroundColor $Colors.Cyan
Write-Host "  2. Open Copilot Chat: Ctrl+Alt+I" -ForegroundColor $Colors.Cyan
Write-Host "  3. Try a task: Ctrl+Shift+P > 'Tasks: Run Task'" -ForegroundColor $Colors.Cyan
Write-Host "  4. Start coding with AI superpowers!" -ForegroundColor $Colors.Cyan
Write-Host ""
Write-Host "$($Emojis.Rocket) Welcome to the G.O.A.T Copilot experience!" -ForegroundColor $Colors.Purple
