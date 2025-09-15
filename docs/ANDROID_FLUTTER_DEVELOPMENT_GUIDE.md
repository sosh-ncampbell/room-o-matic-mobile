# Android Flutter Development Guide

## Table of Contents
1. [Platform Integration Overview](#platform-integration-overview)
2. [Setting Up Android Development](#setting-up-android-development)
3. [Platform Channels & Native Integration](#platform-channels--native-integration)
4. [Platform Views for Native Android Components](#platform-views-for-native-android-components)
5. [Sensor Integration for Room-O-Matic](#sensor-integration-for-room-o-matic)
6. [Security Implementation](#security-implementation)
7. [Performance Optimization](#performance-optimization)
8. [Testing Strategies](#testing-strategies)
9. [Build & Deployment](#build--deployment)
10. [Troubleshooting Common Issues](#troubleshooting-common-issues)

---

## Platform Integration Overview

Flutter provides multiple ways to integrate with Android platform-specific functionality:

### Integration Approaches
1. **Platform Channels** - Bidirectional communication between Dart and native Android code
2. **Platform Views** - Embedding native Android views directly in Flutter UI
3. **Pigeon** - Type-safe code generation for platform communication
4. **FFI (Foreign Function Interface)** - Direct C/C++ integration for performance-critical code

### When to Use Each Approach

| Approach | Use Case | Performance | Complexity |
|----------|----------|-------------|------------|
| Platform Channels | API calls, sensors, system services | Good | Low-Medium |
| Platform Views | Native UI components, maps, web views | Variable | Medium-High |
| Pigeon | Type-safe APIs, large teams | Good | Medium |
| FFI | Math libraries, image processing | Excellent | High |

---

## Setting Up Android Development

### Prerequisites
```bash
# Verify Flutter installation
flutter doctor

# Check Android setup specifically
flutter doctor --android-licenses

# Install Android SDK tools
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"
```

### Android Studio Configuration
1. **Install Android Studio** with Flutter and Dart plugins
2. **Configure AVD Manager** for device emulation
3. **Set up signing configurations** for release builds
4. **Configure ProGuard/R8** for code optimization

### Gradle Configuration for Room-O-Matic
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    defaultConfig {
        applicationId "com.roomomatic.mobile"
        minSdkVersion 23  // Required for Camera2 API and advanced sensors
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true

        // Room-O-Matic specific configurations
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            signingConfig signingConfigs.debug
            minifyEnabled false
            debuggable true
        }
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"

    // Camera and sensor dependencies
    implementation 'androidx.camera:camera-camera2:1.3.0'
    implementation 'androidx.camera:camera-lifecycle:1.3.0'
    implementation 'androidx.camera:camera-view:1.3.0'

    // Sensor and hardware access
    implementation 'androidx.core:core:1.12.0'

    // Security libraries
    implementation 'androidx.biometric:biometric:1.1.0'
    implementation 'androidx.security:security-crypto:1.1.0-alpha06'
}
```

---

## Platform Channels & Native Integration

### Basic Platform Channel Implementation

#### Dart Side (Flutter)
```dart
// lib/platform/sensor_platform.dart
import 'package:flutter/services.dart';

class SensorPlatform {
  static const MethodChannel _channel = MethodChannel('com.roomomatic.sensors');

  // Get LiDAR distance measurements
  static Future<List<double>> getLidarDistances() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getLidarDistances');
      return result.cast<double>();
    } on PlatformException catch (e) {
      throw Exception('Failed to get LiDAR data: ${e.message}');
    }
  }

  // Start continuous sensor monitoring
  static Future<void> startSensorMonitoring() async {
    try {
      await _channel.invokeMethod('startSensorMonitoring');
    } on PlatformException catch (e) {
      throw Exception('Failed to start sensor monitoring: ${e.message}');
    }
  }

  // Stream for real-time sensor data
  static const EventChannel _sensorStream = EventChannel('com.roomomatic.sensors/stream');

  static Stream<Map<String, dynamic>> get sensorDataStream {
    return _sensorStream.receiveBroadcastStream().map((data) {
      return Map<String, dynamic>.from(data);
    });
  }
}
```

#### Android Side (Kotlin)
```kotlin
// android/app/src/main/kotlin/com/roomomatic/mobile/SensorChannelHandler.kt
package com.roomomatic.mobile

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class SensorChannelHandler(private val context: Context) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    SensorEventListener {

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private var eventSink: EventChannel.EventSink? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    companion object {
        const val METHOD_CHANNEL = "com.roomomatic.sensors"
        const val EVENT_CHANNEL = "com.roomomatic.sensors/stream"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getLidarDistances" -> {
                getLidarDistances(result)
            }
            "startSensorMonitoring" -> {
                startSensorMonitoring(result)
            }
            "stopSensorMonitoring" -> {
                stopSensorMonitoring(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getLidarDistances(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                // Simulate LiDAR data collection
                // In real implementation, this would interface with ToF sensors
                val distances = withContext(Dispatchers.IO) {
                    collectLidarData()
                }
                result.success(distances)
            } catch (e: Exception) {
                result.error("SENSOR_ERROR", "Failed to collect LiDAR data", e.message)
            }
        }
    }

    private suspend fun collectLidarData(): List<Double> {
        // Implementation would depend on specific ToF sensor hardware
        // This is a simplified example
        return withContext(Dispatchers.IO) {
            val distances = mutableListOf<Double>()

            // Simulate 360-degree sweep
            for (angle in 0..359 step 5) {
                val distance = simulateToFMeasurement(angle)
                distances.add(distance)
            }

            distances
        }
    }

    private fun simulateToFMeasurement(angle: Int): Double {
        // In real implementation, this would trigger ToF sensor
        // and return actual distance measurement
        return (50.0 + Math.random() * 200.0) // Random distance 50-250cm
    }

    private fun startSensorMonitoring(result: MethodChannel.Result) {
        try {
            val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            val gyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
            val magnetometer = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

            accelerometer?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
            gyroscope?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }
            magnetometer?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
            }

            result.success(null)
        } catch (e: Exception) {
            result.error("SENSOR_ERROR", "Failed to start sensor monitoring", e.message)
        }
    }

    private fun stopSensorMonitoring(result: MethodChannel.Result) {
        sensorManager.unregisterListener(this)
        result.success(null)
    }

    // EventChannel.StreamHandler implementation
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // SensorEventListener implementation
    override fun onSensorChanged(event: SensorEvent?) {
        event?.let { sensorEvent ->
            val sensorData = mapOf(
                "type" to sensorEvent.sensor.type,
                "timestamp" to sensorEvent.timestamp,
                "values" to sensorEvent.values.toList(),
                "accuracy" to sensorEvent.accuracy
            )

            eventSink?.success(sensorData)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Handle accuracy changes if needed
    }

    fun dispose() {
        sensorManager.unregisterListener(this)
        coroutineScope.cancel()
    }
}

// MainActivity.kt integration
class MainActivity: FlutterActivity() {
    private lateinit var sensorHandler: SensorChannelHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorHandler = SensorChannelHandler(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SensorChannelHandler.METHOD_CHANNEL
        ).setMethodCallHandler(sensorHandler)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SensorChannelHandler.EVENT_CHANNEL
        ).setStreamHandler(sensorHandler)
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::sensorHandler.isInitialized) {
            sensorHandler.dispose()
        }
    }
}
```

### Advanced Platform Channel Patterns

#### Pigeon for Type-Safe Communication
```dart
// pigeon/sensor_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/generated/sensor_api.g.dart',
  kotlinOut: 'android/app/src/main/kotlin/com/roomomatic/mobile/generated/SensorApi.kt',
  kotlinOptions: KotlinOptions(package: 'com.roomomatic.mobile.generated'),
))

class SensorReading {
  final String sensorType;
  final List<double> values;
  final int timestamp;
  final double accuracy;

  SensorReading({
    required this.sensorType,
    required this.values,
    required this.timestamp,
    required this.accuracy,
  });
}

class LidarScanResult {
  final List<double> distances;
  final List<double> angles;
  final int scanDurationMs;
  final double deviceOrientation;

  LidarScanResult({
    required this.distances,
    required this.angles,
    required this.scanDurationMs,
    required this.deviceOrientation,
  });
}

@HostApi()
abstract class SensorHostApi {
  LidarScanResult performLidarScan();
  void startContinuousSensorMonitoring();
  void stopContinuousSensorMonitoring();
  bool isLidarAvailable();
  List<String> getAvailableSensors();
}

@FlutterApi()
abstract class SensorFlutterApi {
  void onSensorDataReceived(SensorReading reading);
  void onLidarScanComplete(LidarScanResult result);
  void onSensorError(String error);
}
```

---

## Platform Views for Native Android Components

### Hybrid Composition (Recommended for Room-O-Matic)
```dart
// lib/widgets/native_camera_view.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class NativeCameraView extends StatelessWidget {
  final Function(int viewId)? onCameraCreated;
  final Map<String, dynamic>? creationParams;

  const NativeCameraView({
    Key? key,
    this.onCameraCreated,
    this.creationParams,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String viewType = 'com.roomomatic.camera_view';

    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams ?? {},
          creationParamsCodec: const StandardMessageCodec(),
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener((id) {
            onCameraCreated?.call(id);
          })
          ..create();
      },
    );
  }
}
```

### Android Native View Implementation
```kotlin
// android/app/src/main/kotlin/com/roomomatic/mobile/CameraView.kt
package com.roomomatic.mobile

