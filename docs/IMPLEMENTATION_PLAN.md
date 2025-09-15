# Room-O-Matic Mobile: Comprehensive Room Data Collection

## Implementation Plan: Offline-First Mobile Architecture with Optional Server Integration

### Domain-Driven Design for Standalone Mobile Room Mapping

**Core Philosophy**: The app functions as a complete, standalone room measurement tool. Room-O-Matic server integration is optional and enabled only when API credentials are provided.

## 1. Domain Layer - Core Business Logic

### Value Objects (Validation & Business Rules)
```dart
// Domain/ValueObjects/
@freezed
class RoomCoordinates with _$RoomCoordinates {
  const factory RoomCoordinates({
    required double x,
    required double y,
    required double z,
  }) = _RoomCoordinates;

  factory RoomCoordinates.fromRaw(double x, double y, double z) {
    if (x.isNaN || y.isNaN || z.isNaN) {
      throw InvalidCoordinatesException('Coordinates cannot be NaN');
    }
    if (x.abs() > 50 || y.abs() > 50 || z.abs() > 10) {
      throw InvalidCoordinatesException('Coordinates exceed room bounds');
    }
    return RoomCoordinates(x: x, y: y, z: z);
  }
}

@freezed
class DistanceMeasurement with _$DistanceMeasurement {
  const factory DistanceMeasurement({
    required double distance,
    required DistanceSensorType sensorType,
    required double confidence,
    required DateTime timestamp,
  }) = _DistanceMeasurement;

  factory DistanceMeasurement.fromSensor({
    required double rawDistance,
    required DistanceSensorType sensor,
  }) {
    if (rawDistance < 0 || rawDistance > 50) {
      throw InvalidDistanceException('Distance out of valid range');
    }

    final confidence = _calculateConfidence(rawDistance, sensor);
    return DistanceMeasurement(
      distance: rawDistance,
      sensorType: sensor,
      confidence: confidence,
      timestamp: DateTime.now(),
    );
  }
}

enum DistanceSensorType { lidar, tof, sonar, stereoVision, autofocus }
```

### Entities (Core Domain Objects)
```dart
// Domain/Entities/
class RoomScan {
  final RoomScanId id;
  final UserId userId;
  final List<SensorReading> sensorReadings;
  final List<CapturedImage> images;
  final RoomDimensions estimatedDimensions;
  final ScanQuality quality;
  final DateTime createdAt;

  RoomScan._({
    required this.id,
    required this.userId,
    required this.sensorReadings,
    required this.images,
    required this.estimatedDimensions,
    required this.quality,
    required this.createdAt,
  });

  factory RoomScan.create({
    required UserId userId,
    required List<SensorReading> readings,
    required List<CapturedImage> images,
  }) {
    // Domain business rules
    if (readings.length < 10) {
      throw InsufficientDataException('Minimum 10 sensor readings required');
    }

    final dimensions = RoomDimensionCalculator.calculate(readings);
    final quality = ScanQualityAnalyzer.analyze(readings, images);

    return RoomScan._(
      id: RoomScanId.generate(),
      userId: userId,
      sensorReadings: readings,
      images: images,
      estimatedDimensions: dimensions,
      quality: quality,
      createdAt: DateTime.now(),
    );
  }

  // Domain methods
  bool canBeUploadedBy(User user) {
    return user.id == userId && quality.isAcceptable();
  }

  RoomScanData toUploadFormat() {
    return RoomScanData(
      scanId: id.value,
      sensorData: _aggregateSensorData(),
      imageMetadata: _extractImageMetadata(),
      roomMetrics: _calculateRoomMetrics(),
    );
  }
}
```

### Domain Services
```dart
// Domain/Services/
class SensorFusionService {
  static List<DistanceMeasurement> fuseDistanceReadings(
    List<DistanceMeasurement> readings,
  ) {
    // Kalman filter implementation for sensor fusion
    final fusedReadings = <DistanceMeasurement>[];

    for (final direction in ScanDirection.values) {
      final directionReadings = readings
          .where((r) => r.direction == direction)
          .toList();

      if (directionReadings.isNotEmpty) {
        final fused = _kalmanFusion(directionReadings);
        fusedReadings.add(fused);
      }
    }

    return fusedReadings;
  }
}

class RoomGeometryService {
  static RoomDimensions calculateDimensions(
    List<SensorReading> readings,
  ) {
    final wallPoints = _identifyWallPoints(readings);
    final corners = _detectCorners(wallPoints);

    return RoomDimensions.fromCorners(corners);
  }
}
```

## 2. Application Layer - Use Cases & Security

### Offline-First Repository Interfaces
```dart
// Application/Ports/
abstract class RoomScanRepository {
  // Core offline functionality - always available
  Future<Either<RepositoryFailure, RoomScan>> saveRoomScan(
    RoomScan scan,
    AuthenticatedUser user,
  );

  Future<Either<RepositoryFailure, List<RoomScan>>> getUserScans(
    AuthenticatedUser user, {
    int limit = 50,
  });

  Future<Either<RepositoryFailure, Unit>> deleteRoomScan(
    AuthenticatedUser user,
    RoomScanId scanId,
  );

  // Export functionality - always available
  Future<Either<ExportFailure, File>> exportToJson(RoomScan scan);
  Future<Either<ExportFailure, File>> exportToPdf(RoomScan scan);
  Future<Either<ExportFailure, File>> exportToCsv(RoomScan scan);
}

abstract class OptionalUploadRepository {
  // Optional server integration - only when API configured
  Future<bool> isServerConfigured();

  Future<Either<UploadFailure, UploadResult>> uploadRoomScan(
    AuthenticatedUser user,
    RoomScanData scanData,
    List<ImageFile> images,
  );

  Future<Either<SyncFailure, SyncResult>> syncWithServer(
    AuthenticatedUser user,
  );
}

### Command/Query Handlers
```dart
// Application/UseCases/Commands/
class StartRoomScanCommand {
  final UserId userId;
  final ScanConfiguration config;

