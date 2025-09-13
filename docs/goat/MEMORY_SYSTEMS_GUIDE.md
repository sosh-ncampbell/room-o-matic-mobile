# 🧠 Memory Systems Guide

This template includes **two distinct memory systems** that serve different purposes:

## 📋 Overview

| System | Purpose | File Location | Usage |
|--------|---------|---------------|--------|
| **Template Memory** | Project context, AI preferences, template configuration | `.vscode/memory.json` | Template customization and project context |
| **MCP Memory** | Cross-session knowledge graph, persistent AI memory | `.vscode/mcp-memory.json` | AI remembers information across chat sessions |

---

## 🎯 Template Memory System (`memory.json`)

**Purpose**: Provides context and preferences for AI assistance within your project template.

### Structure Overview

```json
{
  "projectMemory": {
    // Core project information
  },
  "contextPreferences": {
    // AI assistance preferences
  },
  "teamCollaboration": {
    // Team workflow settings
  },
  "developmentWorkflow": {
    // Development process configuration
  },
  "aiOptimizations": {
    // Copilot-specific settings
  },
  "learningResources": {
    // Documentation and learning paths
  }
}
```

### 🛠️ Customization Instructions

#### 1. Project Information (`projectMemory`)

**Customize for your project:**

```json
"projectMemory": {
  "name": "Your Project Name",
  "description": "Brief description of your project",
  "version": "1.0.0",
  "type": "web-app | api | library | cli-tool | mobile-app",
  "primaryLanguages": ["Go", "TypeScript", "Python"],
  "architecturePatterns": ["Clean Architecture", "Microservices"],
  "keyFeatures": ["Your key features"],
  "domainApplications": ["Your industry/domain"]
}
```

**Examples by Project Type:**

```json
// E-commerce Platform
"projectMemory": {
  "name": "ShopFlow Commerce Platform",
  "type": "web-app",
  "primaryLanguages": ["TypeScript", "Go", "Python"],
  "domainApplications": ["E-commerce", "Retail"]
}

// Financial API
"projectMemory": {
  "name": "FinanceAPI Core",
  "type": "api",
  "primaryLanguages": ["Go", "Python"],
  "domainApplications": ["Finance", "Banking", "Payments"]
}

// Healthcare Management System
"projectMemory": {
  "name": "MedFlow Patient System",
  "type": "web-app",
  "primaryLanguages": ["C#", ".NET", "TypeScript"],
  "domainApplications": ["Healthcare", "Medical Records"]
}
```

#### 2. Context Preferences (`contextPreferences`)

**Customize AI assistance behavior:**

```json
"contextPreferences": {
  "codeStyle": "functional | object-oriented | clean-architecture | minimal",
  "testingApproach": "tdd | bdd | integration-heavy | unit-focused",
  "securityFocus": "high | medium | enterprise | startup",
  "performanceGoals": "scalability | speed | memory-efficient | real-time",
  "documentationLevel": "minimal | comprehensive | api-focused | tutorial-heavy",
  "aiAssistanceLevel": "basic | moderate | maximum | domain-expert"
}
```

**Industry-Specific Examples:**

```json
// Startup/MVP Focus
"contextPreferences": {
  "codeStyle": "Rapid development with clean, maintainable patterns",
  "testingApproach": "Essential test coverage with focus on core features",
  "securityFocus": "Security basics with growth-ready patterns",
  "performanceGoals": "Optimized for quick iteration and user feedback"
}

// Enterprise/Banking
"contextPreferences": {
  "codeStyle": "Enterprise patterns with extensive validation and error handling",
  "testingApproach": "Comprehensive test coverage including security and compliance testing",
  "securityFocus": "Maximum security with audit trails and compliance requirements",
  "performanceGoals": "High availability and fault tolerance"
}

// Open Source Library
"contextPreferences": {
  "codeStyle": "Clean, documented code following language idioms",
  "testingApproach": "Extensive testing with examples and edge cases",
  "documentationLevel": "Comprehensive with examples and API documentation",
  "performanceGoals": "Balanced performance with broad compatibility"
}
```

#### 3. Team Collaboration (`teamCollaboration`)

**Adapt to your team size and process:**

```json
// Small Team (2-5 developers)
"teamCollaboration": {
  "codeReviewProcess": "Peer review with focus on knowledge sharing",
  "branchingStrategy": "Feature branches with fast integration",
  "commitStandards": "Clear commit messages with context",
  "qualityGates": "Essential checks: tests, linting, basic security"
}

// Large Team (10+ developers)
"teamCollaboration": {
  "codeReviewProcess": "Structured review with multiple reviewers and domain experts",
  "branchingStrategy": "GitFlow with release branches and hotfix process",
  "commitStandards": "Conventional Commits with detailed descriptions and issue linking",
  "qualityGates": "Comprehensive: tests, security, performance, documentation validation"
}

// Remote/Distributed Team
"teamCollaboration": {
  "codeReviewProcess": "Asynchronous review with detailed comments and documentation",
  "branchingStrategy": "Feature branches with clear merge criteria",
  "knowledgeSharing": "Documentation-heavy with video recordings and decision logs"
}
```

#### 4. Development Workflow (`developmentWorkflow`)

**Match your deployment and release process:**

```json
// Continuous Deployment
"developmentWorkflow": {
  "preCommitChecks": ["formatting", "linting", "unit-tests", "security-scan"],
  "cicdPipeline": ["build", "test", "security-scan", "deploy-staging", "smoke-tests", "deploy-prod"],
  "releaseProcess": ["automated-versioning", "changelog-generation", "automated-deployment"]
}

// Traditional Release Cycles
"developmentWorkflow": {
  "preCommitChecks": ["formatting", "linting", "unit-tests"],
  "cicdPipeline": ["build", "comprehensive-tests", "integration-tests", "security-audit", "performance-tests"],
  "releaseProcess": ["manual-versioning", "release-notes", "staged-rollout", "post-release-monitoring"]
}
```