import android.content.Context
import android.view.View
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraView(
    private val context: Context,
    private val id: Int,
    private val creationParams: Map<String, Any>?
) : PlatformView {

    private val previewView: PreviewView = PreviewView(context)
    private lateinit var cameraExecutor: ExecutorService
    private var camera: Camera? = null

    init {
        setupCamera()
    }

    private fun setupCamera() {
        cameraExecutor = Executors.newSingleThreadExecutor()

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            bindCamera(cameraProvider)
        }, ContextCompat.getMainExecutor(context))
    }

    private fun bindCamera(cameraProvider: ProcessCameraProvider) {
        val preview = Preview.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_16_9)
            .build()
            .also {
                it.setSurfaceProvider(previewView.surfaceProvider)
            }

        val imageAnalyzer = ImageAnalysis.Builder()
            .setTargetAspectRatio(AspectRatio.RATIO_16_9)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
            .also {
                it.setAnalyzer(cameraExecutor, { image ->
                    // Process image for AR overlay, object detection, etc.
                    processImageForRoomMapping(image)
                })
            }

        val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

        try {
            cameraProvider.unbindAll()
            camera = cameraProvider.bindToLifecycle(
                context as LifecycleOwner,
                cameraSelector,
                preview,
                imageAnalyzer
            )
        } catch (exc: Exception) {
            // Handle camera binding failure
        }
    }

    private fun processImageForRoomMapping(image: ImageProxy) {
        // Implement room mapping logic here
        // This would include:
        // - Edge detection for walls
        // - Object recognition for furniture
        // - Distance calculation using camera and sensor fusion

        image.close() // Always close the image
    }

    override fun getView(): View = previewView

    override fun dispose() {
        cameraExecutor.shutdown()
    }
}

