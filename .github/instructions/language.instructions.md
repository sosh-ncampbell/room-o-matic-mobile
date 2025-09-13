---
applyTo: "**/src/**/*.{js,ts,py,go,java,cs,rs,rb,php,kt,scala,swift,dart}"
description: "Universal language patterns, performance optimizations, and development best practices"
references:
  - language_docs: "{CUSTOMIZE: Official language documentation}"
  - framework_docs: "{CUSTOMIZE: Framework-specific documentation}"
  - style_guide: "{CUSTOMIZE: Team coding style guide}"
---

# Universal Development Patterns and Standards

## Language-Agnostic Core Principles

### SOLID Principles Application
```
S - Single Responsibility: Each class/function has one reason to change
O - Open/Closed: Open for extension, closed for modification
L - Liskov Substitution: Subtypes must be substitutable for base types
I - Interface Segregation: Many specific interfaces over one general interface
D - Dependency Inversion: Depend on abstractions, not concretions
```

### Code Quality Standards
```
- Clear, descriptive naming that explains intent
- Functions/methods should do one thing well
- Minimize cognitive complexity and nesting levels
- Use consistent formatting and style conventions
- Write self-documenting code with strategic comments
- Handle errors explicitly and gracefully
- Follow language-specific idioms and best practices
```

## 🚫 Anti-Patterns & Code to Avoid

### Common Bad Practices That Confuse AI Suggestions

**❌ Poor Error Handling**
```go
// DON'T: Silent failures that hide problems
result, _ := riskyOperation()
if result == nil {
    // AI can't understand what went wrong
    return
}

// DON'T: Generic error messages
return errors.New("something went wrong")

// ✅ DO: Explicit error handling with context
result, err := riskyOperation()
if err != nil {
    return fmt.Errorf("failed to perform risky operation for user %s: %w", userID, err)
}
```

**❌ Poor Naming Conventions**
```go
// DON'T: Cryptic names that provide no context
func calc(x, y int) int { return x + y }
var d time.Duration
func proc(data []byte) error { /* ... */ }

// ✅ DO: Descriptive names that explain intent
func calculateTotalPrice(basePrice, tax int) int { return basePrice + tax }
var requestTimeout time.Duration
func processUserRegistrationData(userData []byte) error { /* ... */ }
```

**❌ Performance Anti-Patterns**
```go
// DON'T: Memory leaks with goroutines
go func() {
    for {
        doWork()  // Runs forever, no cancellation
    }
}()

// DON'T: Creating resources without cleanup
db := createDBConnection()
// No defer db.Close()

// ✅ DO: Proper lifecycle management
ctx, cancel := context.WithCancel(context.Background())
defer cancel()

go func() {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            doWork()
        }
    }
}()
```

**❌ Security Anti-Patterns**
```javascript
// DON'T: SQL injection vulnerability
query = `SELECT * FROM users WHERE id = ${userId}`;

// DON'T: Exposing sensitive information
console.log("User data:", { password: user.password, token: user.authToken });

// ✅ DO: Parameterized queries and safe logging
query = `SELECT * FROM users WHERE id = ?`;
db.query(query, [userId]);

console.log("User data:", {
    id: user.id,
    email: user.email,
    // password and tokens excluded
});
```

### Language-Specific Anti-Patterns

**Go Anti-Patterns:**
- ❌ Ignoring errors: `result, _ := operation()`
- ❌ Using `panic()` for normal error handling
- ❌ Not using context for cancellation: `func longRunning() {}`
- ❌ Creating goroutines without proper cleanup
- ❌ Not using structured logging: `fmt.Println("error:", err)`
- ❌ Returning untyped errors: `return errors.New("failed")`

**Python Anti-Patterns:**
- ❌ Using mutable default arguments: `def func(items=[]):`
- ❌ Catching broad exceptions: `except Exception:`
- ❌ Not using type hints in modern Python: `def process(data):`
- ❌ Mixing tabs and spaces for indentation
- ❌ Not using context managers: `file = open("data.txt")`
- ❌ Using `print()` instead of proper logging

**JavaScript/TypeScript Anti-Patterns:**
- ❌ Using `var` instead of `const`/`let`
- ❌ Not handling Promise rejections: `fetch(url).then(...)`
- ❌ Mutating props in React: `props.user.name = newName`
- ❌ Using `any` type everywhere in TypeScript
- ❌ Not using async/await: `promise.then().then().then()`
- ❌ Creating memory leaks with event listeners

