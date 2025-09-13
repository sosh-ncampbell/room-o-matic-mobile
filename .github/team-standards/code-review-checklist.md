# 📋 Code Review Checklist for AI-Assisted Development

## Pre-Review Checklist (Author)

### Before Submitting for Review

- [ ] **Self-Review Completed**: Reviewed your own changes thoroughly
- [ ] **AI-Generated Code Validated**: Verified all AI-generated code follows project patterns
- [ ] **Tests Pass**: All automated tests pass locally
- [ ] **Documentation Updated**: Updated relevant documentation (README, API docs, etc.)
- [ ] **Security Considerations**: Reviewed code for security implications
- [ ] **Performance Impact**: Considered performance implications of changes

### Branch and Commit Standards

- [ ] **Branch Naming**: Follows convention (feature/fix/docs/refactor + description)
- [ ] **Commit Messages**: Follow conventional commit format
- [ ] **Commit Size**: Commits are focused and atomic
- [ ] **No Sensitive Data**: No secrets, keys, or sensitive information in commits

## Code Quality Review

### Architecture and Design

- [ ] **Architecture Compliance**: Code follows established architecture patterns
- [ ] **Design Patterns**: Uses appropriate design patterns consistently
- [ ] **Separation of Concerns**: Clear separation between layers/modules
- [ ] **SOLID Principles**: Code adheres to SOLID principles
- [ ] **Domain Logic**: Business logic is properly encapsulated in domain layer

### Code Structure and Organization

- [ ] **File Organization**: Files are organized according to project structure
- [ ] **Naming Conventions**: Variables, functions, classes use consistent naming
- [ ] **Code Duplication**: No unnecessary code duplication (DRY principle applied wisely)
- [ ] **Function Size**: Functions/methods are appropriately sized and focused
- [ ] **Class Responsibilities**: Classes have clear, single responsibilities

### Error Handling and Resilience

- [ ] **Error Handling**: Comprehensive error handling with proper error types
- [ ] **Error Context**: Errors include sufficient context for debugging
- [ ] **Graceful Degradation**: System handles failures gracefully
- [ ] **Resource Cleanup**: Proper cleanup of resources (connections, files, etc.)
- [ ] **Timeout Handling**: Appropriate timeouts for external calls

## Security Review

### Input Validation and Data Security

- [ ] **Input Validation**: All external inputs are validated and sanitized
- [ ] **SQL Injection Prevention**: Uses parameterized queries/prepared statements
- [ ] **XSS Prevention**: User inputs are properly escaped/sanitized
- [ ] **CSRF Protection**: CSRF tokens implemented where applicable
- [ ] **Data Encryption**: Sensitive data is encrypted appropriately

### Authentication and Authorization

- [ ] **Authentication Required**: Protected endpoints require authentication
- [ ] **Authorization Checks**: Proper authorization checks for resource access
- [ ] **Privilege Escalation**: No opportunities for privilege escalation
- [ ] **Session Management**: Secure session handling and token management
- [ ] **Rate Limiting**: Appropriate rate limiting on public endpoints

### Security Best Practices

- [ ] **Secrets Management**: No hardcoded secrets or credentials
- [ ] **Security Headers**: Appropriate security headers are set
- [ ] **TLS/HTTPS**: All external communications use secure protocols
- [ ] **Audit Logging**: Security-relevant actions are logged
- [ ] **Error Information**: Error messages don't leak sensitive information

## Testing and Quality Assurance

### Test Coverage and Quality

- [ ] **Unit Tests**: Adequate unit test coverage for new code
- [ ] **Integration Tests**: Integration tests for component interactions
- [ ] **Edge Cases**: Tests cover edge cases and error conditions
- [ ] **Test Quality**: Tests are well-structured and maintainable
- [ ] **Mock Usage**: Appropriate use of mocks and test doubles

### Test Organization

- [ ] **Test Structure**: Tests follow Arrange-Act-Assert pattern
- [ ] **Test Naming**: Test names clearly describe what is being tested
- [ ] **Test Data**: Uses proper test data factories and fixtures
- [ ] **Test Independence**: Tests are independent and can run in any order
- [ ] **Performance Tests**: Performance tests where applicable

## Performance and Scalability

### Performance Considerations

- [ ] **Database Queries**: Efficient database queries with proper indexing
- [ ] **N+1 Problems**: No N+1 query problems in ORM usage
- [ ] **Caching Strategy**: Appropriate caching where beneficial
- [ ] **Memory Usage**: Efficient memory usage and garbage collection
- [ ] **Algorithm Efficiency**: Algorithms have appropriate time/space complexity

### Scalability and Monitoring

- [ ] **Connection Pooling**: Database connections properly pooled
- [ ] **Resource Limits**: Appropriate resource limits and timeouts
- [ ] **Monitoring**: Key metrics and logs are captured
- [ ] **Load Handling**: Code can handle expected load patterns
- [ ] **Async Operations**: Blocking operations are handled asynchronously

## Documentation and Maintainability

### Code Documentation

- [ ] **Self-Documenting**: Code is readable and self-explanatory
- [ ] **Comments**: Strategic comments explain why, not what
- [ ] **API Documentation**: Public APIs are documented
- [ ] **Complex Logic**: Complex algorithms/business logic are explained
- [ ] **TODOs**: Any TODOs are tracked and have owner/timeline

### External Documentation