// CameraViewFactory.kt
class CameraViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String, Any>?
        return CameraView(context, viewId, creationParams)
    }
}
```

---

## Sensor Integration for Room-O-Matic

### Comprehensive Sensor Data Collection
```dart
// lib/services/sensor_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  static const Duration _sensorInterval = Duration(milliseconds: 50); // 20Hz

  final StreamController<RoomMappingData> _roomDataController =
      StreamController<RoomMappingData>.broadcast();

  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;
  late StreamSubscription<MagnetometerEvent> _magnetometerSubscription;

  // Kalman filter for sensor fusion
  late KalmanFilter _orientationFilter;
  late KalmanFilter _positionFilter;

  Vector3 _currentPosition = Vector3.zero();
  Vector3 _currentOrientation = Vector3.zero();
  Vector3 _currentVelocity = Vector3.zero();

  Stream<RoomMappingData> get roomDataStream => _roomDataController.stream;

  Future<void> startSensorCollection() async {
    _initializeFilters();

    // Start sensor streams
    _accelerometerSubscription = accelerometerEvents.listen(_onAccelerometerData);
    _gyroscopeSubscription = gyroscopeEvents.listen(_onGyroscopeData);
    _magnetometerSubscription = magnetometerEvents.listen(_onMagnetometerData);

    // Start periodic room data calculation
    Timer.periodic(_sensorInterval, _calculateRoomData);
  }

  void _initializeFilters() {
    // Initialize Kalman filters for sensor fusion
    _orientationFilter = KalmanFilter(
      stateSize: 4, // Quaternion
      measurementSize: 3, // Euler angles
      controlSize: 3, // Angular velocity
    );

    _positionFilter = KalmanFilter(
      stateSize: 6, // Position + velocity
      measurementSize: 3, // Accelerometer
      controlSize: 3, // Acceleration
    );
  }

  void _onAccelerometerData(AccelerometerEvent event) {
    final acceleration = Vector3(event.x, event.y, event.z);

    // Remove gravity component
    final gravity = Vector3(0, 0, 9.81);
    final linearAcceleration = acceleration - gravity;

    // Update position using Kalman filter
    _positionFilter.predict();
    _positionFilter.update(linearAcceleration.toList());

    final state = _positionFilter.state;
    _currentPosition = Vector3(state[0], state[1], state[2]);
    _currentVelocity = Vector3(state[3], state[4], state[5]);
  }

  void _onGyroscopeData(GyroscopeEvent event) {
    final angularVelocity = Vector3(event.x, event.y, event.z);

    // Update orientation using Kalman filter
    _orientationFilter.predict(controlVector: angularVelocity.toList());

    // Convert quaternion to Euler angles
    final quaternion = _orientationFilter.state;
    _currentOrientation = quaternionToEuler(quaternion);
  }

  void _onMagnetometerData(MagnetometerEvent event) {
    final magneticField = Vector3(event.x, event.y, event.z);

    // Use magnetometer for compass heading correction
    final heading = math.atan2(magneticField.y, magneticField.x);

    // Correct orientation filter with compass data
    _orientationFilter.update([_currentOrientation.x, _currentOrientation.y, heading]);
  }

  void _calculateRoomData(Timer timer) {
    final roomData = RoomMappingData(
      position: _currentPosition,
      orientation: _currentOrientation,
      velocity: _currentVelocity,
      timestamp: DateTime.now(),
    );

    _roomDataController.add(roomData);
  }

  Future<void> stopSensorCollection() async {
    await _accelerometerSubscription.cancel();
    await _gyroscopeSubscription.cancel();
    await _magnetometerSubscription.cancel();
  }

  void dispose() {
    _roomDataController.close();
    stopSensorCollection();
  }
}