  const StartRoomScanCommand({
    required this.userId,
    required this.config,
  });
}

class StartRoomScanHandler {
  final SecureRoomScanRepository _repository;
  final SensorPermissionService _permissionService;
  final UserQuotaService _quotaService;

  Future<Either<ScanFailure, RoomScanSession>> handle(
    StartRoomScanCommand command,
  ) async {
    // Security checks first
    final user = await _authenticateUser(command.userId);
    if (user.isLeft()) return Left(ScanFailure.unauthorized());

    // Business rule validation
    final quotaCheck = await _quotaService.checkScanQuota(user.right);
    if (quotaCheck.isExceeded()) {
      return Left(ScanFailure.quotaExceeded());
    }

    // Permission validation
    final permissions = await _permissionService.checkAllPermissions();
    if (!permissions.allGranted()) {
      return Left(ScanFailure.insufficientPermissions());
    }

    // Create scan session
    final session = RoomScanSession.create(
      userId: command.userId,
      configuration: command.config,
    );

    return Right(session);
  }
}
```

## 3. Infrastructure Layer - Sensor Implementations

### Multi-Sensor Data Collection
```dart
// Infrastructure/Sensors/
class ComprehensiveSensorCollector implements SensorDataCollector {
  final LiDARSensorService _lidar;
  final ToFSensorService _tof;
  final SonarMappingService _sonar;
  final CameraService _camera;
  final IMUService _imu;
  final EnvironmentalSensorService _environmental;

  @override
  Future<Either<SensorFailure, ComprehensiveSensorReading>> collectReading(
    ScanDirection direction,
  ) async {
    try {
      // Parallel sensor data collection
      final results = await Future.wait([
        _collectDistanceData(direction),
        _collectVisualData(direction),
        _collectMotionData(),
        _collectEnvironmentalData(),
      ]);

      return Right(ComprehensiveSensorReading(
        distanceReadings: results[0] as List<DistanceMeasurement>,
        visualData: results[1] as VisualData,
        motionData: results[2] as MotionData,
        environmentalData: results[3] as EnvironmentalData,
        timestamp: DateTime.now(),
        direction: direction,
      ));
    } catch (e) {
      return Left(SensorFailure.collectionError(e.toString()));
    }
  }

  Future<List<DistanceMeasurement>> _collectDistanceData(
    ScanDirection direction,
  ) async {
    final readings = <DistanceMeasurement>[];

    // LiDAR (highest accuracy)
    if (await _lidar.isAvailable()) {
      final lidarReading = await _lidar.measureDistance(direction);
      readings.add(DistanceMeasurement.fromSensor(
        rawDistance: lidarReading,
        sensor: DistanceSensorType.lidar,
      ));
    }

    // Time-of-Flight
    if (await _tof.isAvailable()) {
      final tofReading = await _tof.measureDistance(direction);
      readings.add(DistanceMeasurement.fromSensor(
        rawDistance: tofReading,
        sensor: DistanceSensorType.tof,
      ));
    }

    // Custom sonar implementation
    final sonarReading = await _sonar.measureDistance(direction);
    readings.add(DistanceMeasurement.fromSensor(
      rawDistance: sonarReading,
      sensor: DistanceSensorType.sonar,
    ));

    // Stereo vision depth
    final stereoReading = await _camera.measureDepth(direction);
    readings.add(DistanceMeasurement.fromSensor(
      rawDistance: stereoReading,
      sensor: DistanceSensorType.stereoVision,
    ));

    return readings;
  }
}
```

### Secure Upload Service
```dart
// Infrastructure/Upload/
class SecureRoomScanUploadService implements SecureUploadRepository {
  final HttpClient _httpClient;
  final EncryptionService _encryption;
  final AuthTokenService _authService;

  @override
  Future<Either<UploadFailure, UploadResult>> uploadRoomScan(
    AuthenticatedUser user,
    RoomScanData scanData,
    List<ImageFile> images,
  ) async {
    try {
      // Encrypt sensitive data
      final encryptedScanData = await _encryption.encrypt(
        scanData.toJson(),
        user.encryptionKey,
      );

      // Prepare multipart request
      final request = MultipartRequest('POST', _buildUploadUrl());
      request.headers.addAll(await _authService.getAuthHeaders(user));

      // Add encrypted scan data
      request.fields['scan_data'] = encryptedScanData;
      request.fields['user_id'] = user.id.value;
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      // Add images with metadata
      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        request.files.add(await MultipartFile.fromPath(
          'image_$i',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ));

        // Add image metadata
        request.fields['image_${i}_metadata'] = jsonEncode({
          'timestamp': imageFile.timestamp.toIso8601String(),
          'camera_type': imageFile.cameraType.name,
          'exif_data': imageFile.exifData,
        });
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final result = UploadResult.fromJson(jsonDecode(responseBody));
        return Right(result);
      } else {
        return Left(UploadFailure.serverError(response.statusCode));
      }
    } catch (e) {
      return Left(UploadFailure.networkError(e.toString()));
    }
  }
}
```

## 4. JSON Data Structure for Server Upload

### Comprehensive Room Scan Data
```dart
// Domain/DTOs/
@freezed
class RoomScanData with _$RoomScanData {
  const factory RoomScanData({
    required String scanId,
    required String userId,
    required DateTime timestamp,
    required SensorDataCollection sensorData,
    required List<ImageMetadata> imageMetadata,
    required RoomMetrics roomMetrics,
    required DeviceInfo deviceInfo,
    required ScanConfiguration scanConfig,
  }) = _RoomScanData;

  factory RoomScanData.fromJson(Map<String, dynamic> json) =>
      _$RoomScanDataFromJson(json);
}

@freezed
class SensorDataCollection with _$SensorDataCollection {
  const factory SensorDataCollection({
    required List<DistanceReading> distanceReadings,
    required List<MotionReading> motionReadings,
    required List<EnvironmentalReading> environmentalReadings,
    required List<AudioReading> audioReadings,
    required CameraCalibrationData cameraCalibration,
  }) = _SensorDataCollection;
}

