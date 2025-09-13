# 🪝 Git Hooks Customization Guide

This guide helps you set up and customize Git hooks for your project using the Ultimate GitHub Copilot Template. Git hooks automate quality checks and enforce team standards before commits and pushes.

## 🚀 Quick Setup

### Automated Hook Installation

```bash
# Run the provided setup script
./scripts/setup-pre-commit-hooks.sh

# Or set up manually (see sections below)
```

### Manual Hook Setup

1. **Navigate to hooks directory**:
   ```bash
   cd .git/hooks
   ```

2. **Create executable hook files** (remove `.sample` extensions from existing files)

3. **Use the Copilot prompts below** to generate customized hooks for your project

## 🎯 Copilot Prompts for Git Hooks

### 1. Pre-commit Hook Creation

```
🎯 COPILOT PROMPT: Pre-commit Hook
Create a comprehensive pre-commit git hook for my [LANGUAGE] project:

Project Details:
- Primary Language: [Go/Python/TypeScript/Java/C#/etc.]
- Framework: [YOUR_FRAMEWORK]
- Package Manager: [npm/pip/go mod/cargo/dotnet/etc.]
- Testing Tool: [jest/pytest/go test/junit/xunit/etc.]
- Linter: [eslint/flake8/golangci-lint/etc.]
- Formatter: [prettier/black/gofmt/etc.]

Hook Requirements:
1. Code formatting validation
2. Linting checks with error reporting
3. Unit test execution
4. Security vulnerability scanning
5. Commit message format validation
6. No secrets/sensitive data detection
7. Build verification (if applicable)
8. Performance regression checks (if applicable)

Generate a bash script that:
- Runs checks efficiently (parallel where possible)
- Provides clear error messages
- Allows bypass with --no-verify if needed
- Integrates with CI/CD pipeline
- Works on both Unix and Windows (via Git Bash)

Make it production-ready with proper error handling.
```

### 2. Commit Message Validation Hook

```
🎯 COPILOT PROMPT: Commit Message Hook
Create a commit-msg git hook that enforces our team standards:

Message Format Requirements:
- Conventional Commits format (type(scope): description)
- Maximum line lengths (50 for summary, 72 for body)
- Required issue/ticket references (if applicable)
- Prohibited words or patterns
- Minimum description length
- Valid commit types: [feat, fix, docs, style, refactor, test, chore, etc.]

Domain Context:
- Project Type: [YOUR_PROJECT_TYPE]
- Team Size: [SMALL/MEDIUM/LARGE]
- Issue Tracking: [GitHub Issues/Jira/Linear/etc.]
- Methodology: [Agile/Scrum/Kanban/etc.]

Generate a script that:
- Validates commit message format
- Provides helpful error messages with examples
- Allows emergency commits with specific override
- Integrates with issue tracking system
- Supports team conventions and standards

Include clear documentation and examples.
```

### 3. Pre-push Hook Creation

```
🎯 COPILOT PROMPT: Pre-push Hook
Create a pre-push git hook for comprehensive quality assurance:

Quality Gates:
- Full test suite execution
- Integration test validation
- Security scanning (SAST/dependency check)
- Performance benchmarks
- Documentation validation
- Build verification for all environments
- Branch protection compliance

Branch Rules:
- Protected branches: [main, develop, release/*]
- Required review completion check
- Up-to-date branch validation
- Conflict resolution verification

Environment: [YOUR_TECH_STACK]
CI/CD: [GitHub Actions/GitLab CI/Jenkins/etc.]

Generate a script that:
- Validates branch protection rules
- Runs comprehensive quality checks
- Prevents broken code from reaching remote
- Integrates with CI/CD pipeline
- Provides detailed feedback on failures
- Allows emergency pushes with proper authorization

Make it robust and team-friendly.
```

### 4. Post-commit Hook for Automation

```
🎯 COPILOT PROMPT: Post-commit Hook
Create a post-commit git hook for development workflow automation:

Automation Tasks:
- Automatic documentation generation (if docs changed)
- Dependency vulnerability notifications
- Code metrics collection
- Team notifications (if applicable)
- Issue tracker updates
- Development environment synchronization

Integration Points:
- Issue Tracking: [YOUR_ISSUE_TRACKER]
- Communication: [Slack/Teams/Discord/etc.]
- Documentation: [README/Wiki/Confluence/etc.]
- Monitoring: [YOUR_MONITORING_TOOLS]

Generate a script that:
- Runs automation tasks asynchronously
- Handles failures gracefully (non-blocking)
- Provides optional team notifications
- Updates relevant external systems
- Maintains audit trail
- Works across different development environments

Focus on enhancing developer productivity without slowing down commits.
```

