# 🚀 Room-O-Matic Mobile: GitHub Copilot Instructions

## Project Overview

**Project Name**: Room-O-Matic Mobile
**Primary Language**: Dart/Flutter
**Framework/Stack**: Flutter Mobile with Native Platform Integration
**Architecture Pattern**: Clean Architecture + Domain-Driven Design
**Domain**: Mobile Room Measurement & Spatial Data Collection

### Tech Stack

```text
Primary Language: Dart/Flutter
Framework: Flutter 3.24+ with platform channels
Mobile Platforms: iOS (14.0+), Android (API 24+)
Native Languages: Swift (iOS), Kotlin (Android)
Sensors: LiDAR, ToF, Camera, Sonar, IMU, GPS
State Management: Riverpod
Data Layer: Floor/Drift (SQLite), Secure Storage
Authentication: Biometric (TouchID/FaceID/Fingerprint)
Testing: Flutter Test, XCTest (iOS), Espresso (Android)
CI/CD: GitHub Actions with platform-specific builds
```

## 🏗️ Architecture Patterns

### Clean Architecture + Domain-Driven Design

```text
- Domain Layer: Room scanning entities, sensor fusion, measurement algorithms
- Application Layer: Scan commands/queries, security handlers, upload services
- Infrastructure Layer: Platform channels, native sensors, secure storage
- Interface Layer: Flutter UI, platform channel handlers, camera overlays
```

### Mobile-Specific Patterns
- **Platform Channels**: Dart ↔ Native (Swift/Kotlin) communication
- **Sensor Fusion**: Multi-sensor data combination (LiDAR + Camera + IMU)
- **Security-First**: Biometric auth, encrypted storage, secure upload
- **Real-time Processing**: Stream-based sensor data with background isolates

## 📁 Directory Structure

```text
room-o-matic-mobile/
├── lib/                          # Flutter Dart code
│   ├── domain/                   # Room entities, sensor models
│   ├── application/              # Scan use cases, security services
│   ├── infrastructure/           # Platform channels, repositories
│   └── interface/                # UI screens, controllers
├── src/                          # Native platform code
│   ├── iOS/                      # Swift sensor implementations
│   └── android/                  # Kotlin sensor implementations
├── test/                         # Flutter tests
│   ├── unit/                     # Dart unit tests
│   ├── widget/                   # Widget tests
│   └── integration_test/         # Platform integration tests
├── ios/                          # iOS project configuration
├── android/                      # Android project configuration
└── docs/                         # Implementation guides
```

## 🎯 Development Standards

### Naming Conventions

**Dart/Flutter Conventions:**
- **Classes/Enums**: PascalCase (`RoomScan`, `SensorType`)
- **Functions/Variables**: camelCase (`startScan`, `sensorData`)
- **Constants**: camelCase with `k` prefix (`kMaxScanDuration`)
- **Files**: snake_case (`room_scan_controller.dart`)
- **Platform Channels**: Reverse domain (`com.roomomatic.sensors`)

**Native Platform Conventions:**
- **Swift**: PascalCase classes, camelCase methods
- **Kotlin**: PascalCase classes, camelCase functions

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

### Flutter Testing Strategy

```text
- Unit Tests: Business logic, sensor fusion algorithms
- Widget Tests: UI components, camera overlays
- Integration Tests: Platform channel communication
- Golden Tests: UI consistency across devices
- Platform Tests: Native sensor implementations (XCTest/Espresso)
```

### Mobile-Specific Test Patterns

```text
- Mock sensor data for consistent testing
- Pump and settle for widget animations
- Platform channel mocking for native features
- Biometric authentication testing with mock responses
- Camera and AR overlay screenshot testing
```

### Coverage Requirements

```text
- Sensor algorithms: 100% coverage
- Security components: 100% coverage
- UI components: 80% coverage
- Platform channels: 90% coverage
```

## 🔒 Security Requirements

### Mobile Security Standards

