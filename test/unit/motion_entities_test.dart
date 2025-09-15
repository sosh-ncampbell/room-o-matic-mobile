// 🧪 Room-O-Matic Mobile: Motion Entities Tests
// Tests for Core Motion sensor entities and data structures

import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic_mobile/domain/entities/motion/motion_data.dart';

void main() {
  group('Motion Entities Tests', () {
    group('Motion Configuration Tests', () {
      test('should create valid motion configuration', () {
        const config = MotionConfiguration(
          accelerometerUpdateInterval: 60.0,
          gyroscopeUpdateInterval: 60.0,
          magnetometerUpdateInterval: 30.0,
          deviceMotionUpdateInterval: 10.0,
        );

        expect(config.accelerometerUpdateInterval, equals(60.0));
        expect(config.gyroscopeUpdateInterval, equals(60.0));
        expect(config.magnetometerUpdateInterval, equals(30.0));
        expect(config.deviceMotionUpdateInterval, equals(10.0));
      });

      test('should serialize and deserialize motion configuration', () {
        const config = MotionConfiguration(
          accelerometerUpdateInterval: 50.0,
          useReferenceAttitude: true,
          referenceFrame: MotionReferenceFrame.xMagneticNorthZVertical,
        );

        final json = config.toJson();
        final deserializedConfig = MotionConfiguration.fromJson(json);

        expect(deserializedConfig.accelerometerUpdateInterval, equals(50.0));
        expect(deserializedConfig.useReferenceAttitude, equals(true));
        expect(deserializedConfig.referenceFrame,
               equals(MotionReferenceFrame.xMagneticNorthZVertical));
      });

      test('should use default values for motion configuration', () {
        const config = MotionConfiguration();

        expect(config.accelerometerUpdateInterval, equals(60.0));
        expect(config.gyroscopeUpdateInterval, equals(60.0));
        expect(config.magnetometerUpdateInterval, equals(30.0));
        expect(config.deviceMotionUpdateInterval, equals(10.0));
        expect(config.useReferenceAttitude, isTrue);
        expect(config.enableGravityEstimation, isTrue);
        expect(config.motionThreshold, equals(0.1));
        expect(config.maxSampleRate, equals(1000));
        expect(config.bufferSize, equals(10));
      });
    });

    group('Motion Vector and Quaternion Tests', () {
      test('should create and manipulate motion vectors', () {
        const vector = MotionVector(x: 1.0, y: 2.0, z: 3.0);

        expect(vector.x, equals(1.0));
        expect(vector.y, equals(2.0));
        expect(vector.z, equals(3.0));
      });

      test('should serialize motion vectors', () {
        const vector = MotionVector(x: 1.5, y: -2.5, z: 3.5);

        final json = vector.toJson();
        final deserializedVector = MotionVector.fromJson(json);

        expect(deserializedVector.x, equals(1.5));
        expect(deserializedVector.y, equals(-2.5));
        expect(deserializedVector.z, equals(3.5));
      });

      test('should create and manipulate quaternions', () {
        const quaternion = MotionQuaternion(w: 1.0, x: 0.0, y: 0.0, z: 0.0);

        expect(quaternion.w, equals(1.0));
        expect(quaternion.x, equals(0.0));
        expect(quaternion.y, equals(0.0));
        expect(quaternion.z, equals(0.0));
      });

      test('should serialize quaternions', () {
        const quaternion = MotionQuaternion(w: 0.707, x: 0.707, y: 0.0, z: 0.0);

        final json = quaternion.toJson();
        final deserializedQuaternion = MotionQuaternion.fromJson(json);

        expect(deserializedQuaternion.w, equals(0.707));
        expect(deserializedQuaternion.x, equals(0.707));
        expect(deserializedQuaternion.y, equals(0.0));
        expect(deserializedQuaternion.z, equals(0.0));
      });

      test('should create rotation matrix', () {
        const matrix = MotionRotationMatrix(
          m11: 1.0, m12: 0.0, m13: 0.0,
          m21: 0.0, m22: 1.0, m23: 0.0,
          m31: 0.0, m32: 0.0, m33: 1.0,
        );

        expect(matrix.m11, equals(1.0));
        expect(matrix.m22, equals(1.0));
        expect(matrix.m33, equals(1.0));
        expect(matrix.m12, equals(0.0));
        expect(matrix.m13, equals(0.0));
        expect(matrix.m21, equals(0.0));
      });
    });

    group('Device Motion Data Tests', () {
      test('should create device attitude with orientation data', () {
        const quaternion = MotionQuaternion(w: 1.0, x: 0.0, y: 0.0, z: 0.0);
        const matrix = MotionRotationMatrix();
        final timestamp = DateTime.now();

        final attitude = DeviceAttitude(
          roll: 0.5,
          pitch: 0.3,
          yaw: 1.2,
          quaternion: quaternion,
          rotationMatrix: matrix,
          timestamp: timestamp,
        );

        expect(attitude.roll, equals(0.5));
        expect(attitude.pitch, equals(0.3));
        expect(attitude.yaw, equals(1.2));
        expect(attitude.quaternion, equals(quaternion));
        expect(attitude.timestamp, equals(timestamp));
      });

      test('should create comprehensive device motion data', () {
        final timestamp = DateTime.now();
        final attitude = DeviceAttitude(
          roll: 0.0,
          pitch: 0.0,
          yaw: 0.0,
          quaternion: const MotionQuaternion(),
          rotationMatrix: const MotionRotationMatrix(),
          timestamp: timestamp,
        );
        const gravity = MotionVector(x: 0.0, y: 0.0, z: -9.8);
        const userAcceleration = MotionVector(x: 0.1, y: 0.0, z: 0.0);

        final motionData = DeviceMotionData(
          attitude: attitude,
          gravity: gravity,
          userAcceleration: userAcceleration,
          rotationRate: const MotionVector(),
          magneticField: const MotionVector(),
          timestamp: timestamp,
        );

        expect(motionData.gravity.z, equals(-9.8));
        expect(motionData.userAcceleration.x, equals(0.1));
        expect(motionData.timestamp, equals(timestamp));
        expect(motionData.confidence, equals(1.0));
      });

      test('should validate device motion data structure', () {
        final timestamp = DateTime.now();
        final attitude = DeviceAttitude(
          roll: 0.1,
          pitch: 0.2,
          yaw: 0.3,
          quaternion: const MotionQuaternion(),
          rotationMatrix: const MotionRotationMatrix(),
          timestamp: timestamp,
        );

        final motionData = DeviceMotionData(
          attitude: attitude,
          gravity: const MotionVector(x: 0.0, y: 0.0, z: -9.8),
          userAcceleration: const MotionVector(x: 0.1, y: 0.0, z: 0.0),
          rotationRate: const MotionVector(),
          magneticField: const MotionVector(),
          timestamp: timestamp,
        );

        expect(motionData.gravity.z, equals(-9.8));
        expect(motionData.userAcceleration.x, equals(0.1));
        expect(motionData.attitude.roll, equals(0.1));
        expect(motionData.confidence, equals(1.0));
      });
    });

    group('Motion Sensor Status Tests', () {
      test('should track motion sensor availability', () {
        const status = MotionSensorStatus(
          isAccelerometerAvailable: true,
          isGyroscopeAvailable: true,
          isMagnetometerAvailable: false,
          isDeviceMotionAvailable: true,
        );

        expect(status.isAccelerometerAvailable, isTrue);
        expect(status.isGyroscopeAvailable, isTrue);
        expect(status.isMagnetometerAvailable, isFalse);
        expect(status.isDeviceMotionAvailable, isTrue);
      });

      test('should track motion sensor active state', () {
        const status = MotionSensorStatus(
          isDeviceMotionAvailable: true,
          isDeviceMotionActive: true,
          isAccelerometerActive: false,
        );

        expect(status.isDeviceMotionActive, isTrue);
        expect(status.isAccelerometerActive, isFalse);
      });

      test('should serialize motion sensor status', () {
        const status = MotionSensorStatus(
          isAccelerometerAvailable: true,
          isGyroscopeAvailable: true,
          isMagnetometerAvailable: true,
          isDeviceMotionAvailable: true,
          isAccelerometerActive: true,
          isGyroscopeActive: true,
          isMagnetometerActive: false,
          isDeviceMotionActive: true,
          errorMessage: 'Test error',
        );

        final json = status.toJson();
        final deserializedStatus = MotionSensorStatus.fromJson(json);

        expect(deserializedStatus.isAccelerometerAvailable, isTrue);
        expect(deserializedStatus.isMagnetometerActive, isFalse);
        expect(deserializedStatus.errorMessage, equals('Test error'));
      });
    });

    group('Motion Scan Session Tests', () {
      test('should create motion scan session', () {
        const config = MotionConfiguration();
        final startTime = DateTime.now();

        final session = MotionScanSession(
          sessionId: 'session_123',
          roomId: 'room_456',
          configuration: config,
          startTime: startTime,
          status: MotionScanStatus.scanning,
        );

        expect(session.sessionId, equals('session_123'));
        expect(session.roomId, equals('room_456'));
        expect(session.status, equals(MotionScanStatus.scanning));
        expect(session.startTime, equals(startTime));
        expect(session.endTime, isNull);
        expect(session.motionSamples, isEmpty);
        expect(session.accelerometerSamples, isEmpty);
        expect(session.gyroscopeSamples, isEmpty);
        expect(session.magnetometerSamples, isEmpty);
      });

      test('should track motion scan metrics', () {
        const metrics = MotionScanMetrics(
          totalSamples: 1000,
          motionSamples: 800,
          averageConfidence: 0.95,
          scanDuration: 30.0,
          averageSampleRate: 33.3,
          motionIntensity: 0.2,
          rotationIntensity: 0.1,
        );

        expect(metrics.totalSamples, equals(1000));
        expect(metrics.motionSamples, equals(800));
        expect(metrics.averageConfidence, equals(0.95));
        expect(metrics.scanDuration, equals(30.0));
        expect(metrics.averageSampleRate, equals(33.3));
        expect(metrics.motionIntensity, equals(0.2));
        expect(metrics.rotationIntensity, equals(0.1));
      });

      test('should validate motion scan session structure', () {
        const config = MotionConfiguration();
        final startTime = DateTime.now();

        final session = MotionScanSession(
          sessionId: 'test_session',
          roomId: 'test_room',
          configuration: config,
          startTime: startTime,
          status: MotionScanStatus.completed,
          endTime: startTime.add(const Duration(minutes: 5)),
        );

        expect(session.sessionId, equals('test_session'));
        expect(session.roomId, equals('test_room'));
        expect(session.status, equals(MotionScanStatus.completed));
        expect(session.endTime, isNotNull);
        expect(session.configuration.accelerometerUpdateInterval, equals(60.0));
      });
    });

    group('Motion Detection Tests', () {
      test('should detect motion state and patterns', () {
        const linearAcceleration = MotionVector(x: 0.2, y: 0.0, z: 0.0);
        const angularVelocity = MotionVector(x: 0.0, y: 0.1, z: 0.0);
        final timestamp = DateTime.now();

        final detection = MotionDetectionResult(
          isMoving: true,
          motionMagnitude: 0.2,
          rotationMagnitude: 0.1,
          motionType: MotionType.walking,
          linearAcceleration: linearAcceleration,
          angularVelocity: angularVelocity,
          timestamp: timestamp,
          confidence: 0.9,
        );

        expect(detection.isMoving, isTrue);
        expect(detection.motionType, equals(MotionType.walking));
        expect(detection.confidence, equals(0.9));
        expect(detection.motionMagnitude, equals(0.2));
        expect(detection.rotationMagnitude, equals(0.1));
      });

      test('should handle different motion types', () {
        final timestamp = DateTime.now();

        final stationaryDetection = MotionDetectionResult(
          isMoving: false,
          motionMagnitude: 0.01,
          rotationMagnitude: 0.0,
          motionType: MotionType.stationary,
          linearAcceleration: const MotionVector(),
          angularVelocity: const MotionVector(),
          timestamp: timestamp,
        );

        final turningDetection = MotionDetectionResult(
          isMoving: true,
          motionMagnitude: 0.05,
          rotationMagnitude: 0.8,
          motionType: MotionType.turning,
          linearAcceleration: const MotionVector(),
          angularVelocity: const MotionVector(y: 0.8),
          timestamp: timestamp,
        );

        expect(stationaryDetection.motionType, equals(MotionType.stationary));
        expect(turningDetection.motionType, equals(MotionType.turning));
        expect(turningDetection.rotationMagnitude, equals(0.8));
      });

      test('should validate motion detection result structure', () {
        final timestamp = DateTime.now();
        final detection = MotionDetectionResult(
          isMoving: true,
          motionMagnitude: 0.3,
          rotationMagnitude: 0.2,
          motionType: MotionType.scanning,
          linearAcceleration: const MotionVector(x: 0.3),
          angularVelocity: const MotionVector(z: 0.2),
          timestamp: timestamp,
          confidence: 0.85,
        );

        expect(detection.isMoving, isTrue);
        expect(detection.motionType, equals(MotionType.scanning));
        expect(detection.confidence, equals(0.85));
        expect(detection.linearAcceleration.x, equals(0.3));
        expect(detection.angularVelocity.z, equals(0.2));
      });
    });

    group('Accelerometer Data Tests', () {
      test('should create accelerometer data', () {
        const acceleration = MotionVector(x: 0.5, y: -0.2, z: 9.8);
        final timestamp = DateTime.now();

        final accelerometerData = AccelerometerData(
          acceleration: acceleration,
          timestamp: timestamp,
          confidence: 0.95,
        );

        expect(accelerometerData.acceleration, equals(acceleration));
        expect(accelerometerData.confidence, equals(0.95));
        expect(accelerometerData.timestamp, equals(timestamp));
      });
    });

    group('Gyroscope Data Tests', () {
      test('should create gyroscope data', () {
        const rotationRate = MotionVector(x: 0.1, y: 0.2, z: 0.3);
        final timestamp = DateTime.now();

        final gyroscopeData = GyroscopeData(
          rotationRate: rotationRate,
          timestamp: timestamp,
          confidence: 0.9,
        );

        expect(gyroscopeData.rotationRate, equals(rotationRate));
        expect(gyroscopeData.confidence, equals(0.9));
        expect(gyroscopeData.timestamp, equals(timestamp));
      });
    });

    group('Magnetometer Data Tests', () {
      test('should create magnetometer data', () {
        const magneticField = MotionVector(x: 45.0, y: -23.0, z: 12.0);
        final timestamp = DateTime.now();

        final magnetometerData = MagnetometerData(
          magneticField: magneticField,
          timestamp: timestamp,
          confidence: 0.8,
          accuracy: MagneticFieldCalibrationAccuracy.high,
        );

        expect(magnetometerData.magneticField, equals(magneticField));
        expect(magnetometerData.confidence, equals(0.8));
        expect(magnetometerData.accuracy, equals(MagneticFieldCalibrationAccuracy.high));
        expect(magnetometerData.timestamp, equals(timestamp));
      });
    });

    group('Enum Serialization Tests', () {
      test('should serialize motion reference frames', () {
        const frame = MotionReferenceFrame.xMagneticNorthZVertical;
        expect(frame.toString(), contains('xMagneticNorthZVertical'));
      });

      test('should serialize motion scan status', () {
        const status = MotionScanStatus.scanning;
        expect(status.toString(), contains('scanning'));
      });

      test('should serialize motion types', () {
        const type = MotionType.walking;
        expect(type.toString(), contains('walking'));
      });

      test('should serialize magnetic field calibration accuracy', () {
        const accuracy = MagneticFieldCalibrationAccuracy.high;
        expect(accuracy.toString(), contains('high'));
      });

      test('should handle all motion reference frame values', () {
        const frames = [
          MotionReferenceFrame.xArbitraryZVertical,
          MotionReferenceFrame.xArbitraryCorrectedZVertical,
          MotionReferenceFrame.xMagneticNorthZVertical,
          MotionReferenceFrame.xTrueNorthZVertical,
        ];

        for (final frame in frames) {
          expect(frame, isA<MotionReferenceFrame>());
        }
      });

      test('should handle all motion scan status values', () {
        const statuses = [
          MotionScanStatus.idle,
          MotionScanStatus.initializing,
          MotionScanStatus.scanning,
          MotionScanStatus.processing,
          MotionScanStatus.completed,
          MotionScanStatus.error,
          MotionScanStatus.cancelled,
        ];

        for (final status in statuses) {
          expect(status, isA<MotionScanStatus>());
        }
      });

      test('should handle all motion type values', () {
        const types = [
          MotionType.stationary,
          MotionType.walking,
          MotionType.turning,
          MotionType.scanning,
          MotionType.rapid,
          MotionType.unknown,
        ];

        for (final type in types) {
          expect(type, isA<MotionType>());
        }
      });
    });

    group('Edge Cases and Data Validation', () {
      test('should handle empty motion scan session', () {
        final session = MotionScanSession(
          sessionId: 'empty',
          roomId: 'room',
          configuration: const MotionConfiguration(),
          startTime: DateTime.now(),
          motionSamples: const [],
          accelerometerSamples: const [],
          gyroscopeSamples: const [],
          magnetometerSamples: const [],
        );

        expect(session.motionSamples, isEmpty);
        expect(session.accelerometerSamples, isEmpty);
        expect(session.metrics.totalSamples, equals(0));
      });

      test('should handle motion data with extreme values', () {
        final timestamp = DateTime.now();
        const extremeVector = MotionVector(x: 1000.0, y: -1000.0, z: 0.0);
        final motionData = DeviceMotionData(
          attitude: DeviceAttitude(
            roll: 10.0, // Extreme roll
            pitch: -10.0, // Extreme pitch
            yaw: 20.0, // Extreme yaw
            quaternion: const MotionQuaternion(),
            rotationMatrix: const MotionRotationMatrix(),
            timestamp: timestamp,
          ),
          gravity: extremeVector,
          userAcceleration: extremeVector,
          rotationRate: extremeVector,
          magneticField: extremeVector,
          timestamp: timestamp,
        );

        // Should not throw exceptions with extreme values
        expect(motionData.userAcceleration.x, equals(1000.0));
        expect(motionData.attitude.roll, equals(10.0));
        expect(motionData.gravity.y, equals(-1000.0));
      });

      test('should handle zero motion vectors', () {
        const zeroVector = MotionVector(x: 0.0, y: 0.0, z: 0.0);

        expect(zeroVector.x, equals(0.0));
        expect(zeroVector.y, equals(0.0));
        expect(zeroVector.z, equals(0.0));
      });

      test('should handle default motion configuration values', () {
        const config = MotionConfiguration();

        expect(config.accelerometerUpdateInterval, isPositive);
        expect(config.gyroscopeUpdateInterval, isPositive);
        expect(config.magnetometerUpdateInterval, isPositive);
        expect(config.deviceMotionUpdateInterval, isPositive);
        expect(config.motionThreshold, isPositive);
        expect(config.maxSampleRate, isPositive);
        expect(config.bufferSize, isPositive);
      });
    });
  });
}
