# 🚀 Ultimate GitHub Copilot Instructions Template

## Project Overview

[CUSTOMIZE]: Replace with your project description

**Project Name**: [YOUR_PROJECT_NAME]
**Primary Language**: [YOUR_PRIMARY_LANGUAGE]
**Framework/Stack**: [YOUR_TECH_STACK]
**Architecture Pattern**: [e.g., Clean Architecture, MVC, Microservices, etc.]
**Domain**: [e.g., E-commerce, Financial Services, Healthcare, etc.]

### Tech Stack Template

```text
Primary Language: [Go/Python/TypeScript/Java/C#/Rust/etc.]
Framework: [Express/FastAPI/Spring Boot/ASP.NET/Gin/etc.]
Database: [PostgreSQL/MongoDB/MySQL/Redis/etc.]
Cache: [Redis/Memcached/In-Memory/etc.]
Message Queue: [RabbitMQ/Apache Kafka/AWS SQS/etc.]
Container: [Docker/Podman/etc.]
Orchestration: [Kubernetes/Docker Compose/etc.]
Testing: [Jest/pytest/Go testing/JUnit/etc.]
CI/CD: [GitHub Actions/GitLab CI/Jenkins/etc.]
```

## 🏗️ Architecture Patterns

[CUSTOMIZE]: Select and customize your architecture pattern

### Clean Architecture + Domain-Driven Design

```text
- Domain Layer: Core business logic, entities, value objects
- Application Layer: Use cases, application services, DTOs
- Infrastructure Layer: External concerns (database, APIs, etc.)
- Interface Layer: Controllers, presenters, external interfaces
```

### Alternative Patterns (Choose One)

- **MVC**: Model-View-Controller for web applications
- **Microservices**: Distributed services with clear boundaries
- **Event-Driven**: Async communication via events
- **Layered Architecture**: Traditional n-tier architecture
- **Hexagonal Architecture**: Ports and adapters pattern

## 📁 Directory Structure Template

[CUSTOMIZE]: Adapt to your language and architecture

```text
project-root/
├── src/                          # Source code
│   ├── domain/                   # Core business logic
│   ├── application/              # Use cases and services
│   ├── infrastructure/           # External dependencies
│   └── interfaces/               # Controllers, handlers
├── tests/                        # Test files
│   ├── unit/                     # Unit tests
│   ├── integration/              # Integration tests
│   └── e2e/                      # End-to-end tests
├── docs/                         # Documentation
├── scripts/                      # Build and utility scripts
├── configs/                      # Configuration files
└── deployments/                  # Deployment manifests
```

## 🎯 Development Standards

### Naming Conventions

[CUSTOMIZE]: Adapt to your language conventions

**[LANGUAGE_SPECIFIC]** Examples:
- **Go**: PascalCase for exported, camelCase for unexported
- **Python**: snake_case for functions/variables, PascalCase for classes
- **JavaScript/TypeScript**: camelCase for variables/functions, PascalCase for classes/interfaces
- **Java/C#**: PascalCase for classes/methods, camelCase for variables
- **Rust**: snake_case for functions/variables, PascalCase for types

### File Organization Patterns

```text
Feature-based grouping within domain boundaries
Separation of concerns following chosen architecture
Test files co-located with source files
Configuration files in dedicated directory
Documentation alongside relevant code
```

### Code Quality Standards

```text
- Consistent formatting with language-specific tools
- Comprehensive error handling
- Input validation on all external inputs
- Proper logging with structured format
- Security-first approach (authentication, authorization, input sanitization)
- Performance considerations (caching, database optimization, etc.)
```

## 🧪 Testing Guidelines

[CUSTOMIZE]: Adapt to your testing framework

### Testing Strategy

```text
- Unit Tests: Test individual components in isolation
- Integration Tests: Test component interactions
- End-to-End Tests: Test complete user workflows
- Performance Tests: Load and stress testing
- Security Tests: Vulnerability and penetration testing
```

### Test Patterns

```text
- Arrange-Act-Assert (AAA) pattern
- Test data factories for consistent test data
- Mock external dependencies
- Table-driven tests for multiple scenarios
- Parallel test execution where appropriate
```

### Coverage Requirements

```text
- Unit Tests: [80%] minimum coverage for business logic
- Integration Tests: [60%] minimum coverage overall
- Critical Path: [100%] coverage for critical business functions
```

## 🔒 Security Requirements

[CUSTOMIZE]: Add domain-specific security requirements

### Security Standards

```text
- Input validation and sanitization
- SQL injection prevention (parameterized queries)
- Authentication and authorization on all endpoints
- Secrets management (environment variables, secret managers)
- TLS/HTTPS for all external communications
- Rate limiting on public APIs
- Comprehensive audit logging for security events
- Data encryption at rest and in transit
```

### Domain-Specific Security

```text
[Add requirements specific to your domain]
- PCI DSS compliance (for payment processing)
- HIPAA compliance (for healthcare)
- GDPR compliance (for EU data processing)
- SOX compliance (for financial reporting)
```

## ⚡ Performance Guidelines

[CUSTOMIZE]: Add language and domain-specific performance patterns

### Performance Patterns