## 🔧 Language-Specific Hook Examples

### Go Project Hook

```
🎯 COPILOT PROMPT: Go Pre-commit Hook
Create a Go-specific pre-commit hook:

Go Tools:
- go fmt (formatting)
- go vet (static analysis)
- golangci-lint (comprehensive linting)
- go test (unit tests)
- go mod tidy (dependency management)
- gosec (security scanning)

Requirements:
- Check all .go files for formatting
- Run comprehensive linting
- Execute tests with coverage
- Validate go.mod and go.sum
- Security vulnerability scanning
- Build verification

Make it fast and developer-friendly.
```

### Python Project Hook

```
🎯 COPILOT PROMPT: Python Pre-commit Hook
Create a Python-specific pre-commit hook:

Python Tools:
- black (code formatting)
- flake8 or ruff (linting)
- mypy (type checking)
- pytest (testing)
- safety (dependency security)
- isort (import sorting)

Requirements:
- Format all Python files
- Lint with comprehensive rules
- Type checking validation
- Run test suite with coverage
- Security scanning of dependencies
- Import statement organization

Support both pip and poetry environments.
```

### TypeScript/Node.js Hook

```
🎯 COPILOT PROMPT: TypeScript Pre-commit Hook
Create a TypeScript/Node.js pre-commit hook:

JavaScript/TypeScript Tools:
- prettier (code formatting)
- eslint (linting)
- tsc (TypeScript compilation)
- jest/vitest (testing)
- npm audit (security)
- lint-staged (staged files only)

Requirements:
- Format all JS/TS files
- Lint with project-specific rules
- TypeScript compilation check
- Run relevant tests
- Security audit
- Package.json validation

Support both npm and yarn workflows.
```

### .NET Project Hook

```
🎯 COPILOT PROMPT: .NET Pre-commit Hook
Create a .NET-specific pre-commit hook:

.NET Tools:
- dotnet format (code formatting)
- dotnet build (compilation)
- dotnet test (unit tests)
- dotnet list package --vulnerable (security)
- EditorConfig compliance

Requirements:
- Format all C# files
- Build solution/projects
- Run unit test suite
- Security vulnerability check
- Code analysis warnings
- NuGet package validation

Support multiple target frameworks.
```

## 🛠️ Advanced Hook Configurations

### Multi-Language Project Hook

```
🎯 COPILOT PROMPT: Multi-Language Hook
Create a pre-commit hook for a polyglot project:

Languages in Project:
- [LIST_YOUR_LANGUAGES]
- [CORRESPONDING_FRAMEWORKS]

Requirements:
- Detect changed files by language
- Run appropriate tools per language
- Parallel execution for performance
- Unified reporting format
- Language-specific configuration
- Shared quality standards

Create a modular system that's easy to extend.
```

### Performance-Optimized Hook

```
🎯 COPILOT PROMPT: Performance Hook
Create a high-performance pre-commit hook:

Performance Requirements:
- Run only on changed files
- Parallel execution where possible
- Caching for expensive operations
- Incremental checks
- Fast-fail on critical issues
- Progress indicators for slow operations

Large Repository Optimizations:
- File filtering strategies
- Tool-specific optimizations
- Resource usage management
- Network operation caching

Make it suitable for large teams and repositories.
```

### Security-Focused Hook

```
🎯 COPILOT PROMPT: Security Hook
Create a security-focused pre-commit hook:

Security Checks:
- Secret detection (API keys, passwords, tokens)
- Dependency vulnerability scanning
- SAST (Static Application Security Testing)
- License compatibility checking
- Sensitive file prevention
- Code injection pattern detection

Compliance Requirements:
- [YOUR_COMPLIANCE_STANDARDS]
- Audit trail generation
- Policy violation reporting
- Exception handling process

Generate comprehensive security validation.
```

## 📋 Hook Configuration Templates

### Basic Hook Template