- [ ] **README Updates**: README updated with new features/changes
- [ ] **API Changes**: API documentation reflects changes
- [ ] **Migration Guides**: Breaking changes have migration documentation
- [ ] **Architecture Docs**: Architecture documentation updated if needed
- [ ] **Changelog**: Changes documented in changelog/release notes

## Language/Framework-Specific Checks

### [CUSTOMIZE] Language-Specific Standards

#### For Go Projects

- [ ] **Error Handling**: Uses Go's explicit error handling patterns
- [ ] **Context Usage**: Proper context.Context usage for cancellation
- [ ] **Goroutine Management**: Proper goroutine lifecycle management
- [ ] **Channel Usage**: Appropriate channel usage and closing
- [ ] **Interface Design**: Interfaces are small and focused

#### For JavaScript/TypeScript Projects

- [ ] **Type Safety**: TypeScript types are properly defined and used
- [ ] **Promise Handling**: Proper async/await and promise handling
- [ ] **Memory Leaks**: No memory leaks from event listeners/closures
- [ ] **Bundle Size**: Consider impact on bundle size
- [ ] **Browser Compatibility**: Code works in target browsers

#### For Python Projects

- [ ] **Type Hints**: Proper type hints where applicable
- [ ] **Exception Handling**: Python-specific exception handling patterns
- [ ] **Context Managers**: Proper use of context managers for resources
- [ ] **PEP 8 Compliance**: Code follows PEP 8 style guidelines
- [ ] **Virtual Environment**: Dependencies properly managed

#### For Java Projects

- [ ] **Exception Hierarchy**: Proper exception handling and hierarchy
- [ ] **Resource Management**: try-with-resources for resource management
- [ ] **Thread Safety**: Thread safety considerations addressed
- [ ] **Collection Usage**: Appropriate collection types and operations
- [ ] **Memory Management**: Consideration of garbage collection impact

#### For C# Projects

- [ ] **Exception Handling**: Proper exception handling patterns
- [ ] **Async/Await**: Correct async/await usage and ConfigureAwait
- [ ] **Disposal Pattern**: IDisposable implemented where needed
- [ ] **LINQ Usage**: Efficient LINQ usage without performance penalties
- [ ] **Nullable References**: Proper nullable reference type usage

## AI-Specific Review Considerations

### AI-Generated Code Quality

- [ ] **Pattern Consistency**: AI-generated code follows project patterns
- [ ] **Context Awareness**: Code demonstrates understanding of project context
- [ ] **Security Awareness**: AI-generated security code is properly implemented
- [ ] **Performance Optimization**: Generated code follows performance best practices
- [ ] **Error Handling**: AI-generated error handling is comprehensive

### Human Oversight

- [ ] **Business Logic Validation**: Business logic is correct and complete
- [ ] **Integration Verification**: Code integrates properly with existing systems
- [ ] **Edge Case Coverage**: Human review of edge cases and error scenarios
- [ ] **Architectural Alignment**: Code aligns with overall system architecture
- [ ] **Requirement Fulfillment**: Code fully addresses the requirements

## Review Process

### Initial Review

1. **Quick Scan**: Overall structure and approach
2. **Security Pass**: Focus on security implications
3. **Logic Verification**: Business logic correctness
4. **Pattern Compliance**: Adherence to established patterns

### Detailed Review

1. **Line-by-Line**: Careful examination of implementation details
2. **Test Review**: Examination of test coverage and quality
3. **Documentation**: Review of code comments and external docs
4. **Performance**: Analysis of performance implications

### Review Comments

- **Constructive**: Focus on improvement, not criticism
- **Specific**: Point to exact lines and provide concrete suggestions
- **Educational**: Explain reasoning behind suggestions
- **Actionable**: Provide clear steps for resolution
- **Prioritized**: Indicate severity (blocker, important, suggestion)

## Approval Criteria

### Must-Have (Blockers)

- [ ] All security requirements met
- [ ] No critical bugs or logic errors
- [ ] Tests pass and provide adequate coverage
- [ ] Follows established architecture patterns
- [ ] No sensitive data exposure

### Should-Have (Important)

- [ ] Performance meets requirements
- [ ] Error handling is comprehensive
- [ ] Code is maintainable and readable
- [ ] Documentation is updated
- [ ] Follows coding standards

### Nice-to-Have (Suggestions)

- [ ] Additional optimizations
- [ ] Extra test scenarios
- [ ] Enhanced documentation
- [ ] Code style improvements
- [ ] Refactoring opportunities

---

## Quick Reference

### Common Issues to Watch For

- SQL injection vulnerabilities
- Missing error handling
- Resource leaks (connections, files, memory)
- Race conditions in concurrent code
- Performance bottlenecks (N+1 queries, inefficient algorithms)
- Security header misconfigurations
- Missing input validation
- Improper exception handling
- Memory leaks in long-running processes
- Missing authorization checks

### Reviewer Guidelines

- **Be Thorough**: Take time for proper review
- **Be Constructive**: Focus on helping improve the code
- **Be Educational**: Share knowledge and best practices
- **Be Timely**: Provide feedback promptly
- **Be Consistent**: Apply standards consistently across reviews

### Author Guidelines

- **Be Responsive**: Address feedback promptly and thoroughly
- **Be Open**: Accept feedback graciously and learn from it
- **Be Thorough**: Self-review before requesting review
- **Be Clear**: Provide context for complex changes
- **Be Collaborative**: Engage in discussion to find best solutions
