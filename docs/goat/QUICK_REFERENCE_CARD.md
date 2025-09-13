# 🎯 GitHub Copilot Workspace - Quick Reference Card

> **Developer Cheat Sheet**: Essential prompts and workflows for the Ultimate GitHub Copilot Workspace

---

## ⚡ Quick Start Commands

```bash
# 1. Create new project from template
git clone https://github.com/greysquirr3l/copilot-goat.git {PROJECT_NAME}
cd {PROJECT_NAME}

# 2. Open in VS Code
code .

# 3. Run setup verification
# Ctrl/Cmd + Shift + P → "Tasks: Run Task" → "Verify Setup"
```

---

## 🎯 Essential AI Prompts

### 🚀 **Project Initialization**
```
Initialize this GitHub Copilot workspace for:
- Language: {LANGUAGE}
- Framework: {FRAMEWORK}
- Project type: {PROJECT_TYPE}
- Architecture: {ARCHITECTURE}

Please customize the copilot instructions, set up directory structure, and configure build tasks.
```

### 🏗️ **Feature Development**
```
Create a new {FEATURE_NAME} feature following our established patterns:
- Use our error handling conventions
- Include comprehensive logging
- Add unit tests with {TESTING_FRAMEWORK}
- Follow security best practices
- Include API documentation
```

### 🔧 **Code Enhancement**
```
Enhance this code with:
- SOLID principles application
- Performance optimizations for {LANGUAGE}
- Proper error handling and recovery
- Comprehensive test coverage
- Security vulnerability fixes
```

### 🧪 **Testing & Quality**
```
Generate comprehensive tests for this code:
- Unit tests covering all branches
- Integration tests for external dependencies
- Edge cases and error conditions
- Performance benchmarks
- Security test cases
```

### 🔒 **Security Review**
```
Review this code for security issues:
- Input validation and sanitization
- Authentication and authorization
- Data encryption requirements
- SQL injection prevention
- Cross-site scripting (XSS) protection
```

---

## 📋 Development Workflows

### **New Feature Workflow**
1. **Plan**: Define feature requirements with AI assistance
2. **Design**: Create architecture with security considerations
3. **Implement**: Use AI for code generation with patterns
4. **Test**: Generate comprehensive test suites
5. **Review**: AI-assisted code review checklist
6. **Deploy**: Automated deployment with quality gates

### **Bug Fix Workflow**
1. **Analyze**: AI-assisted root cause analysis
2. **Reproduce**: Create failing test cases
3. **Fix**: Implement solution with proper error handling
4. **Test**: Verify fix doesn't break existing functionality
5. **Document**: Update documentation and runbooks

---

## 🎨 Language-Specific Quick Prompts

### **Go Development**
```
Create a Go {COMPONENT_TYPE} with:
- Proper context handling
- Structured logging with slog
- Graceful error wrapping
- Concurrent safety considerations
- Benchmark tests included
```

### **Python Development**
```
Build a Python {COMPONENT_TYPE} using:
- Type hints and dataclasses
- Async/await patterns where appropriate
- Comprehensive error handling
- pytest test suite
- Proper logging configuration
```

### **TypeScript/JavaScript**
```
Develop a TypeScript {COMPONENT_TYPE} with:
- Strong typing and interfaces
- Promise-based error handling
- Jest/Vitest test coverage
- ESLint compliance
- Performance optimizations
```

### **Java Development**
```
Create a Java {COMPONENT_TYPE} featuring:
- Spring Boot best practices
- JUnit 5 test suite
- Proper exception hierarchy
- Lombok annotations
- Maven/Gradle configuration
```

### **.NET 8+ Development**
```
Build a .NET 8+ {COMPONENT_TYPE} with:
- Minimal APIs and dependency injection
- Record types and nullable reference types
- Result pattern for error handling
- xUnit testing with WebApplicationFactory
- Entity Framework Core with migrations
- FluentValidation for request validation
```

---

## 🔧 Common Tasks & Shortcuts

### **VS Code Tasks** (Ctrl/Cmd + Shift + P)
- `Tasks: Run Task` → `Build` - Build the project
- `Tasks: Run Task` → `Test` - Run all tests
- `Tasks: Run Task` → `Lint` - Run linting and formatting
- `Tasks: Run Task` → `Security Scan` - Run security analysis
- `Tasks: Run Task` → `Full Check` - Complete quality validation

### **Git Integration**
```bash
# Pre-commit validation
npm run pre-commit  # or equivalent for your language

# Conventional commit format
git commit -m "feat(scope): description"
git commit -m "fix(scope): description"
git commit -m "docs(scope): description"
```

---

## 📊 Quality Gates Checklist

### ✅ **Pre-Commit Checklist**
- [ ] Code formatting applied
- [ ] Linting errors resolved
- [ ] Unit tests passing
- [ ] Security scan clean
- [ ] Documentation updated

### ✅ **Pre-Deploy Checklist**
- [ ] All tests passing (unit, integration, e2e)
- [ ] Code coverage above threshold
- [ ] Performance benchmarks met
- [ ] Security vulnerabilities addressed
- [ ] Dependencies updated and scanned

---

## 🚨 Troubleshooting Quick Fixes

### **Copilot Not Responding**
```
# Check AI instructions are loaded
1. Verify .github/copilot-instructions.md exists
2. Restart VS Code
3. Check Copilot extension status
4. Refresh context with descriptive comments
```

### **Build/Test Failures**
```
# Quick diagnosis prompt
Analyze this build/test failure and suggest fixes:
- Error message: {ERROR_MESSAGE}
- Technology stack: {TECH_STACK}
- Recent changes: {RECENT_CHANGES}
```

### **Performance Issues**
```
# Performance optimization prompt
Optimize this code for performance:
- Current bottleneck: {BOTTLENECK}
- Target improvement: {IMPROVEMENT_GOAL}
- Technology constraints: {CONSTRAINTS}
```

---

## 📞 Quick Help

**Prompt Template for Getting Help:**
```
I need help with {SPECIFIC_ISSUE}:
- Project: {PROJECT_TYPE} using {TECH_STACK}
- Current error: {ERROR_DESCRIPTION}
- What I tried: {ATTEMPTED_SOLUTIONS}
- Expected outcome: {DESIRED_RESULT}
```

---

## 🎯 Power User Tips

1. **Context Stacking**: Build rich context with multiple related files open
2. **Pattern Recognition**: Establish consistent patterns early for better suggestions
3. **Incremental Development**: Use AI for step-by-step feature building
4. **Test-Driven Prompts**: Ask for tests first, then implementation
5. **Documentation Driven**: Start with clear specifications for better code generation

---

*Keep this card handy for maximum GitHub Copilot productivity! 🚀*

*Version: 2.0.0 | For issues: Contact DevOps Team*
