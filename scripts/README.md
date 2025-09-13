# 🛠️ Ultimate GitHub Copilot Workspace Scripts

This directory contains automation scripts for setting up and managing the Ultimate GitHub Copilot workspace across different platforms.

## 📋 Available Scripts

### 🚀 Quick Installation Scripts

#### `quick-install.sh` (Linux/macOS)
**One-Line Install (Linux/macOS):**

```bash
curl -L https://raw.githubusercontent.com/greysquirr3l/copilot-goat/main/scripts/quick-install.sh | bash
# or
wget https://raw.githubusercontent.com/greysquirr3l/copilot-goat/main/scripts/quick-install.sh

**Features:**
- 🔍 Auto-detects project type
- 📥 Downloads latest template
- 🛠️ Runs complete setup
- ✅ Cross-platform compatibility (macOS, Linux)

#### `quick-install.ps1` (Windows)
**PowerShell installation for Windows systems**

```powershell
# Download and run
iwr -useb https://raw.githubusercontent.com/greysquirr3l/copilot-goat/main/scripts/quick-install.ps1 | iex

# Or download first
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/greysquirr3l/copilot-goat/main/scripts/quick-install.ps1" -OutFile "quick-install.ps1"
.\quick-install.ps1
```

**Features:**
- 💻 Native PowerShell implementation
- 🎨 Rich colored output with emojis
- 🔧 Windows-specific optimizations
- 🌐 Cross-shell compatibility (PowerShell, CMD)

### ⚙️ Full Setup Scripts

#### `setup.sh` (Linux/macOS)
**Complete workspace configuration for Unix-like systems**

```bash
./setup.sh
```

**Capabilities:**
- 🧩 VS Code extension installation
- 🔗 Git configuration and enhanced hooks
- 🎯 Language-specific tool installation
- 📝 Project template customization
- 🛡️ Security and quality gate setup

#### `setup.ps1` (Windows)
**Complete workspace configuration for Windows**

```powershell
.\setup.ps1 [options]