```bash
#!/bin/bash
# Template structure for any git hook

set -e  # Exit on error

# Configuration
PROJECT_ROOT=$(git rev-parse --show-toplevel)
HOOK_NAME=$(basename "$0")

# Logging
log() {
    echo "[$HOOK_NAME] $1"
}

error() {
    echo "[$HOOK_NAME] ERROR: $1" >&2
    exit 1
}

# Main logic here
main() {
    log "Starting $HOOK_NAME checks..."

    # Your custom checks go here

    log "$HOOK_NAME completed successfully"
}

# Execute main function
main "$@"
```

### Hook with Bypass Mechanism

```bash
#!/bin/bash
# Hook with emergency bypass capability

# Check for bypass flag
if git rev-parse --verify HEAD >/dev/null 2>&1; then
    against=HEAD
else
    against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

# Allow bypass with --no-verify or emergency commit message
if git log -1 --pretty=format:%s | grep -q "EMERGENCY\|HOTFIX"; then
    echo "Emergency commit detected, bypassing hooks"
    exit 0
fi

# Your normal hook logic here
```

## 🎭 Team Customization

### Team Standards Hook

```
🎯 COPILOT PROMPT: Team Standards Hook
Create git hooks that enforce our team's coding standards:

Team Context:
- Team Size: [NUMBER]
- Experience Levels: [MIXED/SENIOR/JUNIOR]
- Code Review Process: [DESCRIPTION]
- Quality Requirements: [YOUR_STANDARDS]
- Communication Preferences: [TOOLS]

Standards to Enforce:
- Code style and formatting
- Documentation requirements
- Test coverage minimums
- Security compliance
- Performance benchmarks
- Architecture pattern compliance

Make it educational and team-friendly, not punitive.
```

## 🚀 Installation and Maintenance

### Hook Installation Script

```
🎯 COPILOT PROMPT: Hook Installation
Create a script that sets up all our git hooks:

Setup Requirements:
- Copy hook files to .git/hooks/
- Make them executable
- Set up configuration files
- Install required tools/dependencies
- Validate hook functionality
- Provide troubleshooting guidance

Cross-Platform Support:
- Works on macOS, Linux, and Windows
- Handles different shell environments
- Manages tool installation across platforms

Generate user-friendly setup automation.
```

### Hook Maintenance

```
🎯 COPILOT PROMPT: Hook Maintenance
Create maintenance procedures for our git hooks:

Maintenance Tasks:
- Regular updates for new tools/versions
- Performance optimization
- Configuration updates
- Team feedback integration
- Documentation updates
- Cross-platform compatibility testing

Change Management:
- Version control for hooks
- Rollback procedures
- Team notification of changes
- Migration guides for updates

Generate sustainable maintenance processes.
```

## 📚 Best Practices

### Hook Development Guidelines

1. **Performance**: Make hooks fast - developers shouldn't wait
2. **Reliability**: Handle edge cases and failures gracefully
3. **Clarity**: Provide clear, actionable error messages
4. **Flexibility**: Allow bypasses for emergency situations
5. **Maintainability**: Keep hooks simple and well-documented
6. **Cross-platform**: Ensure compatibility across development environments

### Common Pitfalls to Avoid

1. **Slow hooks** that frustrate developers
2. **Brittle scripts** that break with minor changes
3. **Unclear error messages** that don't help fix issues
4. **Platform-specific code** that doesn't work everywhere
5. **Complex logic** that's hard to debug and maintain

## 🆘 Troubleshooting

### Common Issues

```
🎯 COPILOT PROMPT: Hook Troubleshooting
Create troubleshooting guide for our git hooks:

Common Issues:
- Hook not executing (permissions, shebang)
- Tool not found (PATH issues, installation)
- Performance problems (slow execution)
- False positives (incorrect failure detection)
- Platform compatibility (Windows/Unix differences)

For each issue provide:
- Symptoms description
- Root cause analysis
- Step-by-step resolution
- Prevention strategies

Make it comprehensive for self-service debugging.
```

## 📖 Usage Examples

After setting up hooks, developers can:

1. **Normal commits**: Hooks run automatically and provide feedback
2. **Emergency bypass**: Use `git commit --no-verify` when needed
3. **Hook debugging**: Run hooks manually to test changes
4. **Team coordination**: Share hook configurations and updates

This system ensures consistent code quality while maintaining developer productivity and team collaboration effectiveness.

---

*This guide integrates with the Ultimate GitHub Copilot Template to provide comprehensive, AI-assisted git workflow automation. All prompts are designed to work with GitHub Copilot for optimal customization results.*
