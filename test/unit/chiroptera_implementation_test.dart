import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic_mobile/domain/entities/chiroptera/chiroptera_ping.dart';
import 'package:room_o_matic_mobile/domain/entities/chiroptera/chiroptera_session.dart';
import 'package:room_o_matic_mobile/domain/use_cases/chiroptera_use_cases.dart';

void main() {
  group('Chiroptera Implementation Tests', () {
    test('ChiropteraPing entity creation and validation', () {
      // Arrange
      final ping = ChiropteraPing(
        id: 'test-ping-1',
        timestamp: DateTime.now(),
        direction: PingDirection.forward,
        distance: 2.5,
        confidence: 0.85,
        timeOfFlight: 14550.0, // microseconds for 2.5m distance
        signalQuality: const SignalQuality(
          peakCorrelation: 0.8,
          signalToNoiseRatio: 25.0,
          echoClarity: 0.9,
          noiseLevel: -25.0,
          frequencyResponse: 0.85,
        ),
        processingTime: 15.5,
        environment: const ChiropteraEnvironment(
          temperature: 20.0,
          humidity: 45.0,
          ambientNoise: -35.0,
          speedOfSound: 343.0,
        ),
      );

      // Act & Assert
      expect(ping.id, equals('test-ping-1'));
      expect(ping.distance, equals(2.5));
      expect(ping.confidence, equals(0.85));
      expect(ping.direction, equals(PingDirection.forward));
      expect(ping.signalQuality.overallQuality, greaterThan(0.7));
      expect(ping.estimatedAccuracy, lessThan(0.1)); // Less than 10cm
      expect(ping.isDistanceValid, isTrue);
    });

    test('ChiropteraSession configuration validation', () {
      // Arrange
      const config = ChiropteraConfig.indoor;
      const capabilities = ChiropteraCapabilities(
        supportsUltrasonic: true,
        hasHardwareEchoCancellation: true,
        hasHardwareNoiseSuppression: true,
        supportsStereoAudio: false,
        hasHighQualityAudio: true,
        maxSampleRate: 48000,
        minSampleRate: 8000,
        supportedFormats: ['PCM', 'Float32'],
        audioLatency: 25.0,
      );

      final session = ChiropteraSession(
        sessionId: 'test-session-1',
        startTime: DateTime.now(),
        config: config,
        state: ChiropteraSessionState.ready,
        capabilities: capabilities,
      );

      // Act & Assert
      expect(session.isActive, isTrue);
      expect(session.hasOptimalConfiguration, isTrue);
      expect(session.successRate, equals(0.0)); // No pings yet
      expect(capabilities.isCompatibleWith(config), isTrue);
    });

    test('PingDirection normalization', () {
      // Arrange
      const direction = PingDirection(x: 3.0, y: 4.0, z: 0.0);

      // Act
      final normalized = direction.normalized;

      // Assert
      expect(normalized.x, closeTo(0.6, 0.001)); // 3/5
      expect(normalized.y, closeTo(0.8, 0.001)); // 4/5
      expect(normalized.z, closeTo(0.0, 0.001));

      // Verify magnitude is 1
      final magnitude = (normalized.x * normalized.x +
          normalized.y * normalized.y +
          normalized.z * normalized.z);
      expect(magnitude, closeTo(1.0, 0.001));
    });

    test('SignalQuality overall quality calculation', () {
      // Arrange
      const signalQuality = SignalQuality(
        peakCorrelation: 0.9,
        signalToNoiseRatio: 30.0,
        echoClarity: 0.8,
        noiseLevel: -30.0,
        frequencyResponse: 0.75,
      );

      // Act
      final overallQuality = signalQuality.overallQuality;

      // Assert
      expect(overallQuality, greaterThan(0.8)); // High quality
      expect(overallQuality, lessThanOrEqualTo(1.0));
    });

    test('ChiropteraEnvironment speed of sound calculation', () {
      // Arrange
      const environment = ChiropteraEnvironment(
        temperature: 20.0,
        humidity: 50.0,
      );

      // Act
      final speedOfSound = environment.calculatedSpeedOfSound;

      // Assert
      expect(speedOfSound, closeTo(343.0, 5.0)); // Should be close to standard
    });

    test('FrequencyRange contains method', () {
      // Arrange
      const range = FrequencyRange(
        minFrequency: 18000.0,
        maxFrequency: 22000.0,
        qualityRating: 0.9,
        description: 'Ultrasonic range',
      );

      // Act & Assert
      expect(range.contains(19000.0), isTrue);
      expect(range.contains(17000.0), isFalse);
      expect(range.contains(23000.0), isFalse);
      expect(range.bandwidth, equals(4000.0));
    });

    test('ChiropteraDistanceMeasurement reliability assessment', () {
      // Arrange
      const measurement = ChiropteraDistanceMeasurement(
        distance: 3.2,
        confidence: 0.85,
        quality: 0.8,
        standardDeviation: 0.03, // 3cm variation
        sampleCount: 5,
        direction: PingDirection.forward,
        pings: [], // Empty for test
      );

      // Act & Assert
      expect(measurement.isReliable, isTrue);
      expect(measurement.estimatedAccuracy,
          lessThan(0.11)); // Less than 11cm (accounting for floating point)
    });

    test('ChiropteraException creation and formatting', () {
      // Arrange
      const exception = ChiropteraException(
        'Test error message',
        code: 'TEST_ERROR',
      );

      // Act & Assert
      expect(exception.message, equals('Test error message'));
      expect(exception.code, equals('TEST_ERROR'));
      expect(exception.toString(), contains('ChiropteraException'));
      expect(exception.toString(), contains('TEST_ERROR'));
    });

    test('Configuration presets validation', () {
      // Arrange
      const indoorConfig = ChiropteraConfig.indoor;
      const outdoorConfig = ChiropteraConfig.outdoor;

      // Act & Assert
      // Indoor config should be optimized for shorter ranges
      expect(indoorConfig.maxRange, lessThan(outdoorConfig.maxRange));
      expect(indoorConfig.qualityThreshold,
          greaterThan(outdoorConfig.qualityThreshold));

      // Outdoor config should have more samples for accuracy
      expect(outdoorConfig.averagingSamples,
          greaterThan(indoorConfig.averagingSamples));
      expect(
          outdoorConfig.chirpDuration, greaterThan(indoorConfig.chirpDuration));
    });
  });
}