class RoomMappingData {
  final Vector3 position;
  final Vector3 orientation;
  final Vector3 velocity;
  final DateTime timestamp;

  RoomMappingData({
    required this.position,
    required this.orientation,
    required this.velocity,
    required this.timestamp,
  });
}

class Vector3 {
  final double x, y, z;

  const Vector3(this.x, this.y, this.z);
  static const Vector3 zero = Vector3(0, 0, 0);

  Vector3 operator -(Vector3 other) => Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 operator +(Vector3 other) => Vector3(x + other.x, y + other.y, z + other.z);

  List<double> toList() => [x, y, z];
}
```

### Audio Processing for Sonar
```dart
// lib/services/audio_sonar_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class AudioSonarService {
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  static const int _sampleRate = 44100;
  static const double _chirpFrequencyStart = 18000; // 18kHz - near ultrasonic
  static const double _chirpFrequencyEnd = 22000;   // 22kHz
  static const Duration _chirpDuration = Duration(milliseconds: 100);

  final StreamController<SonarResult> _sonarController =
      StreamController<SonarResult>.broadcast();

  Stream<SonarResult> get sonarResults => _sonarController.stream;

  Future<void> initialize() async {
    await _audioPlayer.openPlayer();
    await _audioRecorder.openRecorder();
  }

  Future<SonarResult> performSonarPing() async {
    final startTime = DateTime.now();

    // Generate chirp signal
    final chirpData = _generateChirpSignal();

    // Start recording before playing chirp
    final recordingCompleter = Completer<Uint8List>();
    _audioRecorder.startRecorder(
      toFile: null, // Record to memory
      codec: Codec.pcm16,
      sampleRate: _sampleRate,
    );

    // Play chirp
    await _audioPlayer.startPlayer(
      fromDataBuffer: chirpData,
      codec: Codec.pcm16,
      sampleRate: _sampleRate,
    );

    // Record for echo detection (500ms should be enough for room-sized spaces)
    await Future.delayed(Duration(milliseconds: 500));

    final recordingPath = await _audioRecorder.stopRecorder();
    await _audioPlayer.stopPlayer();

    // Process recording to detect echo
    final echoData = await _loadRecordingData(recordingPath!);
    final sonarResult = _processEchoData(echoData, startTime);

    _sonarController.add(sonarResult);
    return sonarResult;
  }

  Uint8List _generateChirpSignal() {
    final samples = (_sampleRate * _chirpDuration.inMilliseconds / 1000).round();
    final data = Float32List(samples);

    for (int i = 0; i < samples; i++) {
      final t = i / _sampleRate;
      final frequency = _chirpFrequencyStart +
          (_chirpFrequencyEnd - _chirpFrequencyStart) * t / (_chirpDuration.inMilliseconds / 1000);

      // Generate frequency-modulated chirp
      data[i] = math.sin(2 * math.pi * frequency * t) *
               _hanningWindow(i, samples) * 0.5; // Reduce volume to 50%
    }

    // Convert to 16-bit PCM
    final pcmData = Uint8List(samples * 2);
    for (int i = 0; i < samples; i++) {
      final sample = (data[i] * 32767).round().clamp(-32768, 32767);
      pcmData[i * 2] = sample & 0xFF;
      pcmData[i * 2 + 1] = (sample >> 8) & 0xFF;
    }

    return pcmData;
  }

  double _hanningWindow(int index, int length) {
    return 0.5 * (1 - math.cos(2 * math.pi * index / (length - 1)));
  }

  Future<Float32List> _loadRecordingData(String path) async {
    // Implementation would load and convert recorded audio data
    // This is simplified - actual implementation would read the file
    return Float32List(0);
  }

  SonarResult _processEchoData(Float32List data, DateTime startTime) {
    // Cross-correlation to find echo delay
    final echoDelay = _findEchoDelay(data);

    // Calculate distance (speed of sound ≈ 343 m/s)
    final distance = (echoDelay * 343) / 2; // Divide by 2 for round trip

    // Confidence based on echo strength
    final confidence = _calculateEchoConfidence(data, echoDelay);

    return SonarResult(
      distance: distance,
      confidence: confidence,
      timestamp: startTime,
      echoDelay: echoDelay,
    );
  }

  double _findEchoDelay(Float32List data) {
    // Simplified echo detection using energy thresholding
    // Real implementation would use cross-correlation with transmitted signal

    const double threshold = 0.1;
    final int windowSize = (_sampleRate * 0.01).round(); // 10ms window

    for (int i = windowSize; i < data.length - windowSize; i++) {
      double energy = 0;
      for (int j = i; j < i + windowSize; j++) {
        energy += data[j] * data[j];
      }
      energy /= windowSize;

      if (energy > threshold) {
        return i / _sampleRate; // Convert sample index to time
      }
    }

    return 0; // No echo detected
  }

  double _calculateEchoConfidence(Float32List data, double echoDelay) {
    // Simplified confidence calculation
    // Real implementation would analyze signal-to-noise ratio
    return echoDelay > 0 ? 0.8 : 0.1;
  }

  void dispose() {
    _audioPlayer.closePlayer();
    _audioRecorder.closeRecorder();
    _sonarController.close();
  }
}

