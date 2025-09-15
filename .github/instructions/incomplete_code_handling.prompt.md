---
mode: agent
---

# Incomplete Code Handling Guidelines

## Core Principles

**Production-First Philosophy**: All code should be production-ready. When partial implementations are necessary, mark them clearly with structured TODO syntax.

## TODO Patterns

### Basic TODO Format
```go
// TODO: [CATEGORY] Brief description - specific action needed
func ProcessPayment(amount float64) error {
    // TODO: Implement payment processing with retry logic
    return fmt.Errorf("payment processing not implemented")
}
```

### Stub Best Practices
- Mark incomplete sections clearly with TODO comments
- Return descriptive errors, never silent failures
- Provide implementation hints in comments
- Test stub behavior to ensure proper error handling

## TODO Categories & Examples

```go
// TODO: [FULL_IMPLEMENTATION] Add advanced image compression with 70% size reduction
func (s *ImageService) CompressImage(data []byte) ([]byte, error) {
    // TODO: Replace basic PNG with adaptive multi-format compression
    return basicPNGCompress(data), nil
}

// TODO: [SECURITY] Add comprehensive audit logging for GDPR/HIPAA compliance
func (r *Repository) GetSensitiveData(ctx context.Context, id uuid.UUID) (*Data, error) {
    // TODO: Log access attempts with user context and IP
    return r.db.GetByID(ctx, id)
}

// TODO: [ERROR_HANDLING] Implement retry logic with exponential backoff
func (c *APIClient) SendData(ctx context.Context, data []byte) error {
    // TODO: Add circuit breaker and timeout handling
    return c.httpClient.Post(c.endpoint, data)
}
```

## TODO Categories

- **[FULL_IMPLEMENTATION]**: Missing core business logic or enterprise features
- **[SECURITY]**: Authentication, encryption, audit logging, compliance gaps
- **[ERROR_HANDLING]**: Exception handling, retry logic, graceful degradation
- **[ENHANCEMENT]**: Performance optimization, UX improvements
- **[TESTING]**: Missing unit, integration, or security test coverage

## Format Standard
```go
// TODO: [CATEGORY] Brief description with specific action needed
func Method() error {
    // TODO: Inline comment for specific improvement
    return errors.New("not implemented")
}
```

## Production Readiness
- All [SECURITY] TODOs must be resolved before production
- Critical [ERROR_HANDLING] TODOs implemented
- Core [FULL_IMPLEMENTATION] TODOs completed
- Test stubs must return descriptive errors, never silent failures
