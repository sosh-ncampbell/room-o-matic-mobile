import 'dart:async';
import 'dart:math' as Math;

import 'package:room_o_matic_mobile/domain/entities/sensor_data.dart';
import 'package:room_o_matic_mobile/domain/value_objects/point_3d.dart';
import 'package:room_o_matic_mobile/infrastructure/platform_channels/native_sensor_channel.dart';

/// Mock implementation of INativeSensorChannel for testing
class MockNativeSensorChannel implements INativeSensorChannel {
  final StreamController<List<Point3D>> _mockLidarController;
  final StreamController<SensorData> _mockMotionController;
  final StreamController<Map<String, dynamic>> _mockCameraController;
  final StreamController<String> _mockErrorController;

  MockNativeSensorChannel()
      : _mockLidarController = StreamController<List<Point3D>>.broadcast(),
        _mockMotionController = StreamController<SensorData>.broadcast(),
        _mockCameraController =
            StreamController<Map<String, dynamic>>.broadcast(),
        _mockErrorController = StreamController<String>.broadcast();

  // Override the streams to return our mock controllers
  @override
  Stream<List<Point3D>> get lidarStream => _mockLidarController.stream;

  @override
  Stream<SensorData> get motionStream => _mockMotionController.stream;

  @override
  Stream<Map<String, dynamic>> get cameraStream => _mockCameraController.stream;

  @override
  Stream<String> get errorStream => _mockErrorController.stream;

  // Test helper methods to emit mock data
  void emitLiDARPoints(List<Point3D> points) {
    _mockLidarController.add(points);
  }

  void emitMotionData(SensorData data) {
    _mockMotionController.add(data);
  }

  void emitCameraFrame(Map<String, dynamic> frameData) {
    _mockCameraController.add(frameData);
  }

  void emitError(String error) {
    _mockErrorController.add(error);
  }

  @override
  Future<bool> requestCameraPermission() async => true;

  @override
  Future<bool> requestMotionPermission() async => true;

  @override
  Future<bool> requestLocationPermission() async => true;

  @override
  Future<bool> isLiDARAvailable() async => true;

  @override
  Future<bool> startLiDARScan() async {
    // Simulate starting LiDAR scan by emitting test data
    await Future.delayed(const Duration(milliseconds: 100));
    emitLiDARPoints([
      const Point3D(x: 1.0, y: 2.0, z: 3.0),
      const Point3D(x: 1.5, y: 2.5, z: 3.5),
    ]);
    return true;
  }