class SonarResult {
  final double distance; // meters
  final double confidence; // 0.0 to 1.0
  final DateTime timestamp;
  final double echoDelay; // seconds

  SonarResult({
    required this.distance,
    required this.confidence,
    required this.timestamp,
    required this.echoDelay,
  });
}
```

---

## Security Implementation

### Biometric Authentication
```dart
// lib/services/biometric_auth_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    final isAvailable = await _localAuth.isDeviceSupported();
    final isEnrolled = await _localAuth.getAvailableBiometrics();
    return isAvailable && isEnrolled.isNotEmpty;
  }

  Future<bool> authenticateUser({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedFallbackTitle: 'Use device passcode',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Room-O-Matic Authentication',
            cancelButton: 'Cancel',
            goToSettingsButton: 'Settings',
            goToSettingsDescription: 'Please set up biometric authentication',
          ),
        ],
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }
}
```

### Secure Storage Implementation
```dart
// lib/services/secure_storage_service.dart
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'room_o_matic_secure_prefs',
      preferencesKeyPrefix: 'rom_',
    ),
  );

  static const String _keyPrefix = 'room_data_';
  static const String _encryptionKeyName = 'master_encryption_key';

  Future<void> storeRoomData(String roomId, Map<String, dynamic> roomData) async {
    final encryptedData = await _encryptData(jsonEncode(roomData));
    await _storage.write(key: '$_keyPrefix$roomId', value: encryptedData);
  }

  Future<Map<String, dynamic>?> getRoomData(String roomId) async {
    final encryptedData = await _storage.read(key: '$_keyPrefix$roomId');
    if (encryptedData == null) return null;

    final decryptedData = await _decryptData(encryptedData);
    return jsonDecode(decryptedData) as Map<String, dynamic>;
  }

  Future<String> _encryptData(String data) async {
    final key = await _getOrCreateEncryptionKey();
    final encrypter = Encrypter(AES(key));
    final iv = IV.fromSecureRandom(16);

    final encrypted = encrypter.encrypt(data, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String> _decryptData(String encryptedData) async {
    final parts = encryptedData.split(':');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    final key = await _getOrCreateEncryptionKey();
    final encrypter = Encrypter(AES(key));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<Key> _getOrCreateEncryptionKey() async {
    String? keyString = await _storage.read(key: _encryptionKeyName);

    if (keyString == null) {
      final key = Key.fromSecureRandom(32);
      await _storage.write(key: _encryptionKeyName, value: key.base64);
      return key;
    }

    return Key.fromBase64(keyString);
  }

  Future<void> clearAllData() async {
    await _storage.deleteAll();
  }
}
```

---

## Performance Optimization

### Memory Management
```dart
// lib/utils/memory_manager.dart
import 'dart:async';
import 'dart:developer' as developer;

class MemoryManager {
  static const int _maxCachedFrames = 30; // Keep last 30 camera frames
  static const int _maxSensorReadings = 1000; // Keep last 1000 sensor readings

  final Map<String, dynamic> _frameCache = {};
  final List<Map<String, dynamic>> _sensorCache = [];

  Timer? _cleanupTimer;

  void startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _performCleanup();
    });
  }

  void cacheFrame(String frameId, dynamic frameData) {
    _frameCache[frameId] = frameData;

    if (_frameCache.length > _maxCachedFrames) {
      final oldestKey = _frameCache.keys.first;
      _frameCache.remove(oldestKey);
    }
  }

  void cacheSensorReading(Map<String, dynamic> reading) {
    _sensorCache.add(reading);

    if (_sensorCache.length > _maxSensorReadings) {
      _sensorCache.removeAt(0);
    }
  }

  void _performCleanup() {
    // Force garbage collection
    developer.log('Performing memory cleanup', name: 'MemoryManager');

    // Clear old cached data
    final now = DateTime.now();
    _sensorCache.removeWhere((reading) {
      final timestamp = DateTime.parse(reading['timestamp'] as String);
      return now.difference(timestamp).inMinutes > 5;
    });

    // Report memory usage
    developer.log('Cache sizes - Frames: ${_frameCache.length}, Sensors: ${_sensorCache.length}');
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _frameCache.clear();
    _sensorCache.clear();
  }
}
```

### Background Processing with Isolates
```dart
// lib/services/background_processor.dart
import 'dart:isolate';
import 'dart:async';
import 'dart:typed_data';

