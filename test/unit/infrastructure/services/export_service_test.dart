// 🚀 Room-O-Matic Mobile: Export Service Tests
// Basic tests for export service functionality

import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic_mobile/domain/entities/export/export_data.dart'
    as export_data;

void main() {
  group('Export Data Tests', () {
    test('should create export configuration correctly', () {
      // Arrange & Act
      const config = export_data.ExportConfiguration(
        format: export_data.ExportFormat.json,
        scope: export_data.ExportScope.singleScan,
      );

      // Assert
      expect(config.format, equals(export_data.ExportFormat.json));
      expect(config.scope, equals(export_data.ExportScope.singleScan));
    });

    test('should create export request correctly', () {
      // Arrange
      const config = export_data.ExportConfiguration(
        format: export_data.ExportFormat.json,
        scope: export_data.ExportScope.singleScan,
      );

      // Act
      final request = export_data.ExportRequest(
        id: 'test-id',
        configuration: config,
        requestedAt: DateTime.now(),
        scanIds: ['scan-1'],
      );

      // Assert
      expect(request.id, equals('test-id'));
      expect(
          request.configuration.format, equals(export_data.ExportFormat.json));
      expect(request.scanIds, contains('scan-1'));
    });

    group('ExportFormat extensions', () {
      test('should provide correct file extensions', () {
        expect(export_data.ExportFormat.json.fileExtension, equals('.json'));
        expect(export_data.ExportFormat.pdf.fileExtension, equals('.pdf'));
        expect(export_data.ExportFormat.csv.fileExtension, equals('.csv'));
        expect(export_data.ExportFormat.obj.fileExtension, equals('.obj'));
        expect(export_data.ExportFormat.ply.fileExtension, equals('.ply'));
      });

      test('should provide correct MIME types', () {
        expect(
            export_data.ExportFormat.json.mimeType, equals('application/json'));
        expect(
            export_data.ExportFormat.pdf.mimeType, equals('application/pdf'));
        expect(export_data.ExportFormat.csv.mimeType, equals('text/csv'));
      });

      test('should identify format types correctly', () {
        expect(export_data.ExportFormat.json.isTextFormat, isTrue);
        expect(export_data.ExportFormat.pdf.isBinaryFormat, isTrue);
        expect(export_data.ExportFormat.ply.is3DFormat, isTrue);
        expect(export_data.ExportFormat.obj.is3DFormat, isTrue);
        expect(export_data.ExportFormat.json.is3DFormat, isFalse);
      });
    });

    group('ExportScope extensions', () {
      test('should identify scopes requiring selection', () {
        expect(export_data.ExportScope.singleScan.requiresSelection, isTrue);
        expect(export_data.ExportScope.multipleScan.requiresSelection, isTrue);
        expect(export_data.ExportScope.dateRange.requiresSelection, isTrue);
        expect(export_data.ExportScope.allScans.requiresSelection, isFalse);
      });
    });

    group('ExportStatus extensions', () {
      test('should identify status states correctly', () {
        expect(export_data.ExportStatus.processing.isActive, isTrue);
        expect(export_data.ExportStatus.completed.isComplete, isTrue);
        expect(export_data.ExportStatus.failed.hasError, isTrue);
        expect(export_data.ExportStatus.pending.isCancellable, isTrue);
        expect(export_data.ExportStatus.completed.isCancellable, isFalse);
      });
    });
  });
}