@freezed
class DistanceReading with _$DistanceReading {
  const factory DistanceReading({
    required double distance,
    required String sensorType, // 'lidar', 'tof', 'sonar', 'stereo', 'autofocus'
    required double confidence,
    required DateTime timestamp,
    required DirectionVector direction,
    required DeviceOrientation deviceOrientation,
  }) = _DistanceReading;
}

@freezed
class MotionReading with _$MotionReading {
  const factory MotionReading({
    required Vector3 acceleration,
    required Vector3 gyroscope,
    required Vector3 magnetometer,
    required double barometricPressure,
    required DateTime timestamp,
  }) = _MotionReading;
}

@freezed
class EnvironmentalReading with _$EnvironmentalReading {
  const factory EnvironmentalReading({
    required double ambientLight, // lux
    required double proximity, // cm
    required double temperature, // celsius
    required double humidity, // percentage
    required DateTime timestamp,
  }) = _EnvironmentalReading;
}

@freezed
class AudioReading with _$AudioReading {
  const factory AudioReading({
    required String sonarChirpType, // 'linear', 'logarithmic', 'stepped'
    required double frequency, // Hz
    required double amplitude,
    required double echoDelay, // milliseconds
    required double signalToNoise,
    required DateTime timestamp,
  }) = _AudioReading;
}
```

## 5. Interface Layer - UI & Controllers

### Offline-First UI Controllers
```dart
// Interface/Controllers/
class RoomScanController extends StateNotifier<RoomScanState> {
  final StartRoomScanHandler _startScanHandler;
  final CompleteScanHandler _completeScanHandler;
  final OptionalUploadHandler _uploadHandler;
  final ExportHandler _exportHandler;
  final ConfigurationService _configService;

  RoomScanController(
    this._startScanHandler,
    this._completeScanHandler,
    this._uploadHandler,
    this._exportHandler,
    this._configService,
  ) : super(const RoomScanState.idle());

  Future<void> startScan(ScanConfiguration config) async {
    state = const RoomScanState.starting();

    final command = StartRoomScanCommand(
      userId: UserId.current(), // From local auth context
      config: config,
    );

    final result = await _startScanHandler.handle(command);

    result.fold(
      (failure) => state = RoomScanState.error(failure.message),
      (session) => state = RoomScanState.scanning(session),
    );
  }

  // Core functionality - always available
  Future<void> completeScan() async {
    if (state is! RoomScanScanning) return;

    state = const RoomScanState.processing();
    // Process and save scan locally
    final result = await _completeScanHandler.handle(...);

    result.fold(
      (failure) => state = RoomScanState.error(failure.message),
      (scan) => state = RoomScanState.completed(scan),
    );
  }

  // Export functionality - always available
  Future<void> exportScan(ExportFormat format) async {
    if (state is! RoomScanCompleted) return;

    state = const RoomScanState.exporting();
    final scanState = state as RoomScanCompleted;

    final result = await _exportHandler.exportScan(scanState.scan, format);

    result.fold(
      (failure) => state = RoomScanState.exportError(failure.message),
      (file) => state = RoomScanState.exported(file),
    );
  }

  // Optional upload - only if server configured
  Future<void> uploadScan() async {
    if (state is! RoomScanCompleted) return;

    // Check if server integration is configured
    final isConfigured = await _configService.isServerConfigured();
    if (!isConfigured) {
      state = const RoomScanState.uploadNotAvailable(
        'Room-O-Matic server integration not configured. Use export instead.',
      );
      return;
    }

    state = const RoomScanState.uploading();

    final scanState = state as RoomScanCompleted;
    final uploadCommand = UploadRoomScanCommand(
      scanData: scanState.scanData,
      images: scanState.images,
    );

    final result = await _uploadHandler.handle(uploadCommand);

    result.fold(
      (failure) => state = RoomScanState.uploadError(failure.message),
      (success) => state = RoomScanState.uploaded(success),
    );
  }

  // Server sync - optional functionality
  Future<void> syncWithServer() async {
    final isConfigured = await _configService.isServerConfigured();
    if (!isConfigured) {
      state = const RoomScanState.syncNotAvailable(
        'Room-O-Matic server integration not configured.',
      );
      return;
    }

    state = const RoomScanState.syncing();

    final result = await _uploadHandler.syncWithServer();

    result.fold(
      (failure) => state = RoomScanState.syncError(failure.message),
      (success) => state = RoomScanState.synced(success),
    );
  }
}
```

## 6. Project Structure

```
lib/
├── domain/
│   ├── entities/
│   │   ├── room_scan.dart
│   │   ├── sensor_reading.dart
│   │   └── user.dart
│   ├── value_objects/
│   │   ├── coordinates.dart
│   │   ├── distance_measurement.dart
│   │   └── scan_id.dart
│   ├── services/
│   │   ├── sensor_fusion_service.dart
│   │   └── room_geometry_service.dart
│   └── exceptions/
│       └── domain_exceptions.dart
├── application/
│   ├── ports/
│   │   ├── room_scan_repository.dart
│   │   ├── optional_upload_repository.dart
│   │   └── export_repository.dart
│   ├── use_cases/
│   │   ├── commands/
│   │   │   ├── start_room_scan_command.dart
│   │   │   ├── upload_scan_command.dart
│   │   │   └── export_scan_command.dart
│   │   └── queries/
│   │       └── get_user_scans_query.dart
│   └── services/
│       ├── user_quota_service.dart
│       ├── permission_service.dart
│       └── configuration_service.dart
├── infrastructure/
│   ├── sensors/
│   │   ├── lidar_service.dart
│   │   ├── sonar_service.dart
│   │   ├── camera_service.dart
│   │   └── sensor_collector.dart
│   ├── repositories/
│   │   └── room_scan_repository_impl.dart
│   ├── upload/
│   │   └── optional_upload_service.dart
│   ├── export/
│   │   ├── json_export_service.dart
│   │   ├── pdf_export_service.dart
│   │   └── csv_export_service.dart
│   ├── storage/
│   │   └── local_storage_service.dart
│   └── config/
│       └── configuration_service_impl.dart
└── interface/
    ├── controllers/
    │   └── room_scan_controller.dart
    ├── screens/
    │   ├── scan_screen.dart
    │   ├── scan_results_screen.dart
    │   ├── export_screen.dart
    │   └── settings_screen.dart
    └── widgets/
        ├── sensor_visualization.dart
        ├── scan_progress_indicator.dart
        ├── export_options.dart
        └── server_configuration.dart

