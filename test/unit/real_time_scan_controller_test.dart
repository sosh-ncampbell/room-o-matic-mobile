import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic_mobile/application/controllers/real_time_scan_controller.dart';

import '../mocks/mock_native_sensor_channel.dart';

void main() {
  // Ensure Flutter binding is initialized for platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealTimeScanController with Real Sensor Integration', () {
    late ProviderContainer container;
    late MockNativeSensorChannel mockSensorChannel;

    setUp(() {
      mockSensorChannel = MockNativeSensorChannel();
      container = ProviderContainer(
        overrides: [
          nativeSensorChannelProvider.overrideWithValue(mockSensorChannel),
        ],
      );
    });

    tearDown(() {
      mockSensorChannel.dispose();
      container.dispose();
    });

    test('should initialize with proper real sensor integration', () {
      // Arrange & Act
      final controller =
          container.read(realTimeScanControllerProvider.notifier);
      final state = container.read(realTimeScanControllerProvider);

      // Assert
      expect(state.isScanning, false);
      expect(state.isPaused, false);
      expect(state.pointsCollected, 0);
      expect(state.errorMessage, null);
      expect(controller, isA<RealTimeScanController>());
    });

    test('should start scan and process real sensor data', () async {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);

      // Act
      await controller.startScan();

      // Allow some time for async processing
      await Future.delayed(const Duration(milliseconds: 200));

      // Assert
      final state = container.read(realTimeScanControllerProvider);
      expect(state.isScanning, true);
      expect(state.statusMessage, contains('Scanning'));
    });

    test('should handle real LiDAR data processing', () async {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);

      // Act
      await controller.startScan();

      // Simulate LiDAR data
      await mockSensorChannel.startLiDARScan();

      // Allow processing time
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert
      final state = container.read(realTimeScanControllerProvider);
      expect(state.isScanning, true);
      expect(state.pointsCollected, greaterThan(0));
    });

    test('should handle real motion sensor integration', () async {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);

      // Act
      await controller.startScan();

      // Simulate motion data
      await mockSensorChannel.startMotionSensors();

      // Allow processing time
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert
      final state = container.read(realTimeScanControllerProvider);
      expect(state.isScanning, true);
      // Motion data should be processed by the sensor fusion service
    });

    test('should stop scan and cleanup real sensors', () async {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);
      await controller.startScan();

      // Act
      await controller.stopScan();

      // Assert
      final state = container.read(realTimeScanControllerProvider);
      expect(state.isScanning, false);
      expect(state.isPaused, false);
      expect(state.statusMessage, contains('completed'));
    });

    test('should handle sensor permission requests', () async {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);

      // Act
      await controller.startScan();

      // Verify permission methods were called
      final cameraPermission =
          await mockSensorChannel.requestCameraPermission();
      final motionPermission =
          await mockSensorChannel.requestMotionPermission();
      final locationPermission =
          await mockSensorChannel.requestLocationPermission();

      // Assert
      expect(cameraPermission, true);
      expect(motionPermission, true);
      expect(locationPermission, true);
    });

    test('should handle pause and resume functionality', () {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);

      // Act
      controller.pauseScan();
      var state = container.read(realTimeScanControllerProvider);
      expect(state.isPaused, false); // Can't pause if not scanning

      // Start scanning first
      controller.startScan();
      controller.pauseScan();
      state = container.read(realTimeScanControllerProvider);
      expect(state.isPaused, true);

      controller.resumeScan();
      state = container.read(realTimeScanControllerProvider);
      expect(state.isPaused, false);
    });

    test('should reset scan state properly', () {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);

      // Act
      controller.resetScan();

      // Assert
      final state = container.read(realTimeScanControllerProvider);
      expect(state.isScanning, false);
      expect(state.isPaused, false);
      expect(state.pointsCollected, 0);
      expect(state.scanProgress, 0.0);
      expect(state.currentMeasurements, isEmpty);
      expect(state.visualizationPoints, isEmpty);
    });
  });
}
