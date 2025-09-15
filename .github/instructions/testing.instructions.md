---
applyTo: "**/test/**/*test*"
description: "Essential testing patterns and standards"
---

# Universal Testing Standards

## Core Philosophy
- **Test Behavior, Not Implementation**: Focus on what code does, not how
- **Mobile-First Testing**: Prioritize Flutter widget tests, platform integration, and sensor validation
- **Security-First**: 100% coverage for biometric auth, encryption, and sensor data handling
- **Coverage Priorities**: Security components 100%, sensor algorithms 100%, UI components 80%, platform channels 90%

## Test Organization
- **Unit Tests**: Domain logic, sensor fusion algorithms, security utilities
- **Widget Tests**: Flutter UI components, camera overlays, AR interfaces
- **Integration Tests**: Platform channel communication, sensor data flow
- **Golden Tests**: UI consistency across devices and screen sizes
- **Platform Tests**: Native iOS (XCTest) and Android (Espresso) implementations

## Essential Patterns

### Arrange-Act-Assert (AAA) - Flutter Example
```dart
test('should_start_room_scan_when_user_authenticated', () {
    // ARRANGE: Set up test data and mocks
    final mockSensorService = MockSensorService();
    final mockAuthService = MockAuthService();
    when(mockAuthService.isAuthenticated()).thenReturn(true);
    when(mockSensorService.startScan()).thenReturn(Stream.value(SensorData()));

    final scanController = RoomScanController(mockSensorService, mockAuthService);

    // ACT: Execute the behavior being tested
    scanController.startScan();

    // ASSERT: Verify the expected outcome
    expect(scanController.isScanning, true);
    verify(mockSensorService.startScan()).called(1);
});
```

### Table-Driven Tests - Flutter/Dart
```dart
final testCases = [
    {'name': 'valid_distance', 'input': 2.5, 'expected': true},
    {'name': 'zero_distance', 'input': 0.0, 'expected': false},
    {'name': 'negative_distance', 'input': -1.0, 'expected': false},
    {'name': 'max_distance', 'input': 50.0, 'expected': true},
];

for (final testCase in testCases) {
    test(testCase['name'] as String, () {
        final result = isValidDistance(testCase['input'] as double);
        expect(result, testCase['expected']);
    });
}
```

### Test Data Factory - Flutter/Dart
```dart
class RoomScanFactory {
    static RoomScan create({Map<String, dynamic> overrides = const {}}) {
        final defaults = {
            'id': 'scan-123',
            'userId': 'user-456',
            'dimensions': RoomDimensions(length: 4.0, width: 3.0, height: 2.5),
            'createdAt': DateTime.now(),
            'sensorData': <SensorReading>[],
        };

        final merged = {...defaults, ...overrides};
        return RoomScan.fromMap(merged);
    }

    static SensorReading createSensorReading({Map<String, dynamic> overrides = const {}}) {
        return SensorReading(
            type: SensorType.lidar,
            value: 2.5,
            timestamp: DateTime.now(),
            accuracy: 0.02,
            ...overrides,
        );
    }
}

// Usage: final scan = RoomScanFactory.create(overrides: {'userId': 'custom-user'});
```
        ## Mocking Patterns

### Dependency Injection Mocking
```typescript
// Create mock dependencies
const mockRepository = {
    save: jest.fn().mockResolvedValue(user),
    findById: jest.fn().mockResolvedValue(user)
};

// Inject mocks into system under test
const userService = new UserService(mockRepository);

// Verify interactions
expect(mockRepository.save).toHaveBeenCalledWith(expectedUser);
```

### Error Testing
```typescript
test("should_handle_repository_error") {
    // Arrange
    mockRepository.save.mockRejectedValue(new Error("Database error"));

    // Act & Assert
    expect(() => userService.createUser(userData))
        .rejects.toThrow("Database error");
}
```

## Language-Specific Quick Commands