# Platform-Specific Native Code
src/
├── iOS/
│   ├── Core/
│   │   ├── IOSSensorChannelHandler.swift
│   │   ├── SecurityChannelHandler.swift
│   │   └── PlatformChannelManager.swift
│   ├── Sensors/
│   │   ├── ARKitService.swift
│   │   ├── LiDARService.swift
│   │   ├── LocationService.swift
│   │   ├── SonarService.swift
│   │   └── MotionSensorService.swift
│   ├── Camera/
│   │   ├── CameraService.swift
│   │   ├── ARCameraController.swift
│   │   └── DepthDataProcessor.swift
│   ├── Security/
│   │   ├── BiometricService.swift
│   │   ├── KeychainService.swift
│   │   └── EncryptionService.swift
│   ├── Utils/
│   │   ├── DeviceCapabilities.swift
│   │   ├── PermissionManager.swift
│   │   └── ErrorHandler.swift
│   └── Tests/
│       ├── SensorTests.swift
│       ├── SecurityTests.swift
│       └── IntegrationTests.swift
└── android/
    ├── core/
    │   ├── SensorChannelHandler.kt
    │   ├── SecurityChannelHandler.kt
    │   └── PlatformChannelManager.kt
    ├── sensors/
    │   ├── LiDARSensorService.kt
    │   ├── ToFSensorService.kt
    │   ├── SonarService.kt
    │   ├── CameraSensorService.kt
    │   └── MotionSensorService.kt
    ├── camera/
    │   ├── CameraXService.kt
    │   ├── ImageProcessor.kt
    │   └── DepthEstimator.kt
    ├── security/
    │   ├── BiometricManager.kt
    │   ├── SecureStorage.kt
    │   └── EncryptionHelper.kt
    ├── utils/
    │   ├── DeviceCapabilities.kt
    │   ├── PermissionHelper.kt
    │   └── ErrorHandler.kt
    └── tests/
        ├── SensorServiceTests.kt
        ├── SecurityTests.kt
        └── IntegrationTests.kt

# Configuration Files
ios/
├── Runner/
│   ├── Runner.xcodeproj
│   ├── Info.plist
│   ├── Runner.entitlements
│   └── AppDelegate.swift
├── Podfile
└── Podfile.lock

android/
├── app/
│   ├── build.gradle
│   ├── src/main/
│   │   ├── AndroidManifest.xml
│   │   ├── kotlin/com/roomomatic/mobile/
│   │   │   └── MainActivity.kt
│   │   └── res/
│   └── proguard-rules.pro
├── build.gradle
└── gradle.properties

# Documentation and Guides
docs/
├── ANDROID_FLUTTER_DEVELOPMENT_GUIDE.md
├── IOS_FLUTTER_DEVELOPMENT_GUIDE.md
├── PLATFORM_INTEGRATION_GUIDE.md
├── IMPLEMENTATION_PLAN.md
├── API_DOCUMENTATION.md
├── TESTING_STRATEGY.md
└── goat/
    ├── QUICK_REFERENCE_CARD.md
    ├── HELPFUL_PROMPTS.md
    └── CUSTOMIZATION_GUIDES.md
```

## 7. Platform-Specific Implementation Architecture

### iOS Implementation (`src/iOS/`)

#### Core Platform Integration
- **IOSSensorChannelHandler.swift**: Main platform channel handler for iOS sensor integration
- **SecurityChannelHandler.swift**: iOS-specific security and biometric authentication
- **PlatformChannelManager.swift**: Centralized platform channel management

#### Sensor Services
- **ARKitService.swift**: ARKit integration for LiDAR and spatial mapping
- **LiDARService.swift**: Direct LiDAR sensor access and point cloud processing
- **LocationService.swift**: Core Location framework integration
- **SonarService.swift**: Audio-based sonar implementation using AVFoundation
- **MotionSensorService.swift**: Core Motion sensor fusion (accelerometer, gyroscope, magnetometer)

#### Camera & Visual Processing
- **CameraService.swift**: AVFoundation camera integration with depth data
- **ARCameraController.swift**: AR camera session management
- **DepthDataProcessor.swift**: Real-time depth data processing for distance measurement

#### Security Implementation
- **BiometricService.swift**: TouchID, FaceID, and OpticID authentication
- **KeychainService.swift**: Secure storage using iOS Keychain services
- **EncryptionService.swift**: CryptoKit integration for data encryption

### Android Implementation (`src/android/`)

#### Core Platform Integration
- **SensorChannelHandler.kt**: Main platform channel handler for Android sensors
- **SecurityChannelHandler.kt**: Android-specific security and biometric authentication
- **PlatformChannelManager.kt**: Centralized platform channel management

#### Sensor Services
- **LiDARSensorService.kt**: ToF/LiDAR sensor integration for supported devices
- **ToFSensorService.kt**: Time-of-Flight sensor implementation
- **SonarService.kt**: Audio-based sonar using Android AudioManager
- **CameraSensorService.kt**: Camera2 API integration for depth estimation
- **MotionSensorService.kt**: SensorManager integration for IMU data

#### Camera & Visual Processing
- **CameraXService.kt**: CameraX integration for modern camera handling
- **ImageProcessor.kt**: Real-time image processing for feature detection
- **DepthEstimator.kt**: Stereo vision and ML-based depth estimation

#### Security Implementation
- **BiometricManager.kt**: BiometricPrompt API for fingerprint/face authentication
- **SecureStorage.kt**: EncryptedSharedPreferences for secure data storage
- **EncryptionHelper.kt**: AES encryption for sensitive data

### Platform Channel Communication Architecture

```dart
// Cross-platform interface in lib/
abstract class SensorPlatform {
  Future<List<DistanceMeasurement>> getDistanceReadings();
  Future<MotionData> getMotionData();
  Future<LocationData> getCurrentLocation();
  Future<bool> startARSession();
}