  @override
  Future<bool> stopLiDARScan() async {
    // Simulate stopping LiDAR scan
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Future<bool> startMotionSensors() async {
    // Simulate starting motion sensor by emitting test data
    await Future.delayed(const Duration(milliseconds: 50));
    emitMotionData(SensorData(
      id: 'test_motion_1',
      type: SensorType.accelerometer,
      timestamp: DateTime.now(),
      confidence: 0.95,
      data: {
        'accelerationX': 0.1,
        'accelerationY': 0.2,
        'accelerationZ': 9.8,
        'rotationX': 0.01,
        'rotationY': 0.02,
        'rotationZ': 0.03,
      },
    ));
    return true;
  }

  @override
  Future<bool> stopMotionSensors() async {
    // Simulate stopping motion sensor
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  @override
  Future<Map<String, dynamic>?> getCameraFrame() async {
    // Simulate getting camera frame
    await Future.delayed(const Duration(milliseconds: 50));
    return {
      'frameData': 'mock_camera_frame_data',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'width': 1920,
      'height': 1080,
    };
  }

  // Advanced LiDAR Methods
  @override
  Future<Map<String, dynamic>?> getAdvancedCapabilities() async {
    return {
      'hasLiDAR': true,
      'hasToF': true,
      'supportsSceneReconstruction': true,
      'supportsDepthData': true,
      'supportsMeshGeneration': true,
      'deviceModel': 'TestDevice',
      'supportedFormats': ['depth', 'pointCloud', 'mesh'],
      'specifications': {'maxRange': 10.0, 'accuracy': 0.01},
    };
  }

  @override
  Future<Map<String, dynamic>?> startAdvancedLiDAR(
      Map<String, dynamic> params) async {
    return {'sessionId': params['sessionId'], 'status': 'started'};
  }

  @override
  Future<Map<String, dynamic>?> startAdvancedToF(
      Map<String, dynamic> params) async {
    return {'sessionId': params['sessionId'], 'status': 'started'};
  }

  @override
  Future<Map<String, dynamic>?> startSensorFusion(
      Map<String, dynamic> params) async {
    return {
      'sessionId': params['sessionId'],
      'activeSensors': params['sensors']
    };
  }

  @override
  Future<Map<String, dynamic>?> stopSensorSession(
      Map<String, dynamic> params) async {
    return {
      'sessionId': params['sessionId'],
      'pointCloudCount': 100,
      'meshAnchorCount': 5
    };
  }

  @override
  Future<Map<String, dynamic>?> getCurrentLiDARData(
      Map<String, dynamic> params) async {
    return {
      'sessionId': params['sessionId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'pointCloud': [
        {'x': 1.0, 'y': 2.0, 'z': 3.0, 'type': 'feature', 'depth': 3.0}
      ],
      'confidence': 0.95,
      'cameraTransform': {
        'matrix': [
          [1.0, 0.0, 0.0, 0.0],
          [0.0, 1.0, 0.0, 0.0],
          [0.0, 0.0, 1.0, 0.0],
          [0.0, 0.0, 0.0, 1.0]
        ],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      'metadata': {}
    };
  }

  @override
  Future<Map<String, dynamic>?> getCurrentToFData(
      Map<String, dynamic> params) async {
    return {
      'sessionId': params['sessionId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'measurements': [
        {
          'x': 1.0,
          'y': 2.0,
          'z': 3.0,
          'distance': 3.0,
          'confidence': 0.9,
          'pixelX': 100,
          'pixelY': 200,
          'properties': {}
        }
      ],
      'confidence': 0.9,
      'sensorInfo': {
        'sensorName': 'MockToF',
        'maxRange': 10.0,
        'minRange': 0.1,
        'accuracy': 0.05,
        'width': 640,
        'height': 480,
        'capabilities': {}
      },
      'metadata': {}
    };
  }

  @override
  Future<Map<String, dynamic>?> getFusionData(
      Map<String, dynamic> params) async {
    return {
      'sessionId': params['sessionId'],
      'lidar': await getCurrentLiDARData(params),
      'tof': await getCurrentToFData(params),
      'imu': {
        'accel_x': 0.1,
        'accel_y': 0.2,
        'accel_z': 9.8,
        'gyro_x': 0.01,
        'gyro_y': 0.02,
        'gyro_z': 0.03,
        'mag_x': 0.5,
        'mag_y': 0.6,
        'mag_z': 0.7,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'calibration': {}
      },
      'camera': {
        'frameId': 'mock_frame_001',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'width': 1920,
        'height': 1080,
        'transform': {
          'matrix': [
            [1.0, 0.0, 0.0, 0.0],
            [0.0, 1.0, 0.0, 0.0],
            [0.0, 0.0, 1.0, 0.0],
            [0.0, 0.0, 0.0, 1.0]
          ],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        'properties': {}
      },
      'fusionConfidence': 0.92,
      'fusionMetrics': {'algorithm': 'kalman', 'processingTime': 12.5}
    };
  }

  @override
  Future<Map<String, dynamic>?> measureAdvancedDistance(
      Map<String, dynamic> params) async {
    final fromPoint = List<double>.from(params['fromPoint']);
    final toPoint = List<double>.from(params['toPoint']);

    // Calculate mock distance
    final dx = toPoint[0] - fromPoint[0];
    final dy = toPoint[1] - fromPoint[1];
    final dz = toPoint[2] - fromPoint[2];
    final distance = Math.sqrt(dx * dx + dy * dy + dz * dz);

    return {
      'distance': distance,
      'confidence': 0.95,
      'method': 'ToF',
      'accuracy': 0.02,
      'sessionId': params['sessionId']
    };
  }

  // Location methods
  @override
  Future<bool> startLocationTracking() async => true;

  @override
  Future<bool> stopLocationTracking() async => true;

  @override
  Future<Map<String, dynamic>?> getCurrentLocation() async => {
        'latitude': 37.7749,
        'longitude': -122.4194,
        'altitude': 0.0,
        'accuracy': 5.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

  @override
  Future<Map<String, dynamic>?> getLocationCapabilities() async => {
        'locationServicesEnabled': true,
        'hasPermission': true,
        'supportsPreciseLocation': true,
        'supportsBackgroundLocation': false,
        'authorizationStatus': 'authorized',
        'availableProviders': ['gps', 'network'],
      };

  @override
  Future<Map<String, dynamic>?> measureLocationDistance(
      Map<String, dynamic> params) async {
    // Mock distance calculation
    return {
      'distance': 100.0,
      'confidence': 0.9,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'method': 'gps',
    };
  }

  // Enhanced Camera methods
  @override
  Future<Map<String, dynamic>?> initializeEnhancedCamera(
          Map<String, dynamic> config) async =>
      {
        'success': true,
        'capabilities': {
          'hasCamera': true,
          'supportsDepth': false,
          'supportsARKit': false,
          'supportsToF': false,
        },
      };

  @override
  Future<bool> startCameraSession() async => true;

  @override
  Future<bool> stopCameraSession() async => true;

  @override
  Future<Map<String, dynamic>?> captureEnhancedPhoto(
          Map<String, dynamic> settings) async =>
      {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'photoId': 'mock_photo_${DateTime.now().millisecondsSinceEpoch}',
        'format': settings['format'] ?? 'jpeg',
        'width': 1920,
        'height': 1080,
      };

  @override
  Future<Map<String, dynamic>?> getEnhancedCameraCapabilities() async => {
        'hasCamera': true,
        'hasFrontCamera': true,
        'hasBackCamera': true,
        'supportsDepth': false,
        'supportsARKit': false,
        'supportsToF': false,
        'hardwareLevel': 'limited',
      };

  @override
  Future<Map<String, dynamic>?> measureCameraDistance(
      Map<String, dynamic> params) async {
    // Mock camera distance measurement
    return {
      'distance': 50.0,
      'confidence': 0.7,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'method': 'depth_estimation',
    };
  }

  // MARK: - Chiroptera (Bio-inspired Echolocation) Methods

  @override
  Future<Map<String, dynamic>?> initializeChiroptera(
          Map<String, dynamic> config) async =>
      {
        'supportsChiroptera': true,
        'supportsUltrasonic': true,
        'supportsEcholocation': true,
        'hasAudioInput': true,
        'hasAudioOutput': true,
        'sampleRate': 44100,
        'frequencyRange': {'min': 18000.0, 'max': 22000.0},
        'distanceRange': {'min': 0.1, 'max': 10.0},
        'accuracy': 0.05,
        'chirpDuration': 100,
        'metadata': {'technology': 'chiroptera', 'version': '1.0'},
      };

  @override
  Future<bool> startChiropteraSession() async => true;

  @override
  Future<bool> stopChiropteraSession() async => true;

  @override
  Future<Map<String, dynamic>?> performChiropteraPing(
      Map<String, double> direction) async {
    // Mock echolocation ping
    final mockDistance = 2.5 + (Math.Random().nextDouble() * 0.5); // 2.5-3.0m
    return {
      'distance': mockDistance,
      'confidence': 0.92,
      'delaySeconds': mockDistance * 2 / 343.0, // Sound round trip
      'correlationPeak': 0.85,
      'direction': direction,
      'method': 'chiroptera_echolocation',
      'frequency': '18000-22000Hz',
      'chirpDuration': 100,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': {
        'sampleRate': 44100,
        'signalLength': 8820,
        'referenceLength': 4410,
        'maxIndex': 4200,
      },
    };
  }

  @override
  Future<Map<String, dynamic>?> measureChiropteraDistance(
      Map<String, dynamic> params) async {
    final direction = params['direction'] as Map<String, double>? ??
        {'x': 0.0, 'y': 0.0, 'z': 1.0};
    final maxRange = params['maxRange'] as double? ?? 10.0;

    // Simulate realistic distance measurement
    final mockDistance = Math.min(maxRange * 0.6, 4.2);
    return {
      'distance': mockDistance,
      'confidence': 0.88,
      'direction': direction,
      'maxRange': maxRange,
      'method': 'chiroptera_echolocation',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': {
        'technology': 'chiroptera',
        'signalQuality': 'good',
        'environmentalFactors': 'indoor',
      },
    };
  }

  @override
  Future<Map<String, dynamic>?> getChiropteraCapabilities() async => {
        'supportsChiroptera': true,
        'supportsUltrasonic': true,
        'supportsEcholocation': true,
        'hasAudioInput': true,
        'hasAudioOutput': true,
        'sampleRate': 44100,
        'channelConfig': 'MONO',
        'audioFormat': 'PCM_16BIT',
        'frequencyRange': {'min': 18000.0, 'max': 22000.0},
        'distanceRange': {'min': 0.1, 'max': 10.0},
        'accuracy': 0.05,
        'chirpDuration': 100,
        'hasEchoCanceler': true,
        'hasNoiseSuppressor': true,
        'hasAutomaticGainControl': true,
        'metadata': {'technology': 'chiroptera', 'version': '1.0'},
      };

  @override
  void dispose() {
    _mockLidarController.close();
    _mockMotionController.close();
    _mockCameraController.close();
    _mockErrorController.close();
  }
}