### Dart/Flutter Testing
```bash
flutter test                           # Run all tests
flutter test --coverage               # Run with coverage
flutter test test/unit/               # Run specific test suite
flutter test --watch                  # Watch mode
flutter test --reporter json         # JSON output
dart run test                        # Run Dart tests only
```

### Framework Examples

#### Dart/Flutter
```dart
// Widget test
testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('0'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});

// Unit test with mock
test('should create user when valid data provided', () {
  final mockRepo = MockUserRepository();
  when(mockRepo.save(any)).thenReturn(User(id: '123'));

  final service = UserService(mockRepo);
  final result = service.createUser('test@email.com');

  expect(result.id, '123');
  verify(mockRepo.save(any)).called(1);
});
```

#### JavaScript/TypeScript
```typescript
describe('UserService', () => {
  test('should create user successfully', async () => {
    const mockRepo = { save: jest.fn().mockResolvedValue(user) };
    const service = new UserService(mockRepo);

    const result = await service.createUser(userData);

    expect(result).toEqual(expectedUser);
    expect(mockRepo.save).toHaveBeenCalledWith(userData);
  });
});
```

## Essential Testing Guidelines

### What to Test
- **Public interfaces and contracts**
- **Error handling and edge cases**
- **Business logic and validation rules**
- **Integration points and external dependencies**

### What NOT to Test
- **Private implementation details**
- **Third-party library internals**
- **Generated code (unless business critical)**
- **Simple getters/setters without logic**

### Quality Metrics
- **Test Coverage**: Aim for 80%+ overall, 100% for critical paths
- **Test Speed**: Unit tests <100ms, integration tests <1s
- **Test Reliability**: Zero flaky tests, deterministic outcomes
- **Test Maintainability**: Clear naming, minimal duplication, easy updates
    }

    static createValidationError(field, message) {
        return new ValidationError(field, message);
    }
}
```

## Framework-Specific Patterns

### Testing Framework Templates

#### JavaScript/TypeScript (Jest/Vitest)

```javascript
describe('UserService', () => {
    beforeEach(() => {
        // Setup before each test
    });

    afterEach(() => {
        // Cleanup after each test
    });

    test('should create user successfully', async () => {
        // Test implementation
    });
});
```

#### Python (pytest)

```python
class TestUserService:
    def setup_method(self):
        # Setup before each test
        pass

    def teardown_method(self):
        # Cleanup after each test
        pass

    def test_should_create_user_successfully(self):
        # Test implementation
        pass
```

#### Go (testing)

```go
func TestUserService_CreateUser_Success(t *testing.T) {
    tests := []struct {
        name    string
        input   CreateUserInput
        want    *User
        wantErr error
    }{
        // Test cases here
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test implementation
        })
    }
}
```

#### Java (JUnit)

```java
class UserServiceTest {
    @BeforeEach
    void setUp() {
        // Setup before each test
    }

    @AfterEach
    void tearDown() {
        // Cleanup after each test
    }

    @Test
    @DisplayName("Should create user successfully")
    void shouldCreateUserSuccessfully() {
        // Test implementation
    }
}
```

#### C# / .NET 8+ (xUnit with Modern Patterns)

```csharp
// Domain model using records
public record CreateUserRequest(string Email, string Name, string? Phone = null);
public record User(Guid Id, string Email, string Name, string? Phone, DateTime CreatedAt);

// Result pattern for error handling
public abstract record Result<T>
{
    public record Success(T Value) : Result<T>;
    public record Failure(string Error) : Result<T>;
}

// Service interface
public interface IUserService
{
    Task<Result<User>> CreateUserAsync(CreateUserRequest request, CancellationToken cancellationToken = default);
}

// Unit tests with modern patterns
public class UserServiceTests
{
    private readonly Mock<IUserRepository> _mockRepository;
    private readonly Mock<IValidator<CreateUserRequest>> _mockValidator;
    private readonly Mock<ILogger<UserService>> _mockLogger;
    private readonly UserService _userService;