```text
- Database connection pooling
- Caching strategies (Redis, in-memory, CDN)
- Asynchronous processing where appropriate
- Pagination for large datasets
- Query optimization and indexing
- Resource cleanup and memory management
- Performance monitoring and profiling
```

### Language-Specific Optimizations

```text
[Add language-specific performance patterns]
- Go: Goroutines, channels, sync package usage
- Python: AsyncIO, multiprocessing, caching decorators
- JavaScript: Event loop optimization, worker threads
- Java: JVM tuning, garbage collection optimization
- C#: Memory management, async/await patterns
```

## 🚀 Development Workflow

### Branch Strategy

```text
- main/master: Production-ready code
- develop: Integration branch for features
- feature/[feature-name]: Feature development
- hotfix/[issue-name]: Critical production fixes
- release/[version]: Release preparation
```

### Commit Standards

```text
Format: type(scope): description

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style changes
- refactor: Code refactoring
- test: Test additions/modifications
- chore: Maintenance tasks

Example: feat(auth): add JWT token refresh mechanism
```

### Code Review Guidelines

```text
- Business logic correctness
- Error handling completeness
- Security considerations
- Performance implications
- Test coverage adequacy
- Documentation updates
- Architecture pattern compliance
```

## 📚 Documentation Integration Strategy

[CUSTOMIZE]: Reference your existing documentation

### Smart Reference System

For comprehensive technical documentation, use references to avoid context overload:

```markdown
**High-Value References:**
- [Architecture Guide](docs/architecture.md) - System design and patterns
- [API Standards](docs/api-guidelines.md) - REST/GraphQL standards
- [Security Patterns](docs/security.md) - Security implementation guide
- [Testing Guide](docs/testing.md) - Testing strategies and patterns
- [Performance Guide](docs/performance.md) - Optimization techniques
```

### Context-Aware Usage

```text
For [SPECIFIC_TASK] implementation:
1. Apply basic patterns from these instructions
2. Reference [SPECIFIC_DOC] for advanced patterns:
   - Section X: [Specific advanced pattern]
   - Section Y: [Complex implementation details]
   - Section Z: [Edge cases and solutions]
```

## 🤖 AI Assistant Optimization

### AI Assistance Guidelines

```text
- Provide domain context when requesting business logic
- Always request comprehensive error handling
- Ask for test generation alongside implementation
- Request security considerations for external-facing code
- Include performance considerations for data processing
- Validate generated code against project patterns
```

### Persona-Based Development Integration

```text
When using AI assistance, consider these specialized contexts:
- Requirements Gathering: Focus on user stories and acceptance criteria
- Technical Design: Emphasize architecture patterns and system design
- Implementation: Follow coding standards and best practices
- Testing: Comprehensive test coverage and quality assurance
- Code Review: Security, performance, and maintainability focus
- Debugging: Problem identification and solution strategies
```

### Model Context Protocol (MCP) Integration

```text
Enhanced AI capabilities through MCP:
- Filesystem access for project understanding
- Git integration for version control context
- External tool integration (linters, formatters, etc.)
- Custom domain-specific tools and knowledge bases
```

## 🔧 Tool Integration

### Development Tools

```text
[CUSTOMIZE]: List your specific tools
- Code Formatter: [prettier/gofmt/black/etc.]
- Linter: [eslint/golangci-lint/flake8/etc.]
- Type Checker: [TypeScript/mypy/etc.]
- Build Tool: [webpack/make/gradle/etc.]
- Package Manager: [npm/go mod/pip/etc.]
```

### CI/CD Integration

```text
- Automated testing on all branches
- Code quality checks (formatting, linting, security)
- Test coverage reporting and enforcement
- Security vulnerability scanning
- Performance benchmarking
- Documentation generation and validation
```

## 🎯 Success Metrics

### Code Quality Metrics

```text
- Test Coverage: [X]% minimum
- Code Duplication: <[X]%
- Cyclomatic Complexity: <[X] per function
- Technical Debt Ratio: <[X]%
```

### Performance Metrics

```text
- Response Time: <[X]ms for API endpoints
- Throughput: [X] requests/second minimum
- Memory Usage: <[X]MB baseline
- Database Query Time: <[X]ms average
```

### Security Metrics

```text
- Zero high/critical security vulnerabilities
- All external inputs validated and sanitized
- Authentication required for all protected resources
- Audit logging for all sensitive operations
```

## 🚦 Quality Gates

### Pre-Commit Requirements

```text
- All tests pass
- Code coverage thresholds met
- No linting errors
- Security scan passes
- Documentation updated
```

### Pre-Deploy Requirements

```text
- Full integration test suite passes
- Performance benchmarks met
- Security audit completed
- Infrastructure readiness verified
- Rollback plan documented
```

---

## 🛠️ Customization Checklist

Before using this template:

- [ ] Replace all `[CUSTOMIZE]` sections with project-specific information
- [ ] Update directory structure to match your project layout
- [ ] Adapt naming conventions to your chosen language
- [ ] Configure testing frameworks and coverage requirements
- [ ] Set domain-specific security requirements
- [ ] Configure performance metrics and optimization patterns
- [ ] Set up CI/CD pipeline requirements
- [ ] Create documentation reference system
- [ ] Configure development tools and integrations
- [ ] Set success metrics and quality gates

**This template provides the foundation for maximum GitHub Copilot effectiveness across any programming language or project type.**
