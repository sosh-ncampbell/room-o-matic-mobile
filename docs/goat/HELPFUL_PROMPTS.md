# 🧠 Helpful Prompts for Ultimate GitHub Copilot Workspace

> **Ready-to-use prompts specifically designed for this G.O.A.T Copilot setup**

This collection of prompts is crafted to work seamlessly with the Ultimate GitHub Copilot workspace template. Each prompt leverages the comprehensive AI instructions, VS Code settings, and project structure to maximize development productivity.

## 🚀 Getting Started Prompts

### Initial Setup & Orientation

```text
🎯 **Project Setup Assistant**
I'm using the Ultimate GitHub Copilot workspace template. Help me customize this setup for my [LANGUAGE] project.

Current project details:
- Primary language: [Go/Python/JavaScript/Java/C#/.NET 8+/Rust/etc.]
- Project type: [Web app/API/CLI tool/Library/etc.]
- Framework: [Express/FastAPI/Gin/Spring Boot/etc.]
- Database: [PostgreSQL/MongoDB/None/etc.]

Please review the .github/copilot-instructions.md file and suggest specific customizations for my project type.
```

```text
🔍 **Workspace Analysis**
Analyze this Ultimate Copilot workspace setup. What are the key features I should know about? How can I best leverage:
1. The AI instruction files in .github/
2. The VS Code tasks in .vscode/tasks.json
3. The MCP server configuration
4. The automation scripts

Provide a 5-minute quick-start guide for maximum productivity.
```

## 🛠️ Language-Specific Customization Prompts

### Go Projects

```text
🐹 **Go Project Optimization**
I'm working on a Go project using this Ultimate Copilot workspace. Help me:

1. Customize .github/copilot-instructions.md for Go best practices
2. Set up Go-specific tasks in VS Code
3. Configure proper Go module structure
4. Add Go testing patterns to the AI instructions
5. Set up golangci-lint configuration

My Go project is: [web API/CLI tool/microservice/library]
Using: [Gin/Echo/standard library] for web framework
Database: [PostgreSQL with GORM/MongoDB/etc.]
```

### Python Projects

```text
🐍 **Python Project Setup**
Help me optimize this Ultimate Copilot workspace for my Python project:

Project details:
- Type: [FastAPI web app/Django project/CLI tool/ML project]
- Python version: [3.9/3.10/3.11/3.12]
- Framework: [FastAPI/Django/Flask/None]
- Package manager: [pip/poetry/pipenv]
- Testing: [pytest/unittest]

Please:
1. Update the AI instructions for Python best practices
2. Configure virtual environment handling
3. Set up Python-specific VS Code tasks
4. Add type hinting and linting configurations
5. Create Python project structure recommendations
```

### JavaScript/TypeScript Projects

```text
⚡ **JavaScript/TypeScript Optimization**
I'm building a [React app/Node.js API/Next.js project/Vue app] using this Copilot workspace. Help me:

1. Customize copilot-instructions.md for modern JavaScript/TypeScript
2. Set up proper TypeScript configuration
3. Configure ESLint and Prettier settings
4. Add React/Node.js specific patterns to AI instructions
5. Set up testing with Jest/Vitest

Project stack:
- Frontend: [React/Vue/Angular/Vanilla]
- Backend: [Express/Fastify/Next.js API routes]
- Database: [PostgreSQL/MongoDB/Firebase]
- Deployment: [Vercel/Netlify/AWS/Docker]
```

### Java Projects

```text
### Java Projects

```text
☕ **Java Project Configuration**
Help me adapt this Ultimate Copilot workspace for my Java project:

- Build tool: [Maven/Gradle]
- Framework: [Spring Boot/Quarkus/Plain Java]
- Java version: [11/17/21]
- Testing: [JUnit 5/TestNG]
- Database: [PostgreSQL/MySQL/H2]