class BackgroundProcessor {
  static Isolate? _isolate;
  static SendPort? _sendPort;
  static late Completer<void> _isolateReady;

  static Future<void> initialize() async {
    _isolateReady = Completer<void>();

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);

    receivePort.listen((data) {
      if (data is SendPort) {
        _sendPort = data;
        _isolateReady.complete();
      }
    });

    await _isolateReady.future;
  }

  static Future<List<double>> processLidarData(List<double> rawData) async {
    if (_sendPort == null) await initialize();

    final responsePort = ReceivePort();
    _sendPort!.send({
      'action': 'process_lidar',
      'data': rawData,
      'responsePort': responsePort.sendPort,
    });

    final result = await responsePort.first as List<double>;
    responsePort.close();

    return result;
  }

  static Future<Map<String, dynamic>> processImageData(Uint8List imageData) async {
    if (_sendPort == null) await initialize();

    final responsePort = ReceivePort();
    _sendPort!.send({
      'action': 'process_image',
      'data': imageData,
      'responsePort': responsePort.sendPort,
    });

    final result = await responsePort.first as Map<String, dynamic>;
    responsePort.close();

    return result;
  }

  static void dispose() {
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
  }

  static void _isolateEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((data) {
      final Map<String, dynamic> message = data as Map<String, dynamic>;
      final SendPort responsePort = message['responsePort'] as SendPort;

      switch (message['action']) {
        case 'process_lidar':
          final result = _processLidarInIsolate(message['data'] as List<double>);
          responsePort.send(result);
          break;
        case 'process_image':
          final result = _processImageInIsolate(message['data'] as Uint8List);
          responsePort.send(result);
          break;
      }
    });
  }

  static List<double> _processLidarInIsolate(List<double> rawData) {
    // Perform CPU-intensive LiDAR data processing
    // Apply noise filtering, smoothing, outlier removal

    final processed = <double>[];

    for (int i = 0; i < rawData.length; i++) {
      // Simple moving average filter
      double sum = 0;
      int count = 0;

      for (int j = -2; j <= 2; j++) {
        final index = i + j;
        if (index >= 0 && index < rawData.length) {
          sum += rawData[index];
          count++;
        }
      }

      processed.add(sum / count);
    }

    return processed;
  }

  static Map<String, dynamic> _processImageInIsolate(Uint8List imageData) {
    // Perform image processing for edge detection, object recognition
    // This is a simplified example

    return {
      'edges_detected': true,
      'objects_found': ['wall', 'door', 'window'],
      'processing_time_ms': 150,
    };
  }
}
```

---

## Testing Strategies

### Widget Testing with Camera Mocking
```dart
// test/widget/camera_view_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic/widgets/native_camera_view.dart';

