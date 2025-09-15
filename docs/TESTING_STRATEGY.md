# 🧪 Room-O-Matic Mobile: Testing Strategy

## Overview

This document outlines the comprehensive testing strategy for Room-O-Matic Mobile, a Flutter app for room measurement and spatial data collection. Our testing approach follows mobile-first principles with emphasis on sensor accuracy, security validation, and platform-specific functionality.

## Testing Philosophy

### Security-First Testing
- **Biometric Authentication**: Mock biometric responses for consistent testing
- **Data Encryption**: Validate AES-256 encryption/decryption processes
- **Privacy Compliance**: Test GDPR data export and deletion workflows
- **Secure Storage**: Verify keychain/keystore integration

### Sensor-Critical Testing
- **Accuracy Requirements**: ±2cm tolerance for distance measurements
- **Multi-Sensor Fusion**: LiDAR + Camera + IMU data combination
- **Real-time Processing**: Frame rate validation (60fps AR overlay)
- **Battery Optimization**: Power consumption during continuous scanning

## Test Pyramid Structure

```
                    E2E Tests (5%)
                Platform Integration Tests (15%)
            Unit Tests + Widget Tests (80%)
```

### Unit Tests (60% - High Volume, Fast Feedback)
**Target Coverage: 90%+ for business logic**

#### Sensor Algorithm Testing
```dart
// Example: Distance calculation accuracy
test('LiDAR distance calculation within tolerance', () {
  final calculator = DistanceCalculator();
  final mockPoints = generateMockLiDARPoints();

  final distance = calculator.calculateDistance(mockPoints);

  expect(distance, closeTo(expectedDistance, tolerance: 0.02)); // ±2cm
});
```

#### Security Component Testing
```dart
// Example: Encryption validation
test('AES-256 encryption roundtrip preserves data', () async {
  final encryptionService = EncryptionService();
  final originalData = RoomScanData.mock();

  final encrypted = await encryptionService.encrypt(originalData);
  final decrypted = await encryptionService.decrypt(encrypted);

  expect(decrypted, equals(originalData));
});
```

#### State Management Testing
```dart
// Example: Riverpod provider testing
test('ExportNotifier handles successful export', () async {
  final container = ProviderContainer();

  final notifier = container.read(exportNotifierProvider.notifier);
  await notifier.startExport(format: 'json', options: mockOptions);

  final state = container.read(exportNotifierProvider);
  expect(state, isA<ExportSuccess>());
});
```

### Widget Tests (20% - UI Component Validation)
**Target Coverage: 80%+ for UI components**

#### Retro Widget Testing
```dart
// Example: RetroButton interaction testing
testWidgets('RetroButton calls onPressed when tapped', (tester) async {
  var pressed = false;

  await tester.pumpWidget(
    MaterialApp(
      home: RetroButton(
        text: 'Test Button',
        onPressed: () => pressed = true,
      ),
    ),
  );

  await tester.tap(find.byType(RetroButton));
  expect(pressed, isTrue);
});
```

#### Golden Tests for Visual Consistency
```dart
// Example: Theme consistency across devices
testWidgets('Privacy screen matches golden file', (tester) async {
  await tester.pumpWidget(createTestApp(PrivacyScreen()));
  await expectLater(
    find.byType(PrivacyScreen),
    matchesGoldenFile('privacy_screen.png'),
  );
});
```

### Integration Tests (15% - Platform Channel Validation)
**Focus: Flutter ↔ Native communication**

#### Platform Channel Testing
```dart
// Example: iOS LiDAR integration
testWidgets('iOS LiDAR platform channel returns data', (tester) async {
  const MethodChannel channel = MethodChannel('room_o_matic/sensors');

  // Mock platform method calls
  channel.setMockMethodCallHandler((call) async {
    if (call.method == 'startLiDARScan') {
      return {'status': 'success', 'points': mockLiDARData};
    }
    return null;
  });

  await tester.pumpWidget(MyApp());

  // Trigger LiDAR scan
  await tester.tap(find.byKey(Key('start_scan_button')));
  await tester.pumpAndSettle();

  // Verify scan data received
  expect(find.text('Scan Started'), findsOneWidget);
});
```

#### Biometric Authentication Testing
```dart
// Example: Mock biometric authentication
testWidgets('Biometric auth success flow', (tester) async {
  const MethodChannel channel = MethodChannel('room_o_matic/biometrics');

  channel.setMockMethodCallHandler((call) async {
    if (call.method == 'authenticate') {
      return {'success': true, 'method': 'faceID'};
    }
    return null;
  });

  await tester.pumpWidget(MyApp());

  // Trigger biometric auth
  await tester.tap(find.byKey(Key('biometric_auth_button')));
  await tester.pumpAndSettle();

  // Verify authentication success
  expect(find.text('Authentication Successful'), findsOneWidget);
});
```

### End-to-End Tests (5% - Critical User Journeys)
**Focus: Complete user workflows**