Please:
1. Update AI instructions for Java best practices
2. Configure Maven/Gradle specific tasks
3. Add Spring Boot patterns if applicable
4. Set up Java testing strategies
5. Configure proper Java project structure
```

### .NET 8+ Projects

```text
🔷 **.NET 8+ Project Optimization**
I'm building a modern .NET 8+ project using this Ultimate Copilot workspace. Help me:

Project details:
- Project type: [Web API/Blazor app/Console app/Class library]
- .NET version: [.NET 8/.NET 9/.NET 10]
- Framework: [Minimal APIs/MVC/Blazor Server/MAUI]
- Database: [SQL Server/PostgreSQL/MongoDB with EF Core]
- Authentication: [JWT/Identity/Azure AD]
- Testing: [xUnit/NUnit/MSTest]

Please:
1. Customize .github/copilot-instructions.md for modern .NET patterns
2. Set up comprehensive .NET VS Code tasks
3. Configure Entity Framework Core with migrations
4. Add C# 12+ language features and patterns
5. Set up modern async/await and Result patterns
6. Configure FluentValidation and dependency injection
7. Add comprehensive testing strategies (unit, integration, performance)
8. Set up CI/CD pipeline for .NET deployment

Special requirements:
- Use record types and nullable reference types
- Implement Result pattern instead of exceptions for control flow
- Configure structured logging with Serilog or built-in providers
- Set up health checks and monitoring
- Add security scanning for NuGet packages
```

```text
🔧 **.NET API Development**
Help me set up this workspace for a production-ready .NET 8+ Web API:

API specifications:
- API style: [REST/GraphQL/gRPC]
- Authentication: [JWT Bearer/OAuth2/Azure AD]
- Database: [SQL Server/PostgreSQL with EF Core]
- Caching: [Redis/In-memory]
- Documentation: [Swagger/OpenAPI with examples]

Please:
1. Configure minimal APIs with proper dependency injection
2. Set up comprehensive request/response validation
3. Add proper error handling with Result patterns
4. Configure Entity Framework with database migrations
5. Set up authentication and authorization
6. Add comprehensive API testing (unit, integration, contract)
7. Configure API versioning and documentation
8. Set up performance monitoring and health checks
```

### Rust Projects

````
```

### Rust Projects

```text
🦀 **Rust Project Configuration**
Help me optimize this Ultimate Copilot workspace for my Rust project:

- Project type: [CLI tool/Web API/System tool/Library/WebAssembly]
- Framework: [Actix-web/Axum/Warp/Rocket/Tauri for desktop]
- Database: [PostgreSQL with sqlx/Diesel/SQLite/None]
- Async runtime: [tokio/async-std]
- Testing: [Built-in tests/proptest/criterion for benchmarks]

Please:
1. Update AI instructions for Rust best practices and ownership patterns
2. Configure Cargo-specific tasks and clippy linting
3. Add async/await and error handling patterns
4. Set up Rust testing strategies with cargo test
5. Configure proper Rust project structure and workspace management
6. Add memory safety and performance optimization patterns
```

## 🏗️ Project Type Customization

### New Project Creation

```text
🆕 **New Project Initialization**
I'm starting a completely new [PROJECT_TYPE] project. Using this Ultimate Copilot workspace, help me:

Project vision:
- What: [Brief description of what you're building]
- Target users: [Who will use this]
- Key features: [3-5 main features]
- Tech preferences: [Any specific technologies you want to use]

Please:
1. Suggest optimal project structure
2. Recommend technology stack
3. Create initial AI instruction customizations
4. Set up development workflow
5. Generate starter code following the workspace patterns
6. Configure VS Code tasks for this project type
```

### Existing Project Migration

```text
🔄 **Existing Project Migration**
I have an existing [LANGUAGE] project that I want to migrate to this Ultimate Copilot workspace setup.

Current project:
- Language/Framework: [Current tech stack]
- Project size: [Small/Medium/Large - rough line count]
- Current issues: [Performance/Testing/Documentation/etc.]
- Team size: [Solo/Small team/Large team]

Help me:
1. Analyze my current project structure
2. Plan the migration to this workspace template
3. Preserve existing code while adopting new patterns
4. Update AI instructions to understand my existing codebase
5. Set up gradual modernization plan
6. Configure VS Code settings for my project
```

