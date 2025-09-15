# 🏠 Room-O-Matic Mobile

A Flutter mobile application for precise room measurement using advanced sensor technology. Built with Clean Architecture + Domain-Driven Design for offline-first operation with optional server integration.

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## 🚀 Features

- **🔍 Multi-Sensor Scanning**: LiDAR, ToF, Camera, Sonar, and IMU sensor fusion
- **📱 Offline-First**: All functionality works without internet connection
- **🔒 Security-First**: Biometric authentication and AES-256 encryption
- **📊 Real-Time Processing**: Background isolates for sensor data processing
- **📋 Multiple Export Formats**: PDF reports, CSV data, 3D models (OBJ/PLY)
- **🎯 High Precision**: ±2cm accuracy for distance measurements
- **🔋 Battery Optimized**: Sensor duty cycling and efficient memory management

## 🏗️ Architecture

### Clean Architecture + Domain-Driven Design

```
lib/
├── domain/                    # Business logic and rules
│   ├── entities/              # Core business entities
│   ├── value_objects/         # Immutable value objects
│   ├── repositories/          # Repository interfaces
│   └── services/              # Domain services
├── application/               # Use cases and application logic
│   ├── usecases/              # Business use cases
│   ├── services/              # Application services
│   └── providers/             # Riverpod providers
├── infrastructure/            # External concerns
│   ├── database/              # Drift/SQLite implementation
│   ├── repositories/          # Repository implementations
│   ├── services/              # Service implementations
│   └── platform_channels/     # Native platform integration
└── interface/                 # UI and presentation
    ├── screens/               # Flutter screens
    ├── widgets/               # Reusable widgets
    └── app.dart               # App configuration
```

### Technology Stack

- **Framework**: Flutter 3.24+ with Dart 3.0+
- **State Management**: Riverpod for reactive state
- **Database**: Drift (SQLite) for offline-first storage
- **Serialization**: Freezed + json_annotation
- **Navigation**: GoRouter for type-safe routing
- **Security**: BiometricAuth + SecureStorage
- **Native Integration**: Platform channels for sensor access
- **Testing**: Comprehensive unit, widget, and integration tests

## 🔧 Development Setup

### Prerequisites

- Flutter SDK 3.24+
- Dart SDK 3.0+
- iOS: Xcode 15+ for iOS development
- Android: Android Studio with API 24+ support

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/sosh-ncampbell/room-o-matic-mobile.git
   cd room-o-matic-mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Quick Commands

```bash
# Development
flutter run                          # Debug mode
flutter test --coverage             # Run tests with coverage
flutter analyze                     # Static analysis

# Code Generation
flutter packages pub run build_runner build    # Generate code
flutter packages pub run build_runner watch    # Watch for changes

# Build
flutter build apk --release         # Android release
flutter build ios --release         # iOS release

# Quality Checks
dart format .                       # Format code
flutter doctor                      # Check setup
```

## 📱 Platform Integration

### iOS (14.0+)
- **LiDAR**: ARKit integration for room scanning
- **Camera**: AVFoundation for visual reference
- **Audio**: AVAudioEngine for sonar functionality
- **Motion**: Core Motion for IMU data
- **Security**: LocalAuthentication for biometric auth

### Android (API 24+)
- **ToF Sensors**: Camera2 API for depth sensing
- **Camera**: CameraX for image capture
- **Audio**: AudioManager for sonar implementation
- **Motion**: SensorManager for IMU data
- **Security**: BiometricPrompt for authentication

## 🧪 Testing

### Test Coverage
- **Domain Layer**: 100% coverage (business logic)
- **Application Layer**: 90% coverage (use cases)
- **Infrastructure**: 85% coverage (implementations)
- **Interface**: 80% coverage (UI components)

### Test Types
```bash
flutter test test/unit/             # Unit tests
flutter test test/widget/           # Widget tests
flutter test test/integration_test/ # Integration tests
```

## 🔒 Security & Privacy

### Security Measures
- **Biometric Authentication**: TouchID/FaceID/Fingerprint required
- **Data Encryption**: AES-256 for local storage
- **Secure Communication**: Certificate pinning for API calls
- **Runtime Protection**: Code obfuscation in release builds
- **Permission Management**: Granular sensor access control

### Privacy Features
- **Local Processing**: All scanning data processed on-device
- **No Data Collection**: Zero telemetry or analytics
- **User Consent**: Explicit permission for each sensor
- **Data Retention**: Automatic expiration policies
- **GDPR Compliance**: Full data portability and deletion

## 📊 Performance Targets

- **Accuracy**: ±2cm for distance measurements
- **Battery Life**: >4 hours continuous scanning
- **Startup Time**: <3 seconds cold start
- **Frame Rate**: 60fps for AR overlay
- **App Size**: <100MB total download
- **Memory Usage**: <512MB peak during scanning

## 🚀 Deployment

### Development Build
```bash
flutter build apk --debug
flutter build ios --debug
```

### Production Build
```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols
flutter build ios --release --obfuscate --split-debug-info=build/symbols
```

## 📚 Documentation

- [Implementation Plan](docs/IMPLEMENTATION_PLAN.md) - Complete architecture overview
- [iOS Development Guide](docs/IOS_FLUTTER_DEVELOPMENT_GUIDE.md) - iOS-specific implementation
- [Android Development Guide](docs/ANDROID_FLUTTER_DEVELOPMENT_GUIDE.md) - Android-specific implementation
- [API Documentation](docs/API_DOCUMENTATION.md) - Server API specifications
- [Contributing Guidelines](CONTRIBUTING.md) - Development workflow and standards

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the [docs/](docs/) directory
- **Issues**: Create an issue on GitHub
- **Email**: support@roomomatic.com

---

**Room-O-Matic Mobile** - Precision room measurement at your fingertips 📱📏