# Available parameters
.\setup.ps1 -SkipExtensions    # Skip VS Code extensions
.\setup.ps1 -SkipGitSetup      # Skip Git configuration
.\setup.ps1 -Verbose           # Enable verbose output
.\setup.ps1 -Help              # Show help information
```

**Capabilities:**
- 🧩 VS Code extension installation with Windows compatibility
- 🔗 Git hooks using Windows batch files
- 🎯 Language-specific tool installation (.NET, Node.js, etc.)
- 📝 PowerShell profile integration
- 🛡️ Windows-specific security configurations

## 🎯 Usage Scenarios

### New Project Creation

**Linux/macOS:**

```bash
mkdir my-awesome-project
cd my-awesome-project
curl -L https://github.com/greysquirr3l/copilot-goat/archive/refs/heads/main.zip | tar -xz --strip-components=1
./scripts/setup.sh
```

**Windows:**

```powershell
mkdir my-awesome-project
cd my-awesome-project
Invoke-WebRequest -Uri "https://github.com/greysquirr3l/copilot-goat/archive/refs/heads/main.zip" -OutFile "template.zip"
Expand-Archive template.zip
Copy-Item template\copilot-goat-main\* . -Recurse -Force
.\scripts\setup.ps1
```

### Existing Project Enhancement

**Linux/macOS:**

```bash
cd existing-project
curl -L https://github.com/greysquirr3l/copilot-goat/archive/refs/heads/main.zip | tar -xz --strip-components=1
./scripts/setup.sh
```

**Windows:**

```powershell
cd existing-project
.\scripts\quick-install.ps1
```

## 🔧 Script Features Comparison

| Feature | setup.sh | setup.ps1 | quick-install.sh | quick-install.ps1 |
|---------|----------|-----------|------------------|-------------------|
| **Platform** | Linux/macOS | Windows | Linux/macOS | Windows |
| **One-command install** | ❌ | ❌ | ✅ | ✅ |
| **VS Code extensions** | ✅ | ✅ | ➡️ (via setup) | ➡️ (via setup) |
| **Git configuration** | ✅ | ✅ | ➡️ (via setup) | ➡️ (via setup) |
| **Language detection** | ✅ | ✅ | ✅ | ✅ |
| **Tool installation** | ✅ | ✅ | ➡️ (via setup) | ➡️ (via setup) |
| **Template download** | ❌ | ❌ | ✅ | ✅ |
| **Colored output** | ✅ | ✅ | ✅ | ✅ |
| **Error handling** | ✅ | ✅ | ✅ | ✅ |

## 🚀 Language-Specific Features

### Supported Languages

Both script versions automatically detect and configure:

- **Go** (`go.mod` detected)
  - golangci-lint installation
  - goimports configuration
  - Go formatting setup

- **JavaScript/TypeScript** (`package.json` detected)
  - ESLint and Prettier installation
  - TypeScript configuration
  - npm script integration

- **Python** (`requirements.txt`, `pyproject.toml` detected)
  - Black, flake8, mypy installation
  - pytest configuration
  - Virtual environment handling

- **C#/.NET** (`*.csproj`, `*.sln` detected)
  - dotnet-format installation
  - NuGet package management
  - MSBuild integration

- **Rust** (`Cargo.toml` detected)
  - Clippy configuration
  - rustfmt setup
  - Cargo integration

- **Java** (`pom.xml`, `build.gradle` detected)
  - Maven/Gradle integration
  - Java formatting tools

## 🛡️ Security Features

### Git Hooks

- **Pre-commit validation** with AI assistance hints
- **Commit message templates** with emoji guidelines
- **Secret detection** preventing accidental commits
- **Code formatting** integration

### File Permissions

- **Linux/macOS**: Automatic executable permissions for shell scripts
- **Windows**: PowerShell execution policy guidance
- **Cross-platform**: Secure file handling

## 🎨 Customization Options

### Environment Variables

Both scripts respect these environment variables:

```bash
# Linux/macOS
export COPILOT_SKIP_EXTENSIONS=true    # Skip VS Code extensions
export COPILOT_SKIP_GIT_SETUP=true     # Skip Git configuration
export COPILOT_VERBOSE=true            # Enable verbose output
```

```powershell
# Windows
$env:COPILOT_SKIP_EXTENSIONS = "true"   # Skip VS Code extensions
$env:COPILOT_SKIP_GIT_SETUP = "true"    # Skip Git configuration
$env:COPILOT_VERBOSE = "true"           # Enable verbose output
```

### Configuration Files

Scripts create and modify:
- `.vscode/settings.json` - VS Code optimization
- `.github/copilot-instructions.md` - AI instructions
- `.gitignore` - Cross-platform ignore rules
- `.git/hooks/*` - Enhanced Git hooks
- `.copilot-aliases` - Helpful command aliases

## 🔍 Troubleshooting

### Common Issues

#### Linux/macOS

```bash
# Permission denied
chmod +x scripts/*.sh

# curl not found
sudo apt-get install curl  # Ubuntu/Debian
brew install curl          # macOS

# VS Code CLI not found
# Install VS Code and enable shell command
```

#### Windows

```powershell
# Execution policy error
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# PowerShell version too old
# Install PowerShell 7+ from Microsoft Store

# VS Code CLI not found
# Install VS Code and add to PATH
```

### Getting Help

**Command-line help:**

```bash
./scripts/setup.sh --help              # Linux/macOS
.\scripts\setup.ps1 -Help              # Windows
```

**Debug mode:**

```bash
bash -x scripts/setup.sh               # Linux/macOS debug
.\scripts\setup.ps1 -Verbose          # Windows verbose
```

## 📚 Related Documentation

- [Main README](../README.md) - Complete workspace documentation
- **[Template Customization](../docs/goat/TEMPLATE_CUSTOMIZATION_GUIDE.md)** - Customize for your project
- **[Memory Systems Guide](../docs/goat/MEMORY_SYSTEMS_GUIDE.md)** - AI memory configuration
- **[Quick Reference Card](../docs/goat/QUICK_REFERENCE_CARD.md)** - Fast lookup guide
- **[MCP Setup Guide](../docs/goat/MCP_SERVER_SETUP_GUIDE.md)** - Model Context Protocol setup
- [AI Instructions](../.github/copilot-instructions.md) - AI configuration
- [CHANGELOG](../CHANGELOG.md) - Version history

## 🤝 Contributing

To contribute new scripts or improve existing ones:

1. **Test on multiple platforms** - Ensure cross-platform compatibility
2. **Follow naming conventions** - Use descriptive, consistent names
3. **Add error handling** - Graceful failure and recovery
4. **Document thoroughly** - Clear usage instructions and examples
5. **Include colors and emojis** - Maintain consistent UX across platforms

---

**🚀 Happy automating with the Ultimate Copilot workspace!**