### Team Adoption

```text
👥 **Team Workspace Setup**
Help me adapt this Ultimate Copilot workspace for my development team:

Team details:
- Team size: [Number of developers]
- Experience levels: [Junior/Mid/Senior mix]
- Primary languages: [List of languages used]
- Current workflow: [Agile/Scrum/Kanban/etc.]
- Git strategy: [Git flow/GitHub flow/etc.]

Please:
1. Customize team-standards/code-review-checklist.md
2. Set up shared VS Code settings
3. Configure team-wide AI instruction standards
4. Create onboarding guide for new team members
5. Set up CI/CD pipeline customizations
6. Establish code review automation
```

## 🔧 Feature-Specific Prompts

### API Development

```text
🌐 **API Development Setup**
I'm building a REST API using this workspace. Help me:

API specifications:
- Type: [REST/GraphQL/gRPC]
- Authentication: [JWT/OAuth/API Keys]
- Database: [PostgreSQL/MongoDB/etc.]
- Documentation: [OpenAPI/Swagger preferred]

Please:
1. Add API-specific patterns to AI instructions
2. Set up API testing strategies
3. Configure request/response validation
4. Add security best practices for APIs
5. Set up API documentation generation
6. Create development and production configurations
```

### Testing & Quality Assurance

```text
🧪 **Testing Strategy Enhancement**
Help me enhance the testing capabilities of this workspace for my [LANGUAGE] project:

Current testing needs:
- Unit testing: [Current framework or needs setup]
- Integration testing: [Database/API testing needs]
- E2E testing: [UI testing requirements]
- Performance testing: [Load testing needs]

Please:
1. Enhance testing.instructions.md for my use case
2. Set up comprehensive testing tasks in VS Code
3. Configure test coverage reporting
4. Add testing automation to CI/CD
5. Create testing templates and patterns
6. Set up test data management strategies
```

### Security Hardening

```text
🔒 **Security Enhancement**
I need to enhance the security aspects of this workspace for my [INDUSTRY] project:

Security requirements:
- Compliance needs: [GDPR/HIPAA/SOX/PCI-DSS/etc.]
- Threat model: [Web app/API/Enterprise/etc.]
- Sensitive data: [PII/Financial/Health/etc.]

Please:
1. Review and enhance security-instructions.md
2. Add industry-specific security patterns
3. Set up security scanning automation
4. Configure secure coding practices
5. Add security testing strategies
6. Create security review checklists
```

### Performance Optimization

```text
⚡ **Performance Optimization Setup**
Help me optimize this workspace for high-performance [LANGUAGE] applications:

Performance requirements:
- Expected load: [Requests per second/Users/Data volume]
- Latency requirements: [Response time goals]
- Scalability needs: [Horizontal/Vertical scaling]
- Resource constraints: [Memory/CPU limitations]

Please:
1. Add performance patterns to AI instructions
2. Set up performance testing tasks
3. Configure monitoring and profiling
4. Add performance optimization guidelines
5. Set up benchmarking automation
6. Create performance review processes
```

## 🎨 Advanced Customization Prompts

### Documentation & Maintenance

```text
📚 **Documentation System Setup**
Help me create a comprehensive documentation system using this workspace:

Documentation needs:
- API documentation: [Yes/No]
- User guides: [Technical/Non-technical users]
- Developer documentation: [Architecture/Setup/Contributing]
- Auto-generation: [From code comments/OpenAPI/etc.]

Please:
1. Set up documentation generation tasks
2. Configure automated documentation updates
3. Create documentation templates
4. Set up documentation review processes
5. Integrate documentation with AI instructions
6. Create documentation maintenance workflows
```