// iOS implementation in src/iOS/
class IOSSensorPlatform implements SensorPlatform {
  static const MethodChannel _channel = MethodChannel('com.roomomatic.ios.sensors');

  @override
  Future<List<DistanceMeasurement>> getDistanceReadings() async {
    final result = await _channel.invokeMethod('getDistanceReadings');
    return (result as List).map((e) => DistanceMeasurement.fromJson(e)).toList();
  }
}

// Android implementation in src/android/
class AndroidSensorPlatform implements SensorPlatform {
  static const MethodChannel _channel = MethodChannel('com.roomomatic.android.sensors');

  @override
  Future<List<DistanceMeasurement>> getDistanceReadings() async {
    final result = await _channel.invokeMethod('getDistanceReadings');
    return (result as List).map((e) => DistanceMeasurement.fromJson(e)).toList();
  }
}
```

### Testing Structure

#### iOS Tests (`src/iOS/Tests/`)
- **SensorTests.swift**: Unit tests for all iOS sensor services
- **SecurityTests.swift**: Security and encryption testing
- **IntegrationTests.swift**: Platform channel integration tests

#### Android Tests (`src/android/tests/`)
- **SensorServiceTests.kt**: Unit tests for Android sensor implementations
- **SecurityTests.kt**: Biometric and encryption testing
- **IntegrationTests.kt**: Platform channel integration tests

### Build Configuration

#### iOS Configuration (`ios/`)
- **Podfile**: CocoaPods dependencies for ARKit, Core Location, etc.
- **Info.plist**: Permissions and capabilities configuration
- **Runner.entitlements**: App entitlements for advanced features

#### Android Configuration (`android/`)
- **build.gradle**: Gradle dependencies and build configuration
- **AndroidManifest.xml**: Permissions and hardware requirements
- **proguard-rules.pro**: Code obfuscation rules for release builds

This architecture ensures:
1. **Clean separation** between platforms while sharing business logic
2. **Native performance** for sensor-intensive operations
3. **Secure implementation** with platform-specific security features
4. **Maintainable code** with clear boundaries and responsibilities
5. **Comprehensive testing** at both unit and integration levels

## 8. Configuration & Export Services

### Configuration Service - Server Integration Management
```dart
// Application/Services/
abstract class ConfigurationService {
  Future<bool> isServerConfigured();
  Future<String?> getApiKey();
  Future<String?> getServerUrl();
  Future<void> setServerConfiguration(String apiKey, String serverUrl);
  Future<void> clearServerConfiguration();
  Future<bool> validateServerConnection();
}

// Infrastructure/Config/
class ConfigurationServiceImpl implements ConfigurationService {
  final SecureStorage _secureStorage;
  final HttpClient _httpClient;

  @override
  Future<bool> isServerConfigured() async {
    final apiKey = await getApiKey();
    final serverUrl = await getServerUrl();
    return apiKey != null && serverUrl != null;
  }