```text
- Biometric authentication (TouchID/FaceID/Fingerprint) required
- AES-256 encryption for local room scan data
- Certificate pinning for server communications
- No sensitive data in logs or crash reports
- Secure keychain/keystore for API tokens
- Runtime application self-protection (RASP)
- Code obfuscation for release builds
```

### Room Scanning Privacy

```text
- Location data anonymization
- User consent for camera/microphone access
- Local processing preferred over cloud
- Automatic data expiration policies
- GDPR compliance for EU users
- No personally identifiable information in scan metadata
```

## ⚡ Performance Guidelines

### Mobile Performance Patterns

```text
- Background isolates for sensor data processing
- Efficient memory management for point clouds
- Battery optimization with sensor duty cycling
- Frame rate optimization for AR overlays
- Compressed data formats for uploads
- Lazy loading for scan history
- Device capability detection and adaptation
```

### Flutter/Dart Optimizations

```text
- StreamBuilder for real-time sensor data
- Compute() for CPU-intensive calculations
- RepaintBoundary for complex widgets
- Image caching for camera frames
- Platform channel batching
- Tree shaking for smaller app size
- AOT compilation for release builds
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

## 📚 Documentation References

### Project Documentation

```markdown
**Implementation Guides:**
- [IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) - Complete architecture
- [IOS_FLUTTER_DEVELOPMENT_GUIDE.md](docs/IOS_FLUTTER_DEVELOPMENT_GUIDE.md) - iOS integration
- [ANDROID_FLUTTER_DEVELOPMENT_GUIDE.md](docs/ANDROID_FLUTTER_DEVELOPMENT_GUIDE.md) - Android integration
- [API_DOCUMENTATION.md](docs/API_DOCUMENTATION.md) - Server API specs
```

### Development Context

```text
For sensor integration:
1. Check IMPLEMENTATION_PLAN.md for domain architecture
2. Use iOS/Android guides for platform-specific implementation
3. Reference instruction files for code patterns and testing
4. Apply security-first principles for all external interfaces
```

## 🤖 AI Assistant Optimization

### Room-O-Matic AI Assistance Guidelines

```text
- Prioritize security-first implementation for all sensor data
- Always include error handling for platform channel calls
- Generate tests alongside sensor integration code
- Consider device capabilities and graceful degradation
- Include permission checks for camera/microphone/location
- Optimize for battery life and memory usage
- Follow Clean Architecture patterns with proper layer separation
```

### Flutter Development Context

```text
- State Management: Use Riverpod for reactive state
- Navigation: Go Router for type-safe routing
- Data Models: Freezed for immutable data classes
- Code Generation: Build Runner for serialization
- Platform Integration: Method channels for native features
- Testing: Mockito for mocking, Golden tests for UI
```

### Sensor-Specific Development

```text
- LiDAR: ARKit (iOS) and ToF sensors (Android)
- Camera: AVFoundation (iOS) and CameraX (Android)
- Audio: Sonar implementation with AVAudioEngine/AudioManager
- Motion: Core Motion (iOS) and SensorManager (Android)
- Location: Core Location and FusedLocationProvider
- Security: LocalAuthentication and BiometricPrompt
```
### Success Metrics

```text
- Sensor accuracy: ±2cm for distance measurements
- Battery life: >4 hours continuous scanning
- App size: <100MB total download
- Startup time: <3 seconds cold start
- Frame rate: 60fps for AR overlay
- Test coverage: >85% overall, 100% security/sensors
- Security: Zero critical vulnerabilities
```

### Quick Commands

```bash
# Flutter Development
flutter run                      # Debug mode
flutter test --coverage         # Run tests with coverage
flutter build apk --release     # Android release build
flutter build ios --release     # iOS release build

# Code Generation
dart run build_runner build     # Generate code (Freezed, etc.)
dart run build_runner watch     # Watch for changes

# Analysis & Quality
dart format .                   # Format code
dart analyze                    # Static analysis
flutter doctor                  # Check setup
```

---

**This configuration optimizes GitHub Copilot for Room-O-Matic Mobile development with Flutter, native platform integration, and security-first sensor data collection.**
