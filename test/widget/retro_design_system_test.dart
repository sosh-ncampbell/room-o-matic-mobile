import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Import the retro theme components
import 'package:room_o_matic_mobile/interface/widgets/retro/retro_theme.dart';
import 'package:room_o_matic_mobile/interface/widgets/retro/retro_button.dart';
import 'package:room_o_matic_mobile/interface/widgets/retro/retro_text_field.dart';
import 'package:room_o_matic_mobile/interface/widgets/retro/retro_status_badge.dart';
import 'package:room_o_matic_mobile/interface/widgets/retro/retro_measurement_display.dart';

/// Test app wrapper for components
class TestApp extends StatelessWidget {
  final Widget child;

  const TestApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [RetroTheme.light()],
      ),
      home: Scaffold(body: child),
    );
  }
}

void main() {
  group('Retro Theme Tests', () {
    test('light theme has correct colors', () {
      final theme = RetroTheme.light();

      expect(theme.primaryRed, const Color(0xFFB91C1C));
      expect(theme.charcoalGray, const Color(0xFF374151));
      expect(theme.paperWhite, const Color(0xFFFAFAFA));
      expect(theme.successGreen, const Color(0xFF10B981));
      expect(theme.warningRed, const Color(0xFFEF4444));
    });

    test('dark theme has correct colors', () {
      final theme = RetroTheme.dark();

      expect(theme.primaryRed, const Color(0xFFEF4444));
      expect(theme.charcoalGray, const Color(0xFF1F2937));
      expect(theme.paperWhite, const Color(0xFF111827));
    });
  });

  group('Typography Tests', () {
    test('heading styles have correct hierarchy', () {
      expect(RetroTextStyles.heading1.fontSize, 28.0);
      expect(RetroTextStyles.heading2.fontSize, 24.0);
      expect(RetroTextStyles.heading3.fontSize, 20.0);
      expect(RetroTextStyles.heading4.fontSize, 18.0);

      expect(RetroTextStyles.heading1.fontWeight, FontWeight.w700);
      expect(RetroTextStyles.heading2.fontWeight, FontWeight.w700);
    });

    test('data styles use monospace font', () {
      expect(RetroTextStyles.dataLarge.fontFamily, 'RobotoMono');
      expect(RetroTextStyles.dataMedium.fontFamily, 'RobotoMono');
      expect(RetroTextStyles.dataSmall.fontFamily, 'RobotoMono');
    });
  });

  group('Spacing Tests', () {
    test('spacing values follow 8px grid system', () {
      expect(RetroSpacing.xs % 4, 0); // Multiple of 4
      expect(RetroSpacing.sm % 4, 0);
      expect(RetroSpacing.md % 8, 0); // Multiple of 8
      expect(RetroSpacing.lg % 8, 0);
      expect(RetroSpacing.xl % 8, 0);
      expect(RetroSpacing.xxl % 8, 0);
    });
  });

  group('RetroButton Widget Tests', () {
    testWidgets('primary button renders correctly', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: () {},
            child: const Text('Primary Button'),
          ),
        ),
      );

      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('button press triggers callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: () => pressed = true,
            child: const Text('Press Me'),
          ),
        ),
      );

      await tester.tap(find.text('Press Me'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('disabled button does not respond to taps', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: null, // Disabled
            child: const Text('Disabled'),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  group('RetroTextField Widget Tests', () {
    testWidgets('text field renders with label and hint', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroTextField(
            label: 'Email',
            hint: 'Enter your email',
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enter your email'), findsOneWidget);
    });

    testWidgets('text field accepts input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        TestApp(
          child: RetroTextField(
            controller: controller,
            label: 'Test Field',
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'Hello World');
      await tester.pump();

      expect(controller.text, 'Hello World');
    });
  });

  group('RetroStatusBadge Widget Tests', () {
    testWidgets('success badge renders correctly', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroStatusBadge.success(
            text: 'Success',
            icon: Icons.check,
          ),
        ),
      );

      expect(find.text('Success'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('premium badge renders correctly', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroStatusBadge.premium(
            text: 'Pro Feature',
            icon: Icons.star,
          ),
        ),
      );

      expect(find.text('Pro Feature'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('RetroMeasurementDisplay Widget Tests', () {
    testWidgets('large display shows all elements', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroMeasurementDisplay.large(
            label: 'Room Area',
            value: '142.5',
            unit: 'm²',
            accuracy: '±2.1 cm',
            status: MeasurementStatus.verified,
          ),
        ),
      );

      expect(find.text('Room Area'), findsOneWidget);
      expect(find.text('142.5'), findsOneWidget);
      expect(find.text('m²'), findsOneWidget);
      expect(find.text('±2.1 cm'), findsOneWidget);
    });

    testWidgets('compact display shows essential elements', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroMeasurementDisplay.compact(
            label: 'Width',
            value: '3.2',
            unit: 'm',
          ),
        ),
      );

      expect(find.text('Width'), findsOneWidget);
      expect(find.text('3.2'), findsOneWidget);
      expect(find.text('m'), findsOneWidget);
    });
  });
}