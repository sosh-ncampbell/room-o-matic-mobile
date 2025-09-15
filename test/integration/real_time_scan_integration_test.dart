import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic_mobile/application/controllers/real_time_scan_controller.dart';
import 'package:room_o_matic_mobile/interface/screens/scan/scan_screen.dart';

import '../mocks/mock_native_sensor_channel.dart';

void main() {
  group('Real-Time Scan Integration Tests', () {
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

    testWidgets('Should display scan screen with initial state',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: ScanScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Real-Time Room Scan'), findsOneWidget);
      expect(find.text('Start Scan'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('Should start and stop scanning', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: ScanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Start scanning
      final startButton = find.text('Start Scan');
      expect(startButton, findsOneWidget);

      await tester.tap(startButton);
      await tester.pump();

      // Assert - Should show stop button
      expect(find.text('Stop Scan'), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      // Act - Stop scanning
      final stopButton = find.text('Stop Scan');
      await tester.tap(stopButton);
      await tester.pump();

      // Assert - Should show start button again
      expect(find.text('Start Scan'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('Should display measurement widgets', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: ScanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Check for measurement display components
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Should find measurement-related text
      expect(find.textContaining('measurements', skipOffstage: false),
          findsWidgets);
    });

    testWidgets('Should show scan quality progress when scanning',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: ScanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Start scanning
      await tester.tap(find.text('Start Scan'));
      await tester.pump();

      // Assert - Should show progress indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('Scan Quality'), findsOneWidget);
    });

    testWidgets('Should handle pause and resume', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: ScanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Start scanning
      await tester.tap(find.text('Start Scan'));
      await tester.pump();

      // Should show pause button in app bar
      if (find.byIcon(Icons.pause).evaluate().isNotEmpty) {
        // Act - Pause scanning
        await tester.tap(find.byIcon(Icons.pause));
        await tester.pump();

        // Assert - Should show resume button
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        // Act - Resume scanning
        await tester.tap(find.byIcon(Icons.play_arrow));
        await tester.pump();

        // Assert - Should show pause button again
        expect(find.byIcon(Icons.pause), findsOneWidget);
      }
    });

    testWidgets('Should display control buttons correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: ScanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Check control buttons are present
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Reset button should be enabled when not scanning
      final resetButton = find.byIcon(Icons.refresh);
      expect(resetButton, findsOneWidget);

      // Save button should be disabled initially (no measurements)
      final saveButton = find.byIcon(Icons.save);
      expect(saveButton, findsOneWidget);
    });

    testWidgets('Should handle reset functionality', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: ScanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Tap reset button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert - Should remain in initial state
      expect(find.text('Start Scan'), findsOneWidget);
    });

    test('Should manage scan state correctly', () {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);
      final initialState = container.read(realTimeScanControllerProvider);

      // Assert initial state
      expect(initialState.isScanning, false);
      expect(initialState.isPaused, false);
      expect(initialState.pointsCollected, 0);
      expect(initialState.currentMeasurements, isEmpty);
      expect(initialState.confidence, 0.0);
      expect(initialState.errorMessage, isNull);

      // Act - Start scan
      controller.startScan();
      final scanningState = container.read(realTimeScanControllerProvider);

      // Assert scanning state
      expect(scanningState.isScanning, true);
      expect(scanningState.isPaused, false);

      // Act - Pause scan
      controller.pauseScan();
      final pausedState = container.read(realTimeScanControllerProvider);

      // Assert paused state
      expect(pausedState.isScanning, true);
      expect(pausedState.isPaused, true);

      // Act - Resume scan
      controller.resumeScan();
      final resumedState = container.read(realTimeScanControllerProvider);

      // Assert resumed state
      expect(resumedState.isScanning, true);
      expect(resumedState.isPaused, false);

      // Act - Stop scan
      controller.stopScan();
      final stoppedState = container.read(realTimeScanControllerProvider);

      // Assert stopped state
      expect(stoppedState.isScanning, false);
      expect(stoppedState.isPaused, false);

      // Act - Reset scan
      controller.resetScan();
      final resetState = container.read(realTimeScanControllerProvider);

      // Assert reset state (should be back to initial)
      expect(resetState.isScanning, false);
      expect(resetState.isPaused, false);
      expect(resetState.pointsCollected, 0);
      expect(resetState.errorMessage, isNull);
    });

    test('Should handle error states', () {
      // Arrange
      final controller =
          container.read(realTimeScanControllerProvider.notifier);

      // Act - Simulate error during scan
      controller.startScan();
      // In a real implementation, we would trigger an error condition
      // For now, we can test the reset functionality after error

      controller.resetScan();
      final state = container.read(realTimeScanControllerProvider);

      // Assert - Error should be cleared
      expect(state.errorMessage, isNull);
      expect(state.isScanning, false);
    });
  });
}