**Java Anti-Patterns:**
- ❌ Not closing resources: `FileInputStream fis = new FileInputStream(...)`
- ❌ Using raw types: `List items = new ArrayList()`
- ❌ String concatenation in loops: `str += item`
- ❌ Using `System.out.println()` instead of logging
- ❌ Not handling checked exceptions properly
- ❌ Creating unnecessary objects in loops

**C# / .NET 8+ Anti-Patterns:**
- ❌ Using old Startup.cs pattern in .NET 8+ applications
- ❌ Not using nullable reference types and required properties
- ❌ Using `ConfigureAwait(false)` in application code (only needed in libraries)
- ❌ Manual JSON serialization instead of source generators
- ❌ Exceptions as control flow instead of Result patterns
- ❌ Not leveraging record types for DTOs and value objects
- ❌ Using old controller patterns instead of minimal APIs
- ❌ Not using dependency injection scopes appropriately
- ❌ Ignoring cancellation tokens in async operations
- ❌ Not using `IAsyncEnumerable` for streaming data

**Rust Anti-Patterns:**
- ❌ Using `unwrap()` everywhere: `result.unwrap()`
- ❌ Not using `?` operator for error propagation
- ❌ Creating unnecessary clones: `data.clone().process()`
- ❌ Using `panic!()` for recoverable errors
- ❌ Not leveraging the type system for safety
- ❌ Ignoring compiler warnings

## Error Handling Patterns

### Language-Specific Error Handling

#### JavaScript/TypeScript
```javascript
// Use Result/Option patterns for explicit error handling
class Result<T, E> {
    constructor(private value?: T, private error?: E) {}

    static ok<T>(value: T): Result<T, never> {
        return new Result(value);
    }

    static err<E>(error: E): Result<never, E> {
        return new Result(undefined, error);
    }

    isOk(): boolean { return this.error === undefined; }
    isErr(): boolean { return this.error !== undefined; }
}

// Async error handling
async function processData(data: unknown): Promise<Result<ProcessedData, ProcessingError>> {
    try {
        const validated = await validateData(data);
        const processed = await processValidatedData(validated);
        return Result.ok(processed);
    } catch (error) {
        if (error instanceof ValidationError) {
            return Result.err(new ProcessingError('Validation failed', error));
        }
        return Result.err(new ProcessingError('Processing failed', error));
    }
}
```

#### Python

```python
# Use custom exceptions and proper error context
class DomainError(Exception):
    """Base exception for domain-specific errors."""
    def __init__(self, message: str, cause: Exception = None):
        super().__init__(message)
        self.cause = cause

class ValidationError(DomainError):
    """Raised when input validation fails."""
    def __init__(self, field: str, message: str, cause: Exception = None):
        super().__init__(f"Validation failed for {field}: {message}", cause)
        self.field = field

# Error handling with context
def process_user_data(data: dict) -> User:
    try:
        validated_data = validate_user_data(data)
        return create_user(validated_data)
    except ValidationError as e:
        logger.error(f"User data validation failed: {e}", exc_info=True)
        raise
    except Exception as e:
        logger.error(f"Unexpected error processing user data: {e}", exc_info=True)
        raise ProcessingError("Failed to process user data") from e
```

#### Go

```go
// Explicit error handling with context
type DomainError struct {
    Op      string
    Message string
    Err     error
}

func (e *DomainError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("%s: %s: %v", e.Op, e.Message, e.Err)
    }
    return fmt.Sprintf("%s: %s", e.Op, e.Message)
}

func (e *DomainError) Unwrap() error {
    return e.Err
}

// Service layer error handling
func (s *UserService) CreateUser(ctx context.Context, req CreateUserRequest) (*User, error) {
    const op = "UserService.CreateUser"

    if err := s.validator.Validate(req); err != nil {
        return nil, &DomainError{
            Op:      op,
            Message: "validation failed",
            Err:     err,
        }
    }

    user, err := s.repository.Create(ctx, req.ToEntity())
    if err != nil {
        return nil, &DomainError{
            Op:      op,
            Message: "failed to create user",
            Err:     err,
        }
    }

    return user, nil
}
```

#### Java

