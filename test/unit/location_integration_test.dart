import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic_mobile/domain/entities/location/location_data.dart';
import 'package:room_o_matic_mobile/domain/repositories/location_repository.dart';
import 'package:room_o_matic_mobile/domain/use_cases/location_use_cases.dart';
import 'package:room_o_matic_mobile/infrastructure/repositories/flutter_location_repository.dart';

void main() {
  group('Location Services Integration', () {
    late LocationRepository repository;
    late InitializeLocationServicesUseCase initializeUseCase;
    late GetCurrentLocationForScanUseCase getCurrentLocationUseCase;

    setUp(() {
      repository = FlutterLocationRepository();
      initializeUseCase = InitializeLocationServicesUseCase(repository);
      getCurrentLocationUseCase = GetCurrentLocationForScanUseCase(repository);
    });

    group('LocationData Entity', () {
      test('should create LocationData with required properties', () {
        // Arrange & Act
        final locationData = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        // Assert
        expect(locationData.latitude, equals(37.7749));
        expect(locationData.longitude, equals(-122.4194));
        expect(locationData.accuracy, equals(5.0));
        expect(locationData.source, equals(LocationSource.gps));
        expect(locationData.isIndoor, isFalse);
      });

      test('should assess location quality correctly', () {
        // Excellent quality (< 5m accuracy)
        final excellentLocation = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 2.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );
        expect(excellentLocation.quality, equals(LocationQuality.excellent));

        // Poor quality (> 50m accuracy)
        final poorLocation = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 100.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.network,
          metadata: null,
        );
        expect(poorLocation.quality, equals(LocationQuality.poor));
      });

      test('should determine if location is accurate for scanning', () {
        // Accurate location
        final accurateLocation = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );
        expect(accurateLocation.isAccurateForScanning, isTrue);

        // Inaccurate location
        final inaccurateLocation = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 50.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.network,
          metadata: null,
        );
        expect(inaccurateLocation.isAccurateForScanning, isFalse);
      });

      test('should determine if location is fresh', () {
        // Fresh location (recent timestamp)
        final freshLocation = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );
        expect(freshLocation.isFresh, isTrue);

        // Stale location (old timestamp)
        final staleLocation = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );
        expect(staleLocation.isFresh, isFalse);
      });

      test('should format coordinates correctly', () {
        // Act
        final locationData = LocationData(
          latitude: 37.774929,
          longitude: -122.419416,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        // Assert
        expect(
            locationData.coordinatesString, equals('37.774929, -122.419416'));
      });
    });

    group('IndoorLocationData Entity', () {
      test('should create IndoorLocationData with base location', () {
        // Arrange
        final baseLocation = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 3.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: true,
          source: LocationSource.wifi,
          metadata: null,
        );

        // Act
        final indoorLocation = IndoorLocationData(
          baseLocation: baseLocation,
          buildingId: 'building_123',
          floorLevel: '2',
          roomId: 'room_456',
          relativeX: 10.5,
          relativeY: 15.2,
          relativeZ: null,
          beaconId: 'beacon_789',
          beaconDistance: 5.0,
          method: IndoorPositioningMethod.wifi,
          additionalData: {'confidence': 0.85},
        );

        // Assert
        expect(indoorLocation.baseLocation, equals(baseLocation));
        expect(indoorLocation.buildingId, equals('building_123'));
        expect(indoorLocation.floorLevel, equals('2'));
        expect(indoorLocation.roomId, equals('room_456'));
        expect(indoorLocation.method, equals(IndoorPositioningMethod.wifi));
      });
    });

    group('LocationConfiguration Entity', () {
      test('should create LocationConfiguration with defaults', () {
        // Act
        const configuration = LocationConfiguration();

        // Assert
        expect(configuration.enableGPS, isTrue);
        expect(configuration.enableIndoorPositioning, isTrue);
        expect(configuration.desiredAccuracy, equals(LocationAccuracy.high));
        expect(
            configuration.updateInterval, equals(const Duration(seconds: 30)));
        expect(configuration.minimumAccuracy, equals(10.0));
        expect(configuration.maxAge, equals(const Duration(minutes: 5)));
        expect(configuration.enableBackgroundLocation, isTrue);
        expect(configuration.enableAddressResolution, isTrue);
      });

      test('should create LocationConfiguration with custom values', () {
        // Act
        const configuration = LocationConfiguration(
          enableGPS: false,
          enableIndoorPositioning: false,
          desiredAccuracy: LocationAccuracy.low,
          updateInterval: Duration(minutes: 1),
          minimumAccuracy: 20.0,
          maxAge: Duration(minutes: 10),
          enableBackgroundLocation: false,
          enableAddressResolution: false,
        );

        // Assert
        expect(configuration.enableGPS, isFalse);
        expect(configuration.enableIndoorPositioning, isFalse);
        expect(configuration.desiredAccuracy, equals(LocationAccuracy.low));
        expect(
            configuration.updateInterval, equals(const Duration(minutes: 1)));
        expect(configuration.minimumAccuracy, equals(20.0));
        expect(configuration.maxAge, equals(const Duration(minutes: 10)));
        expect(configuration.enableBackgroundLocation, isFalse);
        expect(configuration.enableAddressResolution, isFalse);
      });
    });

    group('FlutterLocationRepository', () {
      test(
          'should calculate distance between two locations using Haversine formula',
          () {
        // Arrange
        final location1 = LocationData(
          latitude: 37.7749, // San Francisco
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        final location2 = LocationData(
          latitude: 40.7128, // New York
          longitude: -74.0060,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        // Act
        final distance = repository.calculateDistance(location1, location2);

        // Assert
        // Distance between SF and NYC is approximately 4,130 km
        expect(distance, greaterThan(4000000)); // 4,000 km
        expect(distance, lessThan(5000000)); // 5,000 km
      });

      test('should return 0 for identical locations', () {
        // Arrange
        final location = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        // Act
        final distance = repository.calculateDistance(location, location);

        // Assert
        expect(distance, equals(0.0));
      });

      test('should return true when target is within radius', () {
        // Arrange
        final center = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        final target = LocationData(
          latitude: 37.7750, // Very close to center
          longitude: -122.4195,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        // Act
        final isWithinRadius =
            repository.isWithinRadius(center, target, 100); // 100 meters

        // Assert
        expect(isWithinRadius, isTrue);
      });

      test('should return false when target is outside radius', () {
        // Arrange
        final center = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        final target = LocationData(
          latitude: 40.7128, // New York - very far from center
          longitude: -74.0060,
          accuracy: 5.0,
          timestamp: DateTime.now(),
          altitude: null,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: null,
          isIndoor: false,
          source: LocationSource.gps,
          metadata: null,
        );

        // Act
        final isWithinRadius =
            repository.isWithinRadius(center, target, 1000); // 1 km

        // Assert
        expect(isWithinRadius, isFalse);
      });

      test('should return properly formatted metadata for scanning', () {
        // Arrange
        final location = LocationData(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 3.0,
          timestamp: DateTime.now(), // Use current timestamp for fresh test
          altitude: 10.0,
          altitudeAccuracy: null,
          heading: null,
          speed: null,
          speedAccuracy: null,
          address: 'San Francisco, CA',
          isIndoor: false,
          source: LocationSource.gps,
          metadata: {'provider': 'gps'},
        );

        // Act
        final metadata = repository.getScanMetadata(location);

        // Assert
        expect(metadata, contains('location'));
        expect(metadata, contains('platform'));

        final locationMeta = metadata['location'] as Map<String, dynamic>;
        expect(locationMeta['latitude'], equals(37.7749));
        expect(locationMeta['longitude'], equals(-122.4194));
        expect(locationMeta['accuracy'], equals(3.0));
        expect(locationMeta['source'], equals('gps'));
        expect(locationMeta['address'], equals('San Francisco, CA'));
        expect(locationMeta['altitude'], equals(10.0));
        expect(locationMeta['isAccurate'],
            isTrue); // 3.0m accuracy should be accurate
        expect(locationMeta['isFresh'],
            isTrue); // Recent timestamp should be fresh
      });

      test('should return platform metadata when location is null', () {
        // Act
        final metadata = repository.getScanMetadata(null);

        // Assert
        expect(metadata, contains('platform'));
        expect(metadata, isNot(contains('location')));

        final platformMeta = metadata['platform'] as Map<String, dynamic>;
        expect(platformMeta, contains('os'));
        expect(platformMeta, contains('version'));
      });
    });

    group('Location Use Cases', () {
      test('InitializeLocationServicesUseCase should be instantiatable', () {
        // Act & Assert
        expect(initializeUseCase, isNotNull);
        expect(initializeUseCase, isA<InitializeLocationServicesUseCase>());
      });

      test('GetCurrentLocationForScanUseCase should be instantiatable', () {
        // Act & Assert
        expect(getCurrentLocationUseCase, isNotNull);
        expect(
            getCurrentLocationUseCase, isA<GetCurrentLocationForScanUseCase>());
      });

      test('MonitorLocationDuringScanUseCase should be instantiatable', () {
        // Arrange
        final monitorUseCase = MonitorLocationDuringScanUseCase(repository);

        // Act & Assert
        expect(monitorUseCase, isNotNull);
        expect(monitorUseCase, isA<MonitorLocationDuringScanUseCase>());
      });

      test('GetLocationMetadataForScanUseCase should be instantiatable', () {
        // Arrange
        final metadataUseCase = GetLocationMetadataForScanUseCase(repository);

        // Act & Assert
        expect(metadataUseCase, isNotNull);
        expect(metadataUseCase, isA<GetLocationMetadataForScanUseCase>());
      });

      test('CalibrateIndoorPositioningUseCase should be instantiatable', () {
        // Arrange
        final calibrateUseCase = CalibrateIndoorPositioningUseCase(repository);

        // Act & Assert
        expect(calibrateUseCase, isNotNull);
        expect(calibrateUseCase, isA<CalibrateIndoorPositioningUseCase>());
      });
    });

    group('Location Enums', () {
      test('LocationSource should have all expected values', () {
        // Assert
        expect(LocationSource.values, contains(LocationSource.gps));
        expect(LocationSource.values, contains(LocationSource.network));
        expect(LocationSource.values, contains(LocationSource.passive));
        expect(LocationSource.values, contains(LocationSource.fused));
        expect(LocationSource.values, contains(LocationSource.wifi));
        expect(LocationSource.values, contains(LocationSource.bluetooth));
        expect(LocationSource.values, contains(LocationSource.beacon));
        expect(LocationSource.values, contains(LocationSource.manual));
      });

      test('LocationAccuracy should have all expected values', () {
        // Assert
        expect(LocationAccuracy.values, contains(LocationAccuracy.lowest));
        expect(LocationAccuracy.values, contains(LocationAccuracy.low));
        expect(LocationAccuracy.values, contains(LocationAccuracy.medium));
        expect(LocationAccuracy.values, contains(LocationAccuracy.high));
        expect(LocationAccuracy.values, contains(LocationAccuracy.best));
        expect(LocationAccuracy.values,
            contains(LocationAccuracy.bestForNavigation));
      });

      test('LocationQuality should have all expected values', () {
        // Assert
        expect(LocationQuality.values, contains(LocationQuality.poor));
        expect(LocationQuality.values, contains(LocationQuality.fair));
        expect(LocationQuality.values, contains(LocationQuality.good));
        expect(LocationQuality.values, contains(LocationQuality.excellent));
      });

      test('LocationServiceStatus should have all expected values', () {
        // Assert
        expect(LocationServiceStatus.values,
            contains(LocationServiceStatus.unknown));
        expect(LocationServiceStatus.values,
            contains(LocationServiceStatus.enabled));
        expect(LocationServiceStatus.values,
            contains(LocationServiceStatus.disabled));
        expect(LocationServiceStatus.values,
            contains(LocationServiceStatus.restricted));
        expect(LocationServiceStatus.values,
            contains(LocationServiceStatus.denied));
      });

      test('LocationPermissionStatus should have all expected values', () {
        // Assert
        expect(LocationPermissionStatus.values,
            contains(LocationPermissionStatus.unknown));
        expect(LocationPermissionStatus.values,
            contains(LocationPermissionStatus.granted));
        expect(LocationPermissionStatus.values,
            contains(LocationPermissionStatus.denied));
        expect(LocationPermissionStatus.values,
            contains(LocationPermissionStatus.deniedForever));
        expect(LocationPermissionStatus.values,
            contains(LocationPermissionStatus.restricted));
      });

      test('IndoorPositioningMethod should have all expected values', () {
        // Assert
        expect(IndoorPositioningMethod.values,
            contains(IndoorPositioningMethod.wifi));
        expect(IndoorPositioningMethod.values,
            contains(IndoorPositioningMethod.bluetooth));
        expect(IndoorPositioningMethod.values,
            contains(IndoorPositioningMethod.beacon));
        expect(IndoorPositioningMethod.values,
            contains(IndoorPositioningMethod.ultrasonic));
        expect(IndoorPositioningMethod.values,
            contains(IndoorPositioningMethod.magnetic));
        expect(IndoorPositioningMethod.values,
            contains(IndoorPositioningMethod.visual));
        expect(IndoorPositioningMethod.values,
            contains(IndoorPositioningMethod.fusion));
      });
    });
  });
}