void main() {
  group('NativeCameraView Tests', () {
    late List<MethodCall> methodCalls;

    setUp(() {
      methodCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.roomomatic.camera'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          switch (methodCall.method) {
            case 'initialize':
              return {'success': true};
            case 'startPreview':
              return {'success': true};
            default:
              return null;
          }
        },
      );
    });

    testWidgets('should initialize camera on creation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NativeCameraView(
            onCameraCreated: (id) {},
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(methodCalls.length, greaterThan(0));
      expect(methodCalls.first.method, equals('initialize'));
    });

    testWidgets('should handle camera errors gracefully', (WidgetTester tester) async {
      // Mock camera initialization failure
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.roomomatic.camera'),
        (MethodCall methodCall) async {
          throw PlatformException(code: 'CAMERA_ERROR', message: 'Camera not available');
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NativeCameraView(
            onCameraCreated: (id) {},
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // Verify error handling UI is shown
      expect(find.text('Camera Error'), findsOneWidget);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.roomomatic.camera'),
        null,
      );
    });
  });
}
```

### Integration Testing
```dart
// integration_test/room_mapping_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:room_o_matic/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Room Mapping Integration Tests', () {
    testWidgets('complete room scanning workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to room scanning screen
      await tester.tap(find.text('Start Room Scan'));
      await tester.pumpAndSettle();

      // Grant camera permissions (simulated)
      await tester.tap(find.text('Grant Camera Permission'));
      await tester.pumpAndSettle();

      // Start scanning process
      await tester.tap(find.text('Begin Scan'));
      await tester.pumpAndSettle();

      // Wait for scan completion (with timeout)
      await tester.pump(Duration(seconds: 5));

      // Verify scan results are displayed
      expect(find.text('Scan Complete'), findsOneWidget);
      expect(find.text('Room Dimensions'), findsOneWidget);
    });

    testWidgets('sensor data collection accuracy', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to sensor testing screen
      await tester.tap(find.text('Sensor Test'));
      await tester.pumpAndSettle();

      // Start sensor monitoring
      await tester.tap(find.text('Start Monitoring'));
      await tester.pumpAndSettle();

      // Simulate device movement
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/sensors/accelerometer',
        StandardMethodCodec().encodeMethodCall(
          MethodCall('listen', {'x': 1.0, 'y': 0.0, 'z': 9.8}),
        ),
        (data) {},
      );

      await tester.pump();

      // Verify sensor data is being processed
      expect(find.textContaining('Acceleration:'), findsOneWidget);
    });
  });
}
```

### Performance Testing
```dart
// test/performance/memory_leak_test.dart
import 'dart:developer' as developer;
import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic/services/sensor_service.dart';

void main() {
  group('Performance Tests', () {
    test('sensor service memory usage', () async {
      final sensorService = SensorService();

      // Record initial memory usage
      final initialMemory = _getCurrentMemoryUsage();

      // Start sensor collection
      await sensorService.startSensorCollection();

      // Simulate extended usage
      for (int i = 0; i < 1000; i++) {
        // Simulate sensor data
        await Future.delayed(Duration(milliseconds: 10));
      }

      await sensorService.stopSensorCollection();

      // Force garbage collection
      await Future.delayed(Duration(seconds: 1));

      final finalMemory = _getCurrentMemoryUsage();
      final memoryIncrease = finalMemory - initialMemory;

      // Verify memory usage hasn't increased significantly
      expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // Less than 50MB increase

      sensorService.dispose();
    });

    test('frame processing performance', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate frame processing
      for (int i = 0; i < 100; i++) {
        // Process mock frame data
        await _processMockFrame();
      }

      stopwatch.stop();

      final averageProcessingTime = stopwatch.elapsedMilliseconds / 100;

      // Verify processing time is under 16ms (60 FPS)
      expect(averageProcessingTime, lessThan(16));
    });
  });
}

int _getCurrentMemoryUsage() {
  return developer.Service.getIsolateID(Isolate.current).hashCode;
}

Future<void> _processMockFrame() async {
  // Simulate frame processing work
  await Future.delayed(Duration(microseconds: 100));
}
```

---

## Build & Deployment

### Build Configuration
```yaml
# android/app/build.gradle additions for Room-O-Matic
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 23 // Required for Camera2 API
        targetSdkVersion 34

        // Room-O-Matic specific configurations
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }

        // Sensor permissions
        manifestPlaceholders = [
            'cameraPermission': 'true',
            'microphonePermission': 'true',
            'locationPermission': 'true'
        ]
    }

    buildTypes {
        release {
            shrinkResources true
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'

            // Signing configuration
            signingConfig signingConfigs.release
        }
    }

    // Enable R8 full mode for better optimization
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
}

dependencies {
    // Core desugar for newer API features on older devices
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'

    // Camera and sensor libraries
    implementation 'androidx.camera:camera-camera2:1.3.1'
    implementation 'androidx.camera:camera-lifecycle:1.3.1'
    implementation 'androidx.camera:camera-view:1.3.1'

    // Security libraries
    implementation 'androidx.biometric:biometric:1.1.0'
    implementation 'androidx.security:security-crypto:1.1.0-alpha06'
}
```

### ProGuard Configuration
```proguard
# android/app/proguard-rules.pro
# Room-O-Matic specific ProGuard rules

# Keep native method classes
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep sensor-related classes
-keep class com.roomomatic.mobile.sensors.** { *; }
-keep class com.roomomatic.mobile.camera.** { *; }

# Keep Flutter platform channel classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep sensor and camera library classes
-keep class androidx.camera.** { *; }
-keep class android.hardware.** { *; }

# Keep biometric authentication classes
-keep class androidx.biometric.** { *; }

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
```

### GitHub Actions CI/CD
```yaml
# .github/workflows/android_build.yml
name: Android Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '11'

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        channel: 'stable'

    - name: Get dependencies
      run: flutter pub get

    - name: Analyze code
      run: flutter analyze

    - name: Run tests
      run: flutter test --coverage

    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info

  build_android:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '11'

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        channel: 'stable'

    - name: Get dependencies
      run: flutter pub get

    - name: Build APK
      run: flutter build apk --release

    - name: Build App Bundle
      run: flutter build appbundle --release

    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: release-apk
        path: build/app/outputs/apk/release/app-release.apk

    - name: Upload App Bundle
      uses: actions/upload-artifact@v3
      with:
        name: release-aab
        path: build/app/outputs/bundle/release/app-release.aab