```java
// Custom exception hierarchy
public abstract class DomainException extends Exception {
    protected DomainException(String message) {
        super(message);
    }

    protected DomainException(String message, Throwable cause) {
        super(message, cause);
    }
}

public class ValidationException extends DomainException {
    private final String field;

    public ValidationException(String field, String message) {
        super(String.format("Validation failed for %s: %s", field, message));
        this.field = field;
    }

    public String getField() { return field; }
}

// Service layer with proper exception handling
public class UserService {
    public User createUser(CreateUserRequest request) throws DomainException {
        try {
            validator.validate(request);
            return repository.save(request.toEntity());
        } catch (ValidationException e) {
            logger.error("User validation failed: {}", e.getMessage(), e);
            throw e;
        } catch (Exception e) {
            logger.error("Unexpected error creating user: {}", e.getMessage(), e);
            throw new ProcessingException("Failed to create user", e);
        }
    }
}
```

#### C# / .NET 8+ Development

```csharp
// Modern .NET 8+ patterns with minimal APIs and dependency injection
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

// Domain-driven design with records and nullable reference types
public record CreateUserRequest(
    [Required] string Email,
    [Required] string Name,
    string? Phone = null
);

public record User(Guid Id, string Email, string Name, string? Phone, DateTime CreatedAt);

// Result pattern for error handling
public abstract record Result<T>
{
    public record Success(T Value) : Result<T>;
    public record Failure(string Error, Exception? Exception = null) : Result<T>;
}

// Service implementation with modern async patterns
public class UserService
{
    private readonly IUserRepository _repository;
    private readonly IValidator<CreateUserRequest> _validator;
    private readonly ILogger<UserService> _logger;

    public UserService(
        IUserRepository repository,
        IValidator<CreateUserRequest> validator,
        ILogger<UserService> logger)
    {
        _repository = repository;
        _validator = validator;
        _logger = logger;
    }

    public async Task<Result<User>> CreateUserAsync(
        CreateUserRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var validationResult = await _validator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = string.Join(", ", validationResult.Errors.Select(e => e.ErrorMessage));
                _logger.LogWarning("User validation failed: {Errors}", errors);
                return new Result<User>.Failure($"Validation failed: {errors}");
            }

            var user = new User(
                Id: Guid.NewGuid(),
                Email: request.Email,
                Name: request.Name,
                Phone: request.Phone,
                CreatedAt: DateTime.UtcNow
            );

            var savedUser = await _repository.SaveAsync(user, cancellationToken);
            _logger.LogInformation("User created successfully: {UserId}", savedUser.Id);

            return new Result<User>.Success(savedUser);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error creating user");
            return new Result<User>.Failure("An unexpected error occurred", ex);
        }
    }
}

// Minimal API configuration with dependency injection
var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddValidatorsFromAssemblyContaining<CreateUserRequestValidator>();

// Configure logging
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
if (builder.Environment.IsDevelopment())
{
    builder.Logging.SetMinimumLevel(LogLevel.Debug);
}

// Configure Entity Framework with PostgreSQL
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

// Minimal API endpoints
app.MapPost("/api/users", async (
    CreateUserRequest request,
    IUserService userService,
    CancellationToken cancellationToken) =>
{
    var result = await userService.CreateUserAsync(request, cancellationToken);
    return result switch
    {
        Result<User>.Success success => Results.Created($"/api/users/{success.Value.Id}", success.Value),
        Result<User>.Failure failure => Results.BadRequest(new { error = failure.Error }),
        _ => Results.StatusCode(500)
    };
})
.WithName("CreateUser")
.WithOpenApi()
.Produces<User>(StatusCodes.Status201Created)
.ProducesValidationProblem()
.RequireAuthorization();

app.Run();

// Entity Framework configuration with value converters
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.HasIndex(e => e.Email).IsUnique();
        });
    }
}

// FluentValidation for request validation
public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Email must be valid")
            .MaximumLength(255).WithMessage("Email must not exceed 255 characters");

        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("Name is required")
            .MaximumLength(100).WithMessage("Name must not exceed 100 characters");

        RuleFor(x => x.Phone)
            .Matches(@"^\+?[1-9]\d{1,14}$")
            .When(x => !string.IsNullOrEmpty(x.Phone))
            .WithMessage("Phone number must be valid E.164 format");
    }
}

// Repository pattern with Entity Framework
public interface IUserRepository
{
    Task<User> SaveAsync(User user, CancellationToken cancellationToken = default);
    Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
}

public class UserRepository : IUserRepository
{
    private readonly AppDbContext _context;

    public UserRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<User> SaveAsync(User user, CancellationToken cancellationToken = default)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync(cancellationToken);
        return user;
    }

    public async Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Users.FindAsync(new object[] { id }, cancellationToken);
    }

    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        return await _context.Users.FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
    }
}

// xUnit testing with modern patterns
[Fact]
public async Task CreateUserAsync_ValidRequest_ReturnsSuccess()
{
    // Arrange
    var request = new CreateUserRequest("test@example.com", "Test User");
    var mockRepository = new Mock<IUserRepository>();
    var mockValidator = new Mock<IValidator<CreateUserRequest>>();
    var logger = Mock.Of<ILogger<UserService>>();

    mockValidator.Setup(v => v.ValidateAsync(It.IsAny<CreateUserRequest>(), default))
             .ReturnsAsync(new ValidationResult());

    mockRepository.Setup(r => r.SaveAsync(It.IsAny<User>(), default))
                  .ReturnsAsync((User user, CancellationToken _) => user);

    var service = new UserService(mockRepository.Object, mockValidator.Object, logger);

    // Act
    var result = await service.CreateUserAsync(request);

    // Assert
    Assert.IsType<Result<User>.Success>(result);
    var success = (Result<User>.Success)result;
    Assert.Equal(request.Email, success.Value.Email);
    Assert.Equal(request.Name, success.Value.Name);
}

// Integration testing with WebApplicationFactory
public class UserApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public UserApiTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task CreateUser_ValidRequest_ReturnsCreated()
    {
        // Arrange
        var request = new CreateUserRequest("test@example.com", "Test User");
        var json = JsonSerializer.Serialize(request);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        // Act
        var response = await _client.PostAsync("/api/users", content);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();
        var user = JsonSerializer.Deserialize<User>(responseContent, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        Assert.NotNull(user);
        Assert.Equal(request.Email, user.Email);
        Assert.Equal(request.Name, user.Name);
    }
}
```
            _logger.LogError(ex, "Unexpected error creating user: {@Request}", request);
            throw new ProcessingException("Failed to create user", ex);
        }
    }
}
```

#### Rust

```rust
// Custom error types using thiserror for clean error handling
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DomainError {
    #[error("Validation error for field '{field}': {message}")]
    Validation { field: String, message: String },

    #[error("Processing error: {message}")]
    Processing { message: String },

    #[error("Database error")]
    Database(#[from] sqlx::Error),

    #[error("Network error")]
    Network(#[from] reqwest::Error),
}

// Result-based error handling (idiomatic Rust)
pub async fn create_user(request: CreateUserRequest) -> Result<User, DomainError> {
    // Validate input
    if request.email.is_empty() {
        return Err(DomainError::Validation {
            field: "email".to_string(),
            message: "Email cannot be empty".to_string(),
        });
    }

    // Process with proper error propagation
    match user_repository.create(request).await {
        Ok(user) => {
            tracing::info!(
                user_id = %user.id,
                email = %user.email,
                "User created successfully"
            );
            Ok(user)
        }
        Err(e) => {
            tracing::error!(
                error = %e,
                request = ?request,
                "Failed to create user"
            );
            Err(DomainError::Processing {
                message: "User creation failed".to_string(),
            })
        }
    }
}
```

## Logging and Observability Patterns

### Structured Logging Templates

#### Universal Logging Fields

```text
- timestamp: ISO 8601 format timestamp
- level: log level (DEBUG, INFO, WARN, ERROR, FATAL)
- logger: component/class name
- message: human-readable message
- correlation_id: request/operation tracking
- user_id: authenticated user identifier
- operation: specific operation being performed
- duration: operation execution time
- error: error details if applicable
```

#### Language-Specific Logging

##### JavaScript/TypeScript (Winston/Pino)

```typescript
import { Logger } from 'winston';

interface LogContext {
    correlationId?: string;
    userId?: string;
    operation: string;
    component: string;
}

class StructuredLogger {
    constructor(private logger: Logger) {}

    info(message: string, context: LogContext, metadata?: Record<string, unknown>): void {
        this.logger.info(message, {
            timestamp: new Date().toISOString(),
            correlation_id: context.correlationId,
            user_id: context.userId,
            operation: context.operation,
            component: context.component,
            ...metadata
        });
    }

    error(message: string, error: Error, context: LogContext): void {
        this.logger.error(message, {
            timestamp: new Date().toISOString(),
            correlation_id: context.correlationId,
            user_id: context.userId,
            operation: context.operation,
            component: context.component,
            error: {
                name: error.name,
                message: error.message,
                stack: error.stack
            }
        });
    }
}
```

##### Python (structlog)

```python
import structlog

logger = structlog.get_logger()

class UserService:
    def __init__(self):
        self.logger = logger.bind(component="user_service")

    def create_user(self, request: CreateUserRequest, user_id: str = None) -> User:
        operation_logger = self.logger.bind(
            operation="create_user",
            user_id=user_id,
            correlation_id=request.correlation_id
        )

        start_time = time.time()
        operation_logger.info("Creating user initiated", email=request.email)

        try:
            user = self._process_user_creation(request)

            operation_logger.info(
                "User created successfully",
                user_id=user.id,
                duration=time.time() - start_time
            )

            return user

        except ValidationError as e:
            operation_logger.error(
                "User validation failed",
                error=str(e),
                field=e.field,
                duration=time.time() - start_time
            )
            raise
```

##### Go (slog)

```go
func (s *UserService) CreateUser(ctx context.Context, req CreateUserRequest) (*User, error) {
    logger := slog.With(
        slog.String("component", "user_service"),
        slog.String("operation", "create_user"),
        slog.String("correlation_id", getCorrelationID(ctx)),
        slog.String("user_id", getUserID(ctx)),
    )

    start := time.Now()
    logger.Info("Creating user initiated", slog.String("email", req.Email))

    defer func() {
        logger.Info("Operation completed", slog.Duration("duration", time.Since(start)))
    }()

    user, err := s.processUserCreation(ctx, req)
    if err != nil {
        logger.Error("User creation failed",
            slog.String("error", err.Error()),
            slog.Duration("duration", time.Since(start)))
        return nil, fmt.Errorf("create user: %w", err)
    }

    logger.Info("User created successfully", slog.String("user_id", user.ID))
    return user, nil
}
```

## Performance Optimization Patterns

### Memory Management

```text
- Use object pooling for frequently allocated objects
- Implement proper resource disposal (using/with/defer patterns)
- Avoid memory leaks with proper cleanup of event listeners/subscriptions
- Use streaming for large data processing
- Implement pagination for large datasets
- Cache expensive computations with appropriate TTL
```

### Database Optimization

```text
- Use connection pooling with appropriate pool sizes
- Implement query batching for bulk operations
- Use proper indexing strategies
- Implement read replicas for read-heavy workloads
- Use database-specific optimization techniques
- Monitor query performance and optimize slow queries
```

### Caching Strategies

```text
- Application-level caching (in-memory, Redis)
- Database query result caching
- HTTP response caching with appropriate headers
- CDN usage for static assets
- Cache invalidation strategies
- Cache warming for critical data
```

## Concurrency and Async Patterns

### Language-Specific Concurrency

#### JavaScript/TypeScript

```typescript
// Promise-based concurrency
async function processDataConcurrently<T>(
    items: T[],
    processor: (item: T) => Promise<ProcessedItem>,
    concurrency: number = 5
): Promise<ProcessedItem[]> {
    const results: ProcessedItem[] = [];

    for (let i = 0; i < items.length; i += concurrency) {
        const batch = items.slice(i, i + concurrency);
        const batchResults = await Promise.all(
            batch.map(item => processor(item))
        );
        results.push(...batchResults);
    }

    return results;
}

// Worker thread usage for CPU-intensive tasks
import { Worker, isMainThread, parentPort } from 'worker_threads';

if (isMainThread) {
    const worker = new Worker(__filename);
    worker.postMessage({ data: heavyComputationData });
    worker.on('message', (result) => {
        console.log('Computation result:', result);
    });
} else {
    parentPort?.on('message', ({ data }) => {
        const result = performHeavyComputation(data);
        parentPort?.postMessage(result);
    });
}
```

#### Python

```python
import asyncio
import concurrent.futures
from typing import List, Callable, TypeVar

T = TypeVar('T')
R = TypeVar('R')

async def process_concurrently(
    items: List[T],
    processor: Callable[[T], R],
    max_workers: int = 5
) -> List[R]:
    loop = asyncio.get_event_loop()

    with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
        tasks = [
            loop.run_in_executor(executor, processor, item)
            for item in items
        ]
        return await asyncio.gather(*tasks)

# Context manager for resource management
class DatabaseManager:
    async def __aenter__(self):
        self.connection = await create_connection()
        return self.connection

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.connection.close()

# Usage
async def process_data():
    async with DatabaseManager() as db:
        results = await db.query("SELECT * FROM users")
        return results
```

#### Go

```go
// Worker pool pattern
func ProcessConcurrently[T any, R any](
    ctx context.Context,
    items []T,
    processor func(context.Context, T) (R, error),
    workers int,
) ([]R, error) {
    jobs := make(chan T, len(items))
    results := make(chan result[R], len(items))

    // Start workers
    var wg sync.WaitGroup
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for item := range jobs {
                select {
                case <-ctx.Done():
                    return
                default:
                    res, err := processor(ctx, item)
                    results <- result[R]{value: res, err: err}
                }
            }
        }()
    }

    // Send jobs
    go func() {
        defer close(jobs)
        for _, item := range items {
            select {
            case jobs <- item:
            case <-ctx.Done():
                return
            }
        }
    }()

    // Wait for workers and close results
    go func() {
        wg.Wait()
        close(results)
    }()

    // Collect results
    var processedResults []R
    for result := range results {
        if result.err != nil {
            return nil, result.err
        }
        processedResults = append(processedResults, result.value)
    }

    return processedResults, nil
}

