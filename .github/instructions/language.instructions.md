---
applyTo: "**/src/**/*.{js,ts,py,go,java,cs,rs,rb,php,kt,scala,swift,dart}"
description: "Essential development patterns and standards"
---

# Universal Development Standards

## Core Principles
- **SOLID**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Clean Architecture + DDD**: Domain-driven design with clear layer separation for mobile apps
- **Security-First**: Biometric authentication, encrypted storage, secure sensor data handling
- **Mobile Performance**: Battery optimization, memory management, efficient sensor processing
- **Platform Integration**: Seamless Dart ↔ Native (Swift/Kotlin) communication

## Key Anti-Patterns to Avoid

### Critical Issues - Flutter/Dart Focus
```dart
// ❌ Silent failures in platform channels
try {
  final result = await platform.invokeMethod('startScan');
} catch (e) {
  // Silent failure - BAD!
}

// ✅ Explicit error handling with user feedback
try {
  final result = await platform.invokeMethod('startScan');
  return Right(result);
} on PlatformException catch (e) {
  return Left(SensorFailure('Failed to start scan: ${e.message}'));
}

// ❌ Poor naming
class SM { void p() {} }

// ✅ Descriptive naming
class SensorManager {
  Future<void> startProximityScanning() {}
}

// ❌ Resource leaks (streams not disposed)
StreamSubscription? _subscription;
void startListening() {
  _subscription = sensorStream.listen((data) => process(data));
  // No disposal - MEMORY LEAK!
}

// ✅ Proper cleanup with Riverpod/dispose patterns
class SensorController extends StateNotifier<SensorState> {
  StreamSubscription? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### Language-Specific Anti-Patterns
- **Dart/Flutter**: Not disposing controllers/streams, using StatefulWidget unnecessarily, blocking main isolate with heavy computations
- **Swift (iOS)**: Force unwrapping optionals, not handling platform channel errors, memory retain cycles
- **Kotlin (Android)**: Not handling lifecycle properly, platform channel memory leaks, blocking main thread
- **Security**: Storing sensitive data unencrypted, not validating biometric authentication, logging sensor data

## Error Handling Patterns

### Dart/Flutter - Primary Language
```dart
// Result pattern for explicit error handling
abstract class Result<T, E> {
  const Result();
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}

// Platform channel error handling
class SensorService {
  Future<Result<SensorData, SensorFailure>> readSensorData() async {
    try {
      final data = await _platform.invokeMethod('readSensor');
      return Success(SensorData.fromMap(data));
    } on PlatformException catch (e) {
      return Failure(SensorFailure.platformError(e.message));
    } catch (e) {
      return Failure(SensorFailure.unknown(e.toString()));
    }
  }
}

// Freezed union types for error handling
@freezed
class RoomScanState with _$RoomScanState {
  const factory RoomScanState.idle() = _Idle;
  const factory RoomScanState.scanning(List<SensorReading> readings) = _Scanning;
  const factory RoomScanState.completed(RoomScan scan) = _Completed;
  const factory RoomScanState.error(String message) = _Error;
}
```

### Go
```go
type DomainError struct {
    Op      string
    Message string
    Err     error
}

func (e *DomainError) Error() string {
    return fmt.Sprintf("%s: %s", e.Op, e.Message)
}

func (s *Service) CreateUser(ctx context.Context, req Request) (*User, error) {
    if err := validate(req); err != nil {
        return nil, &DomainError{Op: "CreateUser", Message: "validation failed", Err: err}
    }
    return user, nil
}
```

### Python
```python
class DomainError(Exception):
    """Base domain exception"""

def process_data(data: dict) -> User:
    try:
        return User.from_dict(data)
    except ValueError as e:
        raise DomainError(f"Invalid user data: {e}") from e
```

### C# / .NET 8+ Modern Patterns
```csharp
// Modern record types and Result pattern
public record CreateUserRequest([Required] string Email, [Required] string Name, string? Phone = null);
public record User(Guid Id, string Email, string Name, string? Phone, DateTime CreatedAt);

public abstract record Result<T>
{
    public record Success(T Value) : Result<T>();
    public record Failure(string Error) : Result<T>();
}

// Minimal API with dependency injection
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();
app.MapPost("/api/users", async (CreateUserRequest request, IUserService service) => {
    var result = await service.CreateUserAsync(request);
    return result switch {
        Result<User>.Success(var user) => Results.Created($"/api/users/{user.Id}", user),
        Result<User>.Failure(var error) => Results.BadRequest(error),
        _ => Results.Problem()
    };
});

// Service with modern async patterns
public class UserService
{
    public async Task<Result<User>> CreateUserAsync(CreateUserRequest request, CancellationToken ct = default)
    {
        try {
            var user = new User(Guid.NewGuid(), request.Email, request.Name, request.Phone, DateTime.UtcNow);
            await _repository.SaveAsync(user, ct);
            return new Result<User>.Success(user);
        } catch (Exception ex) {
            return new Result<User>.Failure(ex.Message);
        }
    }
}
```

## Essential Patterns

### Structured Logging
```typescript
// Universal logging fields: timestamp, level, component, correlationId, userId, operation, duration, error
interface LogContext {
    correlationId?: string;
    userId?: string;
    component: string;
}

logger.info("User created successfully", {
    userId: user.id,
    operation: "createUser",
    duration: 150
});
```

### Performance Optimization
- **Memory**: Object pooling, proper disposal, avoid leaks
- **Database**: Connection pooling, query batching, indexing
- **Caching**: Application-level, query result, HTTP response caching
- **Concurrency**: Worker pools, async/await patterns, proper cleanup

### Security Best Practices
- **Input Validation**: Allowlists over blocklists, sanitization
- **Authentication**: Rate limiting, parameterized queries, secure defaults
- **Secrets**: Environment variables, secret rotation, no hardcoding
- **Audit Logging**: All auth events, data modifications, real-time alerting

### Quick Commands
```bash
# Dart/Flutter (Primary Language for Room-O-Matic Mobile)
flutter doctor                   # Check development environment
flutter create room_app          # Create new Flutter project
flutter pub get                  # Install dependencies
flutter run                      # Run in debug mode
flutter test                     # Run all tests
flutter test --coverage          # Run tests with coverage
flutter build apk --release      # Build Android release
flutter build ios --release      # Build iOS release
flutter analyze                  # Static analysis
dart format .                    # Format Dart code
flutter clean                    # Clean build cache

# Platform Channel Development
flutter build ios --debug        # Build iOS with debug symbols
flutter build android --debug    # Build Android with debug symbols
flutter logs                     # View real-time logs

# Code Generation (Freezed, JSON, etc.)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch     # Watch for changes

# Native Platform Development
# iOS (Swift)
cd ios && pod install           # Install iOS dependencies
open ios/Runner.xcworkspace     # Open in Xcode

# Android (Kotlin)
cd android && ./gradlew build   # Build Android project
```