### CI/CD Pipeline Customization

```text
🚀 **CI/CD Pipeline Enhancement**
Help me customize the CI/CD pipeline in this workspace for my deployment needs:

Deployment details:
- Platform: [AWS/Azure/GCP/Heroku/Self-hosted]
- Deployment strategy: [Blue-green/Rolling/Canary]
- Environment stages: [Dev/Staging/Prod/etc.]
- Approval processes: [Manual/Automated]

Please:
1. Customize .github/workflows/copilot-optimization.yml
2. Add deployment-specific tasks
3. Set up environment-specific configurations
4. Configure deployment automation
5. Add rollback strategies
6. Set up deployment monitoring
```

### Monitoring & Observability

```text
📊 **Observability Setup**
Help me add comprehensive monitoring and observability to this workspace:

Monitoring needs:
- Application metrics: [Performance/Business metrics]
- Error tracking: [Error rates/Types]
- Logging: [Structured/Centralized logging]
- Alerting: [Critical/Warning thresholds]

Please:
1. Add observability patterns to AI instructions
2. Set up monitoring instrumentation
3. Configure logging best practices
4. Set up alerting strategies
5. Add performance monitoring tasks
6. Create observability dashboards
```

## 🔍 Troubleshooting & Support Prompts

### Workspace Issues

```text
🔧 **Workspace Troubleshooting**
I'm having issues with this Ultimate Copilot workspace setup:

Issue description:
- Problem: [Describe the specific issue]
- When it occurs: [During setup/Development/Specific tasks]
- Error messages: [Any error messages you see]
- Environment: [OS/VS Code version/Extensions]

Please help me:
1. Diagnose the root cause
2. Provide step-by-step solutions
3. Prevent similar issues in the future
4. Optimize the workspace configuration
5. Update relevant documentation
```

### Performance Issues

```text
⚡ **Performance Troubleshooting**
This workspace setup is running slowly. Help me optimize:

Performance symptoms:
- VS Code responsiveness: [Slow/Laggy/Freezing]
- Copilot suggestions: [Slow/Not appearing/Incorrect]
- Task execution: [Build/Test tasks slow]
- File operations: [Search/Navigation slow]

Please:
1. Analyze current settings for performance bottlenecks
2. Suggest optimizations for large codebases
3. Configure file exclusions appropriately
4. Optimize extension settings
5. Improve system resource usage
```

## 💡 Pro Tips for Prompt Usage

### Making Prompts More Effective

1. **Be Specific**: Replace [PLACEHOLDERS] with your actual details
2. **Context Matters**: Always mention you're using the Ultimate Copilot workspace
3. **Iterate**: Start with basic setup, then use follow-up prompts for refinement
4. **Reference Files**: Ask Copilot to review specific files in the workspace
5. **Test Changes**: Use the workspace tasks to validate changes

### Prompt Templates

```text
**Custom Prompt Template**
I'm using the Ultimate GitHub Copilot workspace template for my [PROJECT_TYPE] project.

Current situation:
- [Describe current state]
- [What's working well]
- [What needs improvement]

Goals:
- [Primary objective]
- [Secondary objectives]
- [Success criteria]

Please help me:
1. [Specific action 1]
2. [Specific action 2]
3. [Specific action 3]

Consider the existing:
- AI instructions in .github/
- VS Code configuration in .vscode/
- Project structure and standards
```

---

## 🎯 Quick Reference

**For New Projects**: Use "New Project Initialization" → Language-specific setup → Feature-specific prompts

**For Existing Projects**: Use "Existing Project Migration" → Language optimization → Team adoption

**For Team Setup**: Use "Team Workspace Setup" → Customize standards → Configure CI/CD

**For Issues**: Use "Workspace Troubleshooting" → Performance optimization → Specific feature help

---

**💡 Remember**: These prompts work best when you provide specific details about your project. The more context you give, the better Copilot can customize the workspace for your needs!