    public UserServiceTests()
    {
        _mockRepository = new Mock<IUserRepository>();
        _mockValidator = new Mock<IValidator<CreateUserRequest>>();
        _mockLogger = new Mock<ILogger<UserService>>();
        _userService = new UserService(_mockRepository.Object, _mockValidator.Object, _mockLogger.Object);
    }

    [Fact]
    public async Task CreateUserAsync_WithValidRequest_ShouldReturnSuccessResult()
    {
        // Arrange
        var request = new CreateUserRequest("test@example.com", "Test User");
        var validationResult = new ValidationResult();
        var expectedUser = new User(Guid.NewGuid(), request.Email, request.Name, request.Phone, DateTime.UtcNow);

        _mockValidator.Setup(v => v.ValidateAsync(request, default))
                     .ReturnsAsync(validationResult);

        _mockRepository.Setup(r => r.SaveAsync(It.IsAny<User>(), default))
                      .ReturnsAsync((User user, CancellationToken _) => user);

        // Act
        var result = await _userService.CreateUserAsync(request);

        // Assert
        Assert.IsType<Result<User>.Success>(result);
        var success = (Result<User>.Success)result;
        Assert.Equal(request.Email, success.Value.Email);
        Assert.Equal(request.Name, success.Value.Name);

        _mockValidator.Verify(v => v.ValidateAsync(request, default), Times.Once);
        _mockRepository.Verify(r => r.SaveAsync(It.IsAny<User>(), default), Times.Once);
    }

    [Theory]
    [InlineData("", "Valid Name", "Email is required")]
    [InlineData("invalid-email", "Valid Name", "Email must be valid")]
    [InlineData("valid@email.com", "", "Name is required")]
    public async Task CreateUserAsync_WithInvalidRequest_ShouldReturnFailureResult(
        string email, string name, string expectedError)
    {
        // Arrange
        var request = new CreateUserRequest(email, name);
        var validationResult = new ValidationResult(new[]
        {
            new ValidationFailure("Field", expectedError)
        });

        _mockValidator.Setup(v => v.ValidateAsync(request, default))
                     .ReturnsAsync(validationResult);

        // Act
        var result = await _userService.CreateUserAsync(request);

        // Assert
        Assert.IsType<Result<User>.Failure>(result);
        var failure = (Result<User>.Failure)result;
        Assert.Contains(expectedError, failure.Error);
    }

    [Fact]
    public async Task CreateUserAsync_WhenRepositoryThrows_ShouldReturnFailureResult()
    {
        // Arrange
        var request = new CreateUserRequest("test@example.com", "Test User");
        var validationResult = new ValidationResult();

        _mockValidator.Setup(v => v.ValidateAsync(request, default))
                     .ReturnsAsync(validationResult);

        _mockRepository.Setup(r => r.SaveAsync(It.IsAny<User>(), default))
                      .ThrowsAsync(new InvalidOperationException("Database error"));

        // Act
        var result = await _userService.CreateUserAsync(request);

        // Assert
        Assert.IsType<Result<User>.Failure>(result);
        var failure = (Result<User>.Failure)result;
        Assert.Equal("An unexpected error occurred", failure.Error);
    }
}