#### Room Scanning Workflow
```dart
// Example: Complete room scan workflow
testWidgets('Complete room scan and export workflow', (tester) async {
  await tester.pumpWidget(MyApp());

  // Navigate to scan screen
  await tester.tap(find.byKey(Key('new_scan_button')));
  await tester.pumpAndSettle();

  // Start scanning
  await tester.tap(find.byKey(Key('start_scan_button')));
  await tester.pump(Duration(seconds: 5)); // Simulate scan duration

  // Complete scan
  await tester.tap(find.byKey(Key('complete_scan_button')));
  await tester.pumpAndSettle();

  // Navigate to export
  await tester.tap(find.byKey(Key('export_button')));
  await tester.pumpAndSettle();

  // Start export
  await tester.tap(find.byKey(Key('start_export_button')));
  await tester.pumpAndSettle();

  // Verify export success
  expect(find.text('Export Complete'), findsOneWidget);
});
```

## Platform-Specific Testing

### iOS Testing Strategy
- **XCTest Integration**: Native iOS sensor testing
- **ARKit Validation**: LiDAR and camera integration accuracy
- **TouchID/FaceID**: Biometric authentication flows
- **Keychain**: Secure storage validation

### Android Testing Strategy
- **Espresso Integration**: Native Android sensor testing
- **CameraX Validation**: Camera and ToF sensor integration
- **Fingerprint/Face**: Biometric authentication flows
- **Keystore**: Secure storage validation

## Test Data Management

### Mock Sensor Data
```dart
class MockSensorData {
  static List<LiDARPoint> generateLiDARPoints({
    required double roomWidth,
    required double roomHeight,
    required double roomDepth,
  }) {
    // Generate consistent mock LiDAR points for testing
  }

  static CameraFrame generateCameraFrame({
    required int width,
    required int height,
  }) {
    // Generate mock camera frame data
  }
}
```

### Test Environment Setup
```dart
class TestEnvironment {
  static Future<void> setupTestDatabase() async {
    // Initialize test database with mock room scan data
  }

  static Future<void> mockPlatformChannels() async {
    // Setup platform channel mocks for all native integrations
  }

  static Future<void> configureBiometricMocks() async {
    // Setup biometric authentication mocks
  }
}
```

## Performance Testing

### Memory Usage Validation
```dart
test('Point cloud processing stays within memory limits', () {
  final processor = PointCloudProcessor();
  final largePointCloud = generateLargePointCloud(points: 100000);

  final initialMemory = getMemoryUsage();
  processor.processPointCloud(largePointCloud);
  final finalMemory = getMemoryUsage();

  expect(finalMemory - initialMemory, lessThan(50 * 1024 * 1024)); // < 50MB
});
```

### Battery Usage Testing
```dart
test('Continuous scanning battery usage within limits', () async {
  final scanner = RoomScanner();
  final batteryMonitor = BatteryMonitor();

  await scanner.startContinuousScanning();
  await Future.delayed(Duration(hours: 1));

  final batteryDrain = batteryMonitor.getBatteryDrain();
  expect(batteryDrain, lessThan(25)); // < 25% per hour
});
```

## Security Testing

### Encryption Validation
```dart
test('Data encryption uses AES-256', () {
  final encryptionService = EncryptionService();

  expect(encryptionService.algorithm, equals('AES-256-GCM'));
  expect(encryptionService.keySize, equals(256));
});
```

### Privacy Compliance Testing
```dart
test('GDPR data export includes all user data', () async {
  final privacyService = PrivacyService();
  final exportedData = await privacyService.exportUserData();

  expect(exportedData, containsKey('room_scans'));
  expect(exportedData, containsKey('privacy_settings'));
  expect(exportedData, containsKey('app_settings'));
});
```

## Continuous Integration

### GitHub Actions Workflow
```yaml
name: Flutter CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Install dependencies
        run: flutter pub get

      - name: Run unit tests
        run: flutter test --coverage

      - name: Run integration tests
        run: flutter test integration_test/

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Test Execution

### Local Development
```bash
# Run all tests with coverage
flutter test --coverage

# Run specific test suites
flutter test test/unit/
flutter test test/widget/
flutter test integration_test/

# Run golden file tests
flutter test --update-goldens
```

### CI/CD Pipeline
```bash
# Production build with tests
flutter build apk --release --test-integration
flutter build ios --release --test-integration

# Performance benchmarks
flutter test --benchmark
```

## Coverage Requirements

| Component | Target Coverage | Rationale |
|-----------|----------------|-----------|
| Sensor Algorithms | 100% | Critical for accuracy |
| Security Components | 100% | Zero tolerance for vulnerabilities |
| UI Components | 80% | Visual consistency important |
| Platform Channels | 90% | Native integration critical |
| Business Logic | 95% | Core functionality reliability |

## Test Maintenance

### Golden File Management
- Update golden files when UI changes are intentional
- Validate across multiple device sizes (phone, tablet)
- Test both light and dark themes

### Mock Data Updates
- Keep sensor mock data aligned with real hardware capabilities
- Update mock responses when platform APIs change
- Maintain test data for various room sizes and configurations

### Continuous Improvement
- Monitor test execution time and optimize slow tests
- Add new test categories when new features are implemented
- Regular review of test coverage and gap analysis

---

**This testing strategy ensures Room-O-Matic Mobile maintains high quality, security, and performance standards while providing fast feedback during development.**