  @override
  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: 'roomomatic_api_key');
  }

  @override
  Future<String?> getServerUrl() async {
    return await _secureStorage.read(key: 'roomomatic_server_url');
  }

  @override
  Future<void> setServerConfiguration(String apiKey, String serverUrl) async {
    await _secureStorage.write(key: 'roomomatic_api_key', value: apiKey);
    await _secureStorage.write(key: 'roomomatic_server_url', value: serverUrl);
  }

  @override
  Future<void> clearServerConfiguration() async {
    await _secureStorage.delete(key: 'roomomatic_api_key');
    await _secureStorage.delete(key: 'roomomatic_server_url');
  }

  @override
  Future<bool> validateServerConnection() async {
    if (!await isServerConfigured()) return false;

    try {
      final serverUrl = await getServerUrl();
      final apiKey = await getApiKey();

      final response = await _httpClient.get(
        Uri.parse('$serverUrl/api/health'),
        headers: {'X-API-Key': apiKey!},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
```

### Export Services - Always Available Functionality
```dart
// Application/Ports/
abstract class ExportRepository {
  Future<Either<ExportFailure, File>> exportToJson(RoomScan scan);
  Future<Either<ExportFailure, File>> exportToPdf(RoomScan scan);
  Future<Either<ExportFailure, File>> exportToCsv(RoomScan scan);
  Future<Either<ExportFailure, List<File>>> exportAll(List<RoomScan> scans, ExportFormat format);
}

enum ExportFormat { json, pdf, csv, all }

// Infrastructure/Export/
class JsonExportService implements ExportRepository {
  final FileService _fileService;

  @override
  Future<Either<ExportFailure, File>> exportToJson(RoomScan scan) async {
    try {
      final exportData = RoomScanExportData.fromScan(scan);
      final jsonString = jsonEncode(exportData.toJson());

      final fileName = 'room_scan_${scan.id}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = await _fileService.writeToDocuments(fileName, jsonString);

      return Right(file);
    } catch (e) {
      return Left(ExportFailure.fileError(e.toString()));
    }
  }
}

class PdfExportService implements ExportRepository {
  final PdfGenerator _pdfGenerator;
  final FileService _fileService;

  @override
  Future<Either<ExportFailure, File>> exportToPdf(RoomScan scan) async {
    try {
      final pdfDocument = await _pdfGenerator.generateRoomScanReport(scan);

      final fileName = 'room_scan_report_${scan.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final bytes = await pdfDocument.save();
      final file = await _fileService.writeBytesToDocuments(fileName, bytes);

      return Right(file);
    } catch (e) {
      return Left(ExportFailure.generationError(e.toString()));
    }
  }
}

class CsvExportService implements ExportRepository {
  final FileService _fileService;

  @override
  Future<Either<ExportFailure, File>> exportToCsv(RoomScan scan) async {
    try {
      final csvData = _generateCsvData(scan);

      final fileName = 'room_scan_data_${scan.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = await _fileService.writeToDocuments(fileName, csvData);

      return Right(file);
    } catch (e) {
      return Left(ExportFailure.formatError(e.toString()));
    }
  }

  String _generateCsvData(RoomScan scan) {
    final buffer = StringBuffer();

    // Headers
    buffer.writeln('timestamp,sensor_type,distance_m,confidence,direction_x,direction_y,direction_z');

    // Data rows
    for (final reading in scan.sensorReadings) {
      buffer.writeln([
        reading.timestamp.toIso8601String(),
        reading.sensorType.name,
        reading.distance.toStringAsFixed(3),
        reading.confidence.toStringAsFixed(3),
        reading.direction.x.toStringAsFixed(3),
        reading.direction.y.toStringAsFixed(3),
        reading.direction.z.toStringAsFixed(3),
      ].join(','));
    }

    return buffer.toString();
  }
}
```

### UI Components for Configuration and Export
```dart
// Interface/Widgets/
class ServerConfigurationWidget extends StatefulWidget {
  @override
  _ServerConfigurationWidgetState createState() => _ServerConfigurationWidgetState();
}

class _ServerConfigurationWidgetState extends State<ServerConfigurationWidget> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _serverUrlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Room-O-Matic Server Integration (Optional)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(
                'Configure server integration to sync data with Room-O-Matic platform. The app works fully offline without this configuration.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _serverUrlController,
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://api.roomomatic.com',
                  prefixIcon: Icon(Icons.cloud),
                ),
                validator: (value) {
                  if (value?.isNotEmpty == true && !Uri.tryParse(value!)?.hasAbsolutePath == true) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Your Room-O-Matic API key',
                  prefixIcon: Icon(Icons.key),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveConfiguration,
                    child: Text('Save Configuration'),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: _testConnection,
                    child: Text('Test Connection'),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: _clearConfiguration,
                    child: Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveConfiguration() async {
    if (_formKey.currentState?.validate() == true) {
      final configService = context.read<ConfigurationService>();
      await configService.setServerConfiguration(
        _apiKeyController.text,
        _serverUrlController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuration saved')),
      );
    }
  }

  void _testConnection() async {
    final configService = context.read<ConfigurationService>();
    final isValid = await configService.validateServerConnection();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isValid ? 'Connection successful' : 'Connection failed'),
        backgroundColor: isValid ? Colors.green : Colors.red,
      ),
    );
  }

  void _clearConfiguration() async {
    final configService = context.read<ConfigurationService>();
    await configService.clearServerConfiguration();
    _apiKeyController.clear();
    _serverUrlController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configuration cleared')),
    );
  }
}

class ExportOptionsWidget extends StatelessWidget {
  final RoomScan scan;