type result[T any] struct {
    value T
    err   error
}
```

## Security Best Practices

### Input Validation and Sanitization

```text
- Validate all external inputs at boundaries
- Use allowlists over blocklists for validation
- Sanitize data before processing or storage
- Implement rate limiting for public endpoints
- Use parameterized queries to prevent SQL injection
- Validate file uploads (type, size, content)
- Implement proper authentication and authorization
```

### Secure Configuration Management

```text
- Store secrets in environment variables or secret managers
- Use different configurations for different environments
- Implement proper secret rotation strategies
- Avoid hardcoding sensitive information
- Use secure default configurations
- Implement configuration validation
```

### Audit Logging and Monitoring

```text
- Log all authentication and authorization events
- Log all data modification operations
- Implement proper log rotation and retention
- Monitor for suspicious activity patterns
- Use structured logging for better analysis
- Implement real-time alerting for security events
```

---

## Language-Specific Customization

### Quick Reference Commands

```bash
# [CUSTOMIZE]: Add your language-specific commands
# JavaScript/TypeScript
npm run lint                # Run linter
npm run format             # Format code
npm run type-check         # Type checking

# Python
black .                    # Format code
flake8 .                   # Lint code
mypy .                     # Type checking

# Go
go fmt ./...              # Format code
go vet ./...              # Vet code
golangci-lint run         # Comprehensive linting