#### 5. AI Optimizations (`aiOptimizations`)

**Configure Copilot behavior for your domain:**

```json
// Backend API Focus
"aiOptimizations": {
  "copilotInstructions": "Focus on API design, database optimization, and service architecture",
  "contextualSuggestions": "Emphasize error handling, validation, and security patterns",
  "codeGeneration": "Generate REST endpoints, database models, and service layers",
  "testGeneration": "API testing, integration tests, and performance benchmarks"
}

// Frontend Application Focus
"aiOptimizations": {
  "copilotInstructions": "Focus on component design, state management, and user experience",
  "contextualSuggestions": "Emphasize accessibility, performance, and responsive design",
  "codeGeneration": "Generate components, hooks, and styling patterns",
  "testGeneration": "Component testing, user interaction tests, and visual regression tests"
}

// Data Science/ML Focus
"aiOptimizations": {
  "copilotInstructions": "Focus on data processing, model training, and pipeline optimization",
  "contextualSuggestions": "Emphasize data validation, model evaluation, and reproducibility",
  "codeGeneration": "Generate data pipelines, model training code, and evaluation metrics",
  "testGeneration": "Data validation tests, model performance tests, and pipeline integration tests"
}
```

### 📝 Quick Customization Checklist

- [ ] Update `projectMemory.name` with your project name
- [ ] Set `projectMemory.type` to match your project type
- [ ] List your `primaryLanguages` in order of importance
- [ ] Choose `architecturePatterns` that fit your design
- [ ] Update `domainApplications` for your industry
- [ ] Adjust `contextPreferences` for your team's style
- [ ] Configure `teamCollaboration` for your workflow
- [ ] Set `developmentWorkflow` to match your process
- [ ] Customize `aiOptimizations` for your domain focus

---

## 🔗 MCP Memory System (`mcp-memory.json`)

**Purpose**: Persistent knowledge graph that remembers information across chat sessions.

### How It Works

The MCP memory server automatically:
- **Remembers** people, projects, preferences from conversations
- **Connects** related information through relationships
- **Persists** knowledge across VS Code sessions
- **Searches** stored information for context

### Structure

MCP memory uses a knowledge graph format:

```json
{
  "entities": [
    {
      "name": "John_Smith",
      "entityType": "person",
      "observations": ["Prefers TypeScript over JavaScript", "Works on frontend team"]
    }
  ],
  "relations": [
    {
      "from": "John_Smith",
      "to": "Frontend_Team",
      "relationType": "works_on"
    }
  ]
}
```

### Usage Examples

The MCP memory system will automatically learn and remember:

- **Team Members**: Names, roles, preferences, working patterns
- **Project Details**: Architecture decisions, technology choices, constraints
- **Coding Patterns**: Preferred styles, naming conventions, architectural patterns
- **Business Context**: Domain knowledge, requirements, user feedback

### Configuration

The MCP server is configured in `.vscode/mcp.json`:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": "/Users/nickcampbell/Projects/copilot-goat/.vscode/mcp-memory.json"
      }
    }
  }
}
```

---

## 🚀 Getting Started

### 1. Customize Template Memory

1. Open `.vscode/memory.json`
2. Follow the customization instructions above
3. Save the file
4. The AI will use this context in all interactions

### 2. Enable MCP Memory

1. The MCP server is already configured in `.vscode/mcp.json`
2. VS Code will automatically start the memory server
3. Begin chatting - the AI will start building knowledge over time

### 3. Verify Setup

Test both systems:

```
// Test Template Memory
"What type of project am I working on?"
// Should reference your customized project type

// Test MCP Memory
"Remember that I prefer using clean architecture patterns"
// Will be stored in the knowledge graph for future sessions
```

---

## 🔧 Troubleshooting

### Template Memory Issues

- **AI not using context**: Verify `.vscode/memory.json` is valid JSON
- **Outdated information**: Update the relevant section in `memory.json`
- **Wrong suggestions**: Adjust `contextPreferences` and `aiOptimizations`

### MCP Memory Issues

- **Memory not persisting**: Check VS Code MCP extension is installed and enabled
- **Server not starting**: Verify NPX is available: `npx -y @modelcontextprotocol/server-memory --help`
- **Path issues**: The MCP server may create its memory file in the default location rather than custom path
- **Storage issues**: Check that the VS Code workspace has write permissions
- **Testing setup**: Use the MCP memory tools to create initial entities and verify functionality

### MCP Memory Server Testing

To verify your MCP memory setup is working:

1. **Check server status**: Look for MCP memory server in VS Code's MCP extension status
2. **Test creation**: Try creating a simple entity to test the connection
3. **Verify storage**: Check if memory data persists between sessions
4. **Path verification**: The server may store data in its default location initially

---

## 📚 Advanced Usage

### Template Memory for Multiple Projects

Create project-specific templates:

```bash
# Copy base template
cp .vscode/memory.json .vscode/memory-api.json
cp .vscode/memory.json .vscode/memory-frontend.json

# Customize each for different project types
# Reference them in your project documentation
```

### MCP Memory Management

Use MCP tools to manage stored knowledge:
- Search stored information: Use search functionality
- Clean up outdated info: Remove old entities/relations
- Export knowledge: Backup your knowledge graph

### Integration with CI/CD

Add memory validation to your pipeline:

```yaml
- name: Validate Template Memory
  run: |
    jq empty .vscode/memory.json # Validate JSON syntax
    # Add custom validation scripts
```

---

**Both memory systems work together to provide the most context-aware AI assistance possible!**