  const ExportOptionsWidget({Key? key, required this.scan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Scan Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 3,
              children: [
                _ExportButton(
                  icon: Icons.code,
                  label: 'JSON Data',
                  onPressed: () => _exportAs(context, ExportFormat.json),
                ),
                _ExportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF Report',
                  onPressed: () => _exportAs(context, ExportFormat.pdf),
                ),
                _ExportButton(
                  icon: Icons.table_chart,
                  label: 'CSV Data',
                  onPressed: () => _exportAs(context, ExportFormat.csv),
                ),
                _ExportButton(
                  icon: Icons.share,
                  label: 'Share All',
                  onPressed: () => _shareData(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _exportAs(BuildContext context, ExportFormat format) async {
    final exportService = context.read<ExportRepository>();

    final result = switch (format) {
      ExportFormat.json => await exportService.exportToJson(scan),
      ExportFormat.pdf => await exportService.exportToPdf(scan),
      ExportFormat.csv => await exportService.exportToCsv(scan),
      _ => throw UnimplementedError(),
    };

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${failure.message}')),
      ),
      (file) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${file.path}')),
      ),
    );
  }

  void _shareData(BuildContext context) {
    // Implement sharing functionality
    Share.shareFiles([/* export files */], text: 'Room scan data');
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
```

## 9. Security Implementation

### Authentication & Authorization
```dart
class SecureAuthContext {
  static AuthenticatedUser? _currentUser;

  static Future<Either<AuthFailure, AuthenticatedUser>> authenticate() async {
    // Biometric authentication
    final biometricResult = await _biometricAuth.authenticate();
    if (biometricResult.isFailure()) {
      return Left(AuthFailure.biometricFailed());
    }

    // Token validation
    final tokenResult = await _validateAuthToken();
    if (tokenResult.isFailure()) {
      return Left(AuthFailure.tokenInvalid());
    }

    _currentUser = AuthenticatedUser.fromToken(tokenResult.token);
    return Right(_currentUser!);
  }

  static AuthenticatedUser requireUser() {
    if (_currentUser == null) {
      throw UnauthorizedException('User not authenticated');
    }
    return _currentUser!;
  }
}
```

## 9. Flutter Dependencies

### pubspec.yaml
```yaml
name: room_o_matic_mobile
description: Comprehensive room data collection app for Room-O-Matic platform

dependencies:
  flutter: ^3.16.0

  # State Management & Architecture
  riverpod: ^2.4.9
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  dartz: ^0.10.1

  # Sensors & Hardware
  sensors_plus: ^4.0.2
  camera: ^0.10.5
  flutter_sound: ^9.2.13
  permission_handler: ^11.0.1

  # Image Processing
  image: ^4.1.3
  exif: ^3.3.0

  # Networking & Upload
  dio: ^5.3.2
  http: ^1.1.0

  # Security
  local_auth: ^2.1.6
  crypto: ^3.0.3

  # Storage
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1

  # UI & Visualization - AR Camera Overlays
  flutter_cube: ^0.1.1
  fl_chart: ^0.64.0
  vector_math: ^2.1.4  # For 3D transformations
  flutter_compass: ^0.7.0  # Device orientation

  # Real-time processing
  stream_transform: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1

  # Testing
  mockito: ^5.4.2
  integration_test:
    sdk: flutter
```

## 10. Comprehensive AR Camera System

### Real-Time Sonar Visualization Types
```dart
// Interface/Widgets/Overlays/
enum VisualizationMode {
  sonarRays,        // Radiating lines from center
  heatMap,          // Color-coded distance zones
  pointCloud,       // 3D points in space
  roomOutline,      // Detected wall boundaries
  measurements,     // Distance annotations
}

class ARVisualizationController {
  VisualizationMode currentMode = VisualizationMode.sonarRays;
  bool showDistanceLabels = true;
  bool showScanAnimation = true;
  double overlayOpacity = 0.7;

  void cycleVisualizationMode() {
    final modes = VisualizationMode.values;
    final currentIndex = modes.indexOf(currentMode);
    currentMode = modes[(currentIndex + 1) % modes.length];
  }
}
```

### Enhanced Camera Integration
```dart
// Infrastructure/Camera/
class ARCameraService {
  late CameraController _controller;
  late StreamSubscription<CameraImage> _imageStream;

  Future<void> initializeARCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // For real-time processing
    );

    await _controller.initialize();

    // Start real-time image analysis
    await _controller.startImageStream(_processImageForAR);
  }

  void _processImageForAR(CameraImage image) {
    // Real-time image processing for:
    // - Feature detection
    // - Edge detection for wall finding
    // - Lighting analysis
    // - Motion blur detection
  }

  Future<void> captureFrameWithSensorData(SonarOverlayState overlayData) async {
    final image = await _controller.takePicture();

    // Combine image with current sensor readings
    final frameCapture = FrameCapture(
      image: image,
      sensorData: overlayData,
      timestamp: DateTime.now(),
      cameraSettings: _controller.value,
    );

    // Store for later upload
    await _storeCapturedFrame(frameCapture);
  }
}
```

### Interactive AR Gestures
```dart
// Interface/Widgets/
class ARGestureDetector extends StatelessWidget {
  final Widget child;
  final Function(Offset) onTapPosition;
  final Function(double) onPinchZoom;
  final Function(Offset) onPanUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) => onTapPosition(details.localPosition),
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          onPinchZoom(details.scale);
        } else {
          onPanUpdate(details.focalPointDelta);
        }
      },
      child: child,
    );
  }
}

// Usage in main screen
ARGestureDetector(
  onTapPosition: (position) {
    // Measure distance to tapped point
    _measureDistanceAt(position);
  },
  onPinchZoom: (scale) {
    // Zoom overlay visualization
    _updateOverlayZoom(scale);
  },
  onPanUpdate: (delta) {
    // Pan around room visualization
    _updateOverlayPan(delta);
  },
  child: ARScanningScreen(),
)
```

### Visual Accuracy & Projection System
```dart
// Simplified projection system for visual feedback
class ARProjectionService {
  // Convert real-world measurements to screen visualization
  Offset projectDistanceToScreen(
    DistanceReading reading,
    Size screenSize,
    CameraParameters cameraParams,
  ) {
    // Approximate field-of-view mapping
    final fovRadians = cameraParams.fieldOfView * (math.pi / 180);
    final pixelsPerMeter = screenSize.width / (2 * reading.distance * math.tan(fovRadians / 2));

    // Convert sensor direction to screen coordinates
    final screenX = (reading.direction.x * pixelsPerMeter) + screenSize.width / 2;
    final screenY = (-reading.direction.y * pixelsPerMeter) + screenSize.height / 2;

    return Offset(screenX, screenY);
  }
}
```

### AR Interaction Modes

#### Point & Measure Mode
```dart
class PointMeasureMode extends ARInteractionMode {
  void onScreenTap(Offset screenPosition) {
    // Convert screen tap to world ray
    final worldRay = _screenToWorldRay(screenPosition);

    // Trigger targeted sensor reading
    _triggerDirectionalScan(worldRay.direction);

    // Show measurement popup
    _showMeasurementAt(screenPosition);
  }
}
```

#### Room Scanning Mode
```dart
class RoomScanningMode extends ARInteractionMode {
  void startAutoScan() {
    // Systematic 360° scanning
    _startRadialScan();

    // Show scanning progress overlay
    _showScanningProgress();
  }
}
```

#### Manual Measurement Mode
```dart
class ManualMeasurementMode extends ARInteractionMode {
  Offset? _startPoint;

  void onPanStart(Offset position) {
    _startPoint = position;
  }

  void onPanUpdate(Offset position) {
    if (_startPoint != null) {
      // Draw measurement line in real-time
      _drawMeasurementLine(_startPoint!, position);
    }
  }
}
```

### Performance Optimizations

#### Frame Rate Management
```dart
class ARRenderingController {
  static const int targetFPS = 30;
  static const Duration frameInterval = Duration(milliseconds: 33);

  Timer? _renderTimer;
  bool _isRendering = false;

  void startRendering() {
    _renderTimer = Timer.periodic(frameInterval, (_) {
      if (!_isRendering) {
        _isRendering = true;
        _renderFrame();
        _isRendering = false;
      }
    });
  }