# Java
mvn spotless:apply        # Format code
mvn checkstyle:check      # Style checking
./gradlew spotbugsMain    # Bug detection

# C# / .NET 8+
dotnet format                    # Format code
dotnet build --verbosity normal  # Build with warnings
dotnet test --collect:"XPlat Code Coverage" # Run tests with coverage
dotnet run --environment Development        # Run in specific environment
dotnet publish -c Release                   # Publish optimized build
dotnet dev-certs https --trust              # Trust development HTTPS certificate
dotnet user-secrets init                    # Initialize user secrets
dotnet add package Microsoft.EntityFrameworkCore.Design  # Add EF Core tools
dotnet ef migrations add InitialCreate     # Add EF Core migration
dotnet ef database update                  # Update database schema
dotnet watch run                           # Run with hot reload
dotnet nuget locals all --clear           # Clear NuGet cache
```

### Framework Integration

```text
[CUSTOMIZE]: Configure framework-specific patterns
- MVC frameworks: Controller/action patterns
- API frameworks: Middleware and request/response handling
- ORM frameworks: Entity and repository patterns
- Testing frameworks: Test organization and mocking strategies
- Logging frameworks: Structured logging configuration
```

This language instruction file provides comprehensive, universal development patterns that can be customized for any programming language and framework combination.
