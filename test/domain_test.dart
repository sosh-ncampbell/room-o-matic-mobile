import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic_mobile/domain/entities/room_scan.dart';
import 'package:room_o_matic_mobile/domain/value_objects/measurement.dart';
import 'package:room_o_matic_mobile/domain/value_objects/point_3d.dart';

void main() {
  group('Domain Layer Tests', () {
    test('RoomScan entity creation', () {
      final now = DateTime.now();
      final scan = RoomScan(
        id: 'test-id',
        name: 'Test Room',
        createdAt: now,
        updatedAt: now,
        roomType: RoomType.livingRoom,
        pointCloud: [],
        measurements: {},
        status: ScanStatus.draft,
      );

      expect(scan.id, equals('test-id'));
      expect(scan.name, equals('Test Room'));
      expect(scan.roomType, equals(RoomType.livingRoom));
      expect(scan.status, equals(ScanStatus.draft));
      expect(scan.isArchived, isFalse);
    });

    test('Measurement value object creation', () {
      final measurement = Measurement(
        value: 3.5,
        unit: MeasurementUnit.meters,
        accuracy: 0.02,
        timestamp: DateTime.now(),
      );

      expect(measurement.value, equals(3.5));
      expect(measurement.unit, equals(MeasurementUnit.meters));
      expect(measurement.accuracy, equals(0.02));
      expect(measurement.isEstimated, isFalse);
    });

    test('Point3D distance calculation', () {
      const point1 = Point3D(x: 0, y: 0, z: 0);
      const point2 = Point3D(x: 3, y: 4, z: 0);

      final distance = point1.distanceTo(point2);
      expect(distance, closeTo(5.0, 0.001)); // 3-4-5 triangle
    });

    test('Point3D midpoint calculation', () {
      const point1 = Point3D(x: 0, y: 0, z: 0);
      const point2 = Point3D(x: 10, y: 20, z: 30);

      final midpoint = point1.midpointTo(point2);
      expect(midpoint.x, equals(5.0));
      expect(midpoint.y, equals(10.0));
      expect(midpoint.z, equals(15.0));
    });

    test('MeasurementUnit conversions', () {
      expect(MeasurementUnit.meters.toMeters, equals(1.0));
      expect(MeasurementUnit.centimeters.toMeters, equals(0.01));
      expect(MeasurementUnit.feet.toMeters, closeTo(0.3048, 0.0001));
      expect(MeasurementUnit.inches.toMeters, closeTo(0.0254, 0.0001));
    });

    test('RoomType display names', () {
      expect(RoomType.livingRoom.displayName, equals('Living Room'));
      expect(RoomType.bedroom.displayName, equals('Bedroom'));
      expect(RoomType.kitchen.displayName, equals('Kitchen'));
    });

    test('ScanStatus properties', () {
      expect(ScanStatus.inProgress.isActive, isTrue);
      expect(ScanStatus.processing.isActive, isTrue);
      expect(ScanStatus.completed.isComplete, isTrue);
      expect(ScanStatus.failed.hasError, isTrue);
      expect(ScanStatus.draft.isActive, isFalse);
    });
  });
}