  void _renderFrame() {
    // Only update overlay if sensor data has changed
    if (_sensorDataChanged) {
      _updateOverlayPainter();
      _sensorDataChanged = false;
    }
  }
}
```

#### Sensor Data Filtering
```dart
class SensorDataFilter {
  static List<DistanceReading> filterForDisplay(
    List<DistanceReading> rawReadings,
  ) {
    return rawReadings
        .where((reading) => reading.confidence > 0.3) // Filter low confidence
        .where((reading) => reading.distance < 10.0)  // Filter extreme distances
        .where((reading) => reading.distance > 0.1)   // Filter too close readings
        .take(20) // Limit for performance
        .toList();
  }
}
```

### Calibration & Accuracy Features

#### Device-Specific Calibration
```dart
class ARCalibrationService {
  static Future<CalibrationData> calibrateDevice() async {
    final deviceModel = await _getDeviceModel();

    // Load device-specific calibration or create new
    var calibration = await _loadCalibration(deviceModel);
    calibration ??= await _performCalibration();

    return calibration;
  }

  static Future<CalibrationData> _performCalibration() async {
    // Guide user through calibration process
    return CalibrationWizard.run();
  }
}
```

#### Real-Time Accuracy Feedback
```dart
class AccuracyIndicator extends StatelessWidget {
  final ScanQuality quality;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getQualityColor(quality),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getQualityIcon(quality), color: Colors.white),
          SizedBox(width: 4),
          Text(
            quality.description,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(ScanQuality quality) {
    switch (quality.level) {
      case QualityLevel.excellent: return Colors.green;
      case QualityLevel.good: return Colors.orange;
      case QualityLevel.poor: return Colors.red;
    }
  }
}
```

### Advanced AR Features

#### Object Recognition Integration
```dart
class ARObjectDetection {
  Future<List<DetectedObject>> detectObjects(CameraImage image) async {
    // Use TensorFlow Lite or ML Kit for real-time object detection
    final results = await _mlModel.processImage(image);

    return results.map((result) => DetectedObject(
      label: result.label,
      confidence: result.confidence,
      boundingBox: result.boundingBox,
    )).toList();
  }
}
```

#### Furniture Placement Preview
```dart
class FurniturePlacementOverlay extends StatelessWidget {
  final List<VirtualFurniture> furniture;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FurniturePainter(furniture),
      size: Size.infinite,
    );
  }
}

class VirtualFurniture {
  final String name;
  final RoomCoordinates position;
  final Dimensions size;
  final Color color;
  final double opacity;

  // Render as simple 3D wireframe or textured model
}
```

## Complete AR User Flow

1. **App Launch** → Biometric authentication → Camera permission request
2. **Live Camera View** → Real-time sonar overlay appears immediately
3. **Tap to Start Scanning** → Animated scanning begins with visual feedback
4. **360° Room Scan** → User rotates phone, distance rays update in real-time
5. **Tap for Spot Measurements** → Point at objects for instant distance readings
6. **Room Outline Detection** → Walls and corners highlighted automatically
7. **Quality Assessment** → Real-time feedback on scan completeness
8. **Upload Preview** → Show captured data before sending to server

### Key AR Camera Features Summary

#### Real-Time Visual Overlays:
- **Sonar rays** radiating from center showing distance measurements
- **Animated scanning** with rotating scan lines and pulsing circles
- **Distance labels** floating over detected objects
- **Room outline detection** showing walls and corners in real-time
- **Confidence indicators** with color-coded accuracy levels

#### Interactive AR Interface:
- **Full-screen camera view** with floating controls
- **Tap-to-measure** functionality - tap anywhere to get distance
- **Pinch-to-zoom** overlay visualization
- **Multiple visualization modes** (sonar rays, heat map, point cloud, room outline)
- **Real-time status display** showing room dimensions and scan quality

#### Smart Visual Feedback:
- **Cross-hair targeting** in center of screen
- **Progress indicators** for scanning completion
- **Sensor status indicators** showing which sensors are active
- **Live measurement display** with room dimensions updating in real-time

#### Technical Implementation:
- **Custom Canvas Painting** for smooth, performant overlays
- **Real-time sensor fusion** updating at 10Hz (100ms intervals)
- **Stream-based architecture** for responsive UI updates
- **Gesture detection** for interactive measurements
- **Camera frame synchronization** with sensor data timestamps

#### Visual Accuracy Considerations:
The overlay system is designed to be **visually intuitive** rather than perfectly accurate, providing immediate feedback that makes the scanning process feel like using a high-tech measurement tool rather than a complex technical application.

## 11. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- Set up project structure with Clean Architecture
- Implement domain layer with value objects and entities
- Create security-first repository interfaces
- Basic authentication and authorization

### Phase 2: Sensor Integration (Weeks 3-5)
- Implement individual sensor services (LiDAR, ToF, Camera, etc.)
- Build comprehensive sensor collector
- Create sensor fusion algorithms
- Add permission handling

### Phase 3: Data Processing (Weeks 6-7)
- Implement room geometry calculation
- Build scan quality analysis
- Create JSON serialization for upload
- Add local storage capabilities

### Phase 4: Upload & Security (Weeks 8-9)
- Implement secure upload service with encryption
- Add retry mechanisms and error handling
- Create upload progress tracking
- Implement quota management

### Phase 5: UI & UX (Weeks 10-11)
- Build scanning interface with real-time feedback
- Create AR overlay for distance visualization
- Add scan results and history screens
- Implement settings and calibration

### Phase 6: Testing & Polish (Weeks 12-13)
- Comprehensive unit and integration testing
- Performance optimization
- Security audit and penetration testing
- Final UI/UX polish and accessibility

## 12. Key Success Metrics

- **Accuracy**: Distance measurements within 2cm for LiDAR, 5cm for fused sensors
- **Performance**: Complete room scan in under 60 seconds
- **Security**: Zero authentication bypasses, encrypted data transmission
- **Reliability**: 99.5% upload success rate with retry mechanisms
- **User Experience**: One-tap scanning with intuitive AR feedback

This implementation plan ensures that Room-O-Matic Mobile will collect the most comprehensive room data possible while maintaining the highest security and architectural standards.