// Integration tests using WebApplicationFactory
public class UserApiIntegrationTests : IClassFixture<WebApplicationFactory<Program>>, IAsyncDisposable
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;
    private readonly IServiceScope _scope;
    private readonly AppDbContext _dbContext;

    public UserApiIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.UseEnvironment("Testing");
            builder.ConfigureServices(services =>
            {
                // Replace database with in-memory database for testing
                services.RemoveAll<DbContextOptions<AppDbContext>>();
                services.AddDbContext<AppDbContext>(options =>
                    options.UseInMemoryDatabase($"TestDb_{Guid.NewGuid()}"));
            });
        });

        _client = _factory.CreateClient();
        _scope = _factory.Services.CreateScope();
        _dbContext = _scope.ServiceProvider.GetRequiredService<AppDbContext>();
    }

    [Fact]
    public async Task PostUser_WithValidRequest_ShouldCreateUser()
    {
        // Arrange
        var request = new CreateUserRequest("integration@test.com", "Integration Test User");
        var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
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

        // Verify user was saved to database
        var savedUser = await _dbContext.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        Assert.NotNull(savedUser);
    }

    [Theory]
    [InlineData("", "Valid Name")]
    [InlineData("invalid-email", "Valid Name")]
    [InlineData("valid@email.com", "")]
    public async Task PostUser_WithInvalidRequest_ShouldReturnBadRequest(string email, string name)
    {
        // Arrange
        var request = new CreateUserRequest(email, name);
        var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        // Act
        var response = await _client.PostAsync("/api/users", content);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    public async ValueTask DisposeAsync()
    {
        await _dbContext.DisposeAsync();
        _scope.Dispose();
        _client.Dispose();
        await _factory.DisposeAsync();
    }
}

// Performance testing with NBomber
[Fact]
public void UserApi_LoadTest_ShouldHandleExpectedThroughput()
{
    var scenario = Scenario.Create("create_user_scenario", async context =>
    {
        var request = new CreateUserRequest($"load-test-{context.InvocationNumber}@test.com", "Load Test User");
        var json = JsonSerializer.Serialize(request);
        var content = new StringContent(json, Encoding.UTF8, "application/json");

        using var client = new HttpClient();
        client.BaseAddress = new Uri("https://localhost:7001");

        var response = await client.PostAsync("/api/users", content);
        return response.IsSuccessStatusCode ? Response.Ok() : Response.Fail();
    })
    .WithLoadSimulations(
        Simulation.InjectPerSec(rate: 100, during: TimeSpan.FromMinutes(1))
    );

    NBomberRunner
        .RegisterScenarios(scenario)
        .Run();
}
```
    }
}
```

#### Rust (cargo test)

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use tokio_test;
    use proptest::prelude::*;

    #[test]
    fn test_create_user_success() {
        // Arrange
        let request = CreateUserRequest {
            email: "test@example.com".to_string(),
            name: "Test User".to_string(),
        };

        // Act
        let result = create_user(request);

        // Assert
        assert!(result.is_ok());
        let user = result.unwrap();
        assert_eq!(user.email, "test@example.com");
    }

    #[tokio::test]
    async fn test_create_user_async_success() {
        let request = CreateUserRequest {
            email: "async@example.com".to_string(),
            name: "Async User".to_string(),
        };

        let result = create_user_async(request).await;
        assert!(result.is_ok());
    }

    // Property-based testing with proptest
    proptest! {
        #[test]
        fn test_email_validation(email in "[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}") {
            let result = validate_email(&email);
            prop_assert!(result.is_ok());
        }
    }

    // Benchmark tests
    #[bench]
    fn bench_user_creation(b: &mut test::Bencher) {
        b.iter(|| {
            let request = CreateUserRequest {
                email: "bench@example.com".to_string(),
                name: "Bench User".to_string(),
            };
            create_user(request)
        });
    }
}
```

## Mocking and Test Doubles

### Mock Strategy

```text
- Mock external dependencies (databases, APIs, file systems)
- Use real objects for value objects and simple data structures
- Create test doubles for complex collaborators
- Verify behavior on mocks, state on real objects
```

### Mock Patterns

```text
[Language-specific mocking examples]

// JavaScript (Jest)
const mockRepository = jest.fn();
mockRepository.save = jest.fn().mockResolvedValue(user);

// Python (unittest.mock)
with patch('module.Repository') as mock_repo:
    mock_repo.save.return_value = user

// Go (testify/mock)
mockRepo := &MockRepository{}
mockRepo.On("Save", mock.Anything, mock.Anything).Return(user, nil)