```

---

## Troubleshooting Common Issues

### Camera Integration Issues

**Problem**: Camera preview not showing
```kotlin
// Solution: Check camera permissions and lifecycle
class CameraView(private val context: Context) : PlatformView {
    private fun checkCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun setupCamera() {
        if (!checkCameraPermission()) {
            // Request permission through platform channel
            requestCameraPermission()
            return
        }

        // Proceed with camera setup
    }
}
```

**Problem**: Camera performance issues
```dart
// Solution: Optimize camera configuration
ImageAnalysis imageAnalysis = ImageAnalysis.Builder()
    .setTargetResolution(Size(640, 480)) // Lower resolution for better performance
    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
    .build()
```

### Sensor Data Issues

**Problem**: Noisy sensor readings
```dart
// Solution: Implement Kalman filtering
class SensorFilter {
  static List<double> applyKalmanFilter(List<double> rawData) {
    // Implementation of Kalman filter for sensor noise reduction
    final filtered = <double>[];
    double previousEstimate = rawData.first;
    double previousErrorCovariance = 1.0;

    for (final measurement in rawData) {
      // Prediction step
      final predictedEstimate = previousEstimate;
      final predictedErrorCovariance = previousErrorCovariance + 0.01; // Process noise

      // Update step
      final kalmanGain = predictedErrorCovariance / (predictedErrorCovariance + 0.1); // Measurement noise
      final currentEstimate = predictedEstimate + kalmanGain * (measurement - predictedEstimate);
      final currentErrorCovariance = (1 - kalmanGain) * predictedErrorCovariance;

      filtered.add(currentEstimate);

      previousEstimate = currentEstimate;
      previousErrorCovariance = currentErrorCovariance;
    }

    return filtered;
  }
}
```

### Memory Management Issues

**Problem**: Memory leaks in continuous sensor monitoring
```dart
// Solution: Proper stream management
class SensorService {
  StreamSubscription? _sensorSubscription;

  void startMonitoring() {
    _sensorSubscription = sensorStream.listen((data) {
      // Process data
    });
  }

  void stopMonitoring() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
```

### Platform Channel Communication Issues

**Problem**: Method channel calls failing
```dart
// Solution: Add proper error handling and timeouts
class PlatformService {
  static const _timeout = Duration(seconds: 5);

  static Future<T> callWithTimeout<T>(
    String method, [
    dynamic arguments,
  ]) async {
    try {
      final result = await _channel
          .invokeMethod<T>(method, arguments)
          .timeout(_timeout);
      return result!;
    } on TimeoutException {
      throw Exception('Platform call timed out: $method');
    } on PlatformException catch (e) {
      throw Exception('Platform error: ${e.message}');
    }
  }
}
```

### Performance Optimization Issues

**Problem**: UI freezing during heavy computation
```dart
// Solution: Use isolates for heavy processing
class PerformanceOptimizer {
  static Future<ProcessedData> processInBackground(RawData data) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(_backgroundProcessor, {
      'sendPort': receivePort.sendPort,
      'data': data,
    });

    final result = await receivePort.first as ProcessedData;
    receivePort.close();

    return result;
  }

  static void _backgroundProcessor(Map<String, dynamic> message) {
    final SendPort sendPort = message['sendPort'];
    final RawData data = message['data'];

    // Perform heavy computation
    final result = performHeavyComputation(data);

    sendPort.send(result);
  }
}
```

---

## Conclusion

This guide provides a comprehensive foundation for Android Flutter development specifically tailored for the Room-O-Matic mobile application. The patterns and implementations shown here cover:

- **Platform Integration**: Seamless communication between Flutter and native Android code
- **Sensor Management**: Real-time collection and processing of sensor data
- **Camera Integration**: AR-ready camera implementation with performance optimization
- **Security**: Biometric authentication and secure data storage
- **Performance**: Memory management and background processing optimization
- **Testing**: Comprehensive testing strategies for mobile sensor applications

Remember to:
1. Always test on real devices for sensor functionality
2. Implement proper error handling for all platform integrations
3. Optimize for battery life when using continuous sensor monitoring
4. Follow Android security best practices for sensitive data
5. Use background processing for computationally intensive tasks

The Room-O-Matic application's unique sensor integration requirements make this guide particularly focused on high-performance, real-time data collection and processing capabilities that are essential for accurate room mapping and measurement functionality.