// Java (Mockito)
@Mock
private Repository repository;
when(repository.save(any())).thenReturn(user);
```

## Async and Concurrency Testing

### Async Test Patterns

```text
- Use proper async/await patterns for asynchronous code
- Test timeout scenarios with appropriate test timeouts
- Verify async error handling and propagation
- Test concurrent execution patterns safely
```

### Concurrency Test Strategies

```text
- Use deterministic testing approaches
- Control timing with synchronization primitives
- Test race conditions with multiple iterations
- Verify thread safety with concurrent operations
```

## Integration Test Patterns

### Database Testing

```text
- Use test databases or containers
- Implement proper test data setup and teardown
- Test transaction boundaries and rollbacks
- Verify database constraints and relationships
```

### API Testing

```text
- Test complete request/response cycles
- Verify error responses and status codes
- Test authentication and authorization
- Validate request/response schemas
```

### External Service Testing

```text
- Use service virtualization or contract testing
- Implement circuit breaker and retry logic testing
- Test failure scenarios and degraded modes
- Verify service contract compliance
```

## Performance and Load Testing

### Performance Test Types

```text
- Load Testing: Normal expected load
- Stress Testing: Beyond normal capacity
- Spike Testing: Sudden load increases
- Volume Testing: Large amounts of data
- Endurance Testing: Extended periods
```

### Performance Assertions

```text
- Response time thresholds
- Throughput requirements
- Resource utilization limits
- Memory leak detection
- Database query performance
```

## Security Testing Patterns

### Security Test Categories

```text
- Input validation and sanitization
- Authentication and authorization
- Session management
- Data encryption and protection
- SQL injection and XSS prevention
```

### Security Assertions

```text
- Verify access control enforcement
- Test input boundary conditions
- Validate error message information leakage
- Check for sensitive data exposure
- Test rate limiting and DOS protection
```

## Test Maintenance and Quality

### Test Code Quality

```text
- Apply same coding standards as production code
- Use descriptive test names that explain the scenario
- Keep tests independent and isolated
- Minimize test setup complexity
- Refactor tests when production code changes
```

### Test Documentation

```text
- Document complex test scenarios
- Explain non-obvious test data choices
- Maintain test suite documentation
- Document test environment requirements
- Keep test coverage reports updated
```

## Continuous Integration Integration

### CI/CD Test Strategy

```text
- Unit tests: Run on every commit
- Integration tests: Run on pull requests
- E2E tests: Run on staging deployments
- Performance tests: Run on release candidates
- Security tests: Run on security-sensitive changes
```

### Test Reporting

```text
- Generate test coverage reports
- Track test execution trends
- Report test failure patterns
- Monitor test suite execution time
- Maintain test quality metrics
```

---

## Testing Framework Customization

### Quick Start Commands

```bash
# [CUSTOMIZE]: Add your language-specific commands
# JavaScript/TypeScript
npm test                    # Run all tests
npm run test:watch         # Run tests in watch mode
npm run test:coverage      # Run tests with coverage

# Python
pytest                     # Run all tests
pytest --cov=src          # Run with coverage
pytest -x                 # Stop on first failure

# Go
go test ./...              # Run all tests
go test -race ./...        # Run with race detection
go test -cover ./...       # Run with coverage

# Java
mvn test                   # Run tests with Maven
gradle test               # Run tests with Gradle

# C# / .NET 8+
dotnet test                                    # Run all tests
dotnet test --collect:"XPlat Code Coverage"   # Run tests with coverage
dotnet test --filter "Category=Unit"          # Run specific test category
dotnet test --logger "console;verbosity=detailed"  # Detailed test output
dotnet test --settings coverlet.runsettings   # Custom test settings
dotnet run --project tests/IntegrationTests   # Run integration tests
dotnet test --blame-hang-timeout 30s          # Debug hanging tests
```

### IDE Integration

```text
[CUSTOMIZE]: Configure your IDE for optimal testing experience
- Set up test runners and debugging
- Configure test coverage visualization
- Set up automatic test execution on save
- Configure test result reporting and notifications
```

This testing instruction file provides comprehensive, language-agnostic testing patterns that any project can customize for their specific technology stack and requirements.
