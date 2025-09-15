# 🧪 Room-O-Matic Design System Testing Guide

> *Complete testing strategy for the retro business design system*

---

## 🎯 **Testing Overview**

### Testing Strategy
```text
📱 Unit Tests: Individual component behavior and styling
🔧 Widget Tests: Component integration and interaction
🎨 Golden Tests: Visual consistency across devices
⚡ Performance Tests: Rendering and animation performance
♿ Accessibility Tests: Contrast, semantics, and usability
📊 Integration Tests: Complete user flows
```

### Test Coverage Goals
- **Components**: 95%+ code coverage
- **Theme System**: 100% coverage
- **Interactions**: All user interactions tested
- **Visual Regression**: Golden tests for all components
- **Accessibility**: WCAG AA compliance

---

## 🔧 **Unit Testing**

### RetroTheme Testing
```dart
// test/unit/retro_theme_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_theme.dart';

void main() {
  group('RetroTheme', () {
    test('light theme has correct colors', () {
      final theme = RetroTheme.light();

      expect(theme.primaryRed, const Color(0xFFB91C1C));
      expect(theme.charcoalGray, const Color(0xFF374151));
      expect(theme.paperWhite, const Color(0xFFFAFAFA));
      expect(theme.successGreen, const Color(0xFF059669));
      expect(theme.warningRed, const Color(0xFFDC2626));
    });

    test('dark theme has correct colors', () {
      final theme = RetroTheme.dark();

      expect(theme.primaryRed, const Color(0xFFEF4444));
      expect(theme.charcoalGray, const Color(0xFF1F2937));
      expect(theme.paperWhite, const Color(0xFF111827));
    });

    test('color contrast meets accessibility standards', () {
      final theme = RetroTheme.light();

      // Test primary red on white background
      final contrast = _calculateContrast(theme.primaryRed, theme.paperWhite);
      expect(contrast, greaterThan(4.5)); // WCAG AA standard

      // Test charcoal gray on white background
      final textContrast = _calculateContrast(theme.charcoalGray, theme.paperWhite);
      expect(textContrast, greaterThan(7.0)); // WCAG AAA standard
    });
  });
}

// Helper function for contrast calculation
double _calculateContrast(Color color1, Color color2) {
  final lum1 = _getLuminance(color1);
  final lum2 = _getLuminance(color2);
  final lighter = math.max(lum1, lum2);
  final darker = math.min(lum1, lum2);
  return (lighter + 0.05) / (darker + 0.05);
}

double _getLuminance(Color color) {
  final r = color.red / 255.0;
  final g = color.green / 255.0;
  final b = color.blue / 255.0;

  final rs = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4);
  final gs = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4);
  final bs = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4);

  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
}
```

### Typography Testing
```dart
// test/unit/retro_text_styles_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_theme.dart';

void main() {
  group('RetroTextStyles', () {
    test('heading styles have correct hierarchy', () {
      expect(RetroTextStyles.heading1.fontSize, 32.0);
      expect(RetroTextStyles.heading2.fontSize, 24.0);
      expect(RetroTextStyles.heading3.fontSize, 20.0);
      expect(RetroTextStyles.heading4.fontSize, 18.0);

      // Verify font weights
      expect(RetroTextStyles.heading1.fontWeight, FontWeight.w700);
      expect(RetroTextStyles.heading2.fontWeight, FontWeight.w600);
    });

    test('body text styles are readable', () {
      expect(RetroTextStyles.bodyLarge.fontSize, 18.0);
      expect(RetroTextStyles.bodyMedium.fontSize, 16.0);
      expect(RetroTextStyles.bodySmall.fontSize, 14.0);

      // Verify line heights for readability
      expect(RetroTextStyles.bodyMedium.height, 1.5);
    });

    test('data styles are appropriate for measurements', () {
      expect(RetroTextStyles.dataLarge.fontSize, 48.0);
      expect(RetroTextStyles.dataMedium.fontSize, 24.0);
      expect(RetroTextStyles.dataSmall.fontSize, 16.0);

      // Verify tabular nums for consistent number display
      expect(
        RetroTextStyles.dataLarge.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });
}
```

### Spacing Testing
```dart
// test/unit/retro_spacing_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_theme.dart';

void main() {
  group('RetroSpacing', () {
    test('spacing values follow 8px grid system', () {
      expect(RetroSpacing.xs % 4, 0); // Multiple of 4
      expect(RetroSpacing.sm % 4, 0);
      expect(RetroSpacing.md % 8, 0); // Multiple of 8
      expect(RetroSpacing.lg % 8, 0);
      expect(RetroSpacing.xl % 8, 0);
      expect(RetroSpacing.xxl % 8, 0);
    });

    test('spacing hierarchy is logical', () {
      expect(RetroSpacing.xs, lessThan(RetroSpacing.sm));
      expect(RetroSpacing.sm, lessThan(RetroSpacing.md));
      expect(RetroSpacing.md, lessThan(RetroSpacing.lg));
      expect(RetroSpacing.lg, lessThan(RetroSpacing.xl));
      expect(RetroSpacing.xl, lessThan(RetroSpacing.xxl));
    });

    test('padding constants are appropriate', () {
      final cardPadding = RetroSpacing.cardPadding;
      expect(cardPadding.horizontal, 16.0);
      expect(cardPadding.vertical, 16.0);

      final screenPadding = RetroSpacing.screenPadding;
      expect(screenPadding.horizontal, 16.0);
      expect(screenPadding.vertical, 0.0);
    });
  });
}
```

---

## 🎨 **Widget Testing**

### RetroButton Testing
```dart
// test/widget/retro_button_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_button.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_theme.dart';

import '../helpers/test_app.dart';

void main() {
  group('RetroButton', () {
    testWidgets('primary button renders with correct styling', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: () {},
            child: const Text('Primary Button'),
          ),
        ),
      );

      // Find the button
      expect(find.text('Primary Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Test styling
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final theme = RetroTheme.light();

      expect(
        button.style?.backgroundColor?.resolve({}),
        theme.primaryRed,
      );
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
      bool pressed = false;

      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: null, // Disabled
            child: const Text('Disabled'),
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('loading button shows progress indicator', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: () {},
            isLoading: true,
            child: const Text('Loading'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('outline button has correct border', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.outline(
            onPressed: () {},
            child: const Text('Outline'),
          ),
        ),
      );

      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final theme = RetroTheme.light();

      expect(
        button.style?.side?.resolve({}),
        BorderSide(color: theme.primaryRed, width: 1.5),
      );
    });

    testWidgets('danger button has warning color', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.danger(
            onPressed: () {},
            child: const Text('Delete'),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final theme = RetroTheme.light();

      expect(
        button.style?.backgroundColor?.resolve({}),
        theme.warningRed,
      );
    });

    testWidgets('text button has no background', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.text(
            onPressed: () {},
            child: const Text('Text Button'),
          ),
        ),
      );

      final button = tester.widget<TextButton>(find.byType(TextButton));

      expect(
        button.style?.backgroundColor?.resolve({}),
        Colors.transparent,
      );
    });
  });
}
```

### RetroTextField Testing
```dart
// test/widget/retro_text_field_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_text_field.dart';

import '../helpers/test_app.dart';

void main() {
  group('RetroTextField', () {
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

      await tester.enterText(find.byType(TextField), 'Hello World');
      await tester.pump();

      expect(controller.text, 'Hello World');
    });

    testWidgets('validation error is displayed', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Form(
            child: RetroTextField(
              label: 'Required Field',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'This field is required';
                }
                return null;
              },
            ),
          ),
        ),
      );

      // Submit form without entering text
      await tester.pump();

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('prefix icon is displayed', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroTextField(
            label: 'Email',
            prefixIcon: Icons.email,
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('obscure text hides input', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroTextField(
            label: 'Password',
            obscureText: true,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('onChanged callback is triggered', (tester) async {
      String? changedValue;

      await tester.pumpWidget(
        TestApp(
          child: RetroTextField(
            label: 'Test',
            onChanged: (value) => changedValue = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Changed');
      await tester.pump();

      expect(changedValue, 'Changed');
    });
  });
}
```

### RetroStatusBadge Testing
```dart
// test/widget/retro_status_badge_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_status_badge.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_theme.dart';

import '../helpers/test_app.dart';

void main() {
  group('RetroStatusBadge', () {
    testWidgets('success badge has correct styling', (tester) async {
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

      // Check background color
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Success'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      final theme = RetroTheme.light();
      expect(decoration.color, theme.successGreen.withOpacity(0.1));
    });

    testWidgets('premium badge has star styling', (tester) async {
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

    testWidgets('warning badge has alert styling', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroStatusBadge.warning(
            text: 'Warning',
            icon: Icons.warning,
          ),
        ),
      );

      expect(find.text('Warning'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('info badge has info styling', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroStatusBadge.info(
            text: 'Info',
            icon: Icons.info,
          ),
        ),
      );

      expect(find.text('Info'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });
}
```

### RetroMeasurementDisplay Testing
```dart
// test/widget/retro_measurement_display_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_measurement_display.dart';

import '../helpers/test_app.dart';

void main() {
  group('RetroMeasurementDisplay', () {
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
      expect(find.text('Verified'), findsOneWidget);
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

    testWidgets('status affects styling', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Column(
            children: [
              RetroMeasurementDisplay.large(
                label: 'Verified',
                value: '100',
                unit: 'm',
                status: MeasurementStatus.verified,
              ),
              RetroMeasurementDisplay.large(
                label: 'Error',
                value: '0',
                unit: 'm',
                status: MeasurementStatus.error,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
    });
  });
}
```

---

## 🎨 **Golden Testing**

### Golden Test Setup
```dart
// test/golden/golden_test_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_theme.dart';

class GoldenTestApp extends StatelessWidget {
  final Widget child;
  final ThemeMode themeMode;

  const GoldenTestApp({
    required this.child,
    this.themeMode = ThemeMode.light,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        extensions: [RetroTheme.light()],
      ),
      darkTheme: ThemeData.dark().copyWith(
        extensions: [RetroTheme.dark()],
      ),
      themeMode: themeMode,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }
}

void goldenTest(
  String description,
  Widget widget, {
  bool testDarkTheme = true,
  Size? surfaceSize,
}) {
  testWidgets('$description - light theme', (tester) async {
    await tester.pumpWidget(
      GoldenTestApp(
        themeMode: ThemeMode.light,
        child: widget,
      ),
    );

    if (surfaceSize != null) {
      await tester.binding.setSurfaceSize(surfaceSize);
    }

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GoldenTestApp),
      matchesGoldenFile('goldens/${description.toLowerCase().replaceAll(' ', '_')}_light.png'),
    );
  });

  if (testDarkTheme) {
    testWidgets('$description - dark theme', (tester) async {
      await tester.pumpWidget(
        GoldenTestApp(
          themeMode: ThemeMode.dark,
          child: widget,
        ),
      );

      if (surfaceSize != null) {
        await tester.binding.setSurfaceSize(surfaceSize);
      }

      await tester.pumpAndSettle();
      await expectLater(
        find.byType(GoldenTestApp),
        matchesGoldenFile('goldens/${description.toLowerCase().replaceAll(' ', '_')}_dark.png'),
      );
    });
  }
}
```

### Button Golden Tests
```dart
// test/golden/retro_button_golden_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_button.dart';

import 'golden_test_helper.dart';

void main() {
  group('RetroButton Golden Tests', () {
    goldenTest(
      'Primary Button',
      RetroButton.primary(
        onPressed: () {},
        child: const Text('Primary Button'),
      ),
    );

    goldenTest(
      'Outline Button',
      RetroButton.outline(
        onPressed: () {},
        child: const Text('Outline Button'),
      ),
    );

    goldenTest(
      'Danger Button',
      RetroButton.danger(
        onPressed: () {},
        child: const Text('Delete Account'),
      ),
    );

    goldenTest(
      'Text Button',
      RetroButton.text(
        onPressed: () {},
        child: const Text('Text Button'),
      ),
    );

    goldenTest(
      'Disabled Button',
      RetroButton.primary(
        onPressed: null,
        child: const Text('Disabled'),
      ),
    );

    goldenTest(
      'Loading Button',
      RetroButton.primary(
        onPressed: () {},
        isLoading: true,
        child: const Text('Loading'),
      ),
    );

    goldenTest(
      'Button with Icon',
      RetroButton.outline(
        onPressed: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Settings'),
          ],
        ),
      ),
    );

    goldenTest(
      'Button Sizes',
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RetroButton.primary(
            onPressed: () {},
            minimumSize: const Size(120, 32),
            child: const Text('Small'),
          ),
          const SizedBox(height: 16),
          RetroButton.primary(
            onPressed: () {},
            minimumSize: const Size(160, 48),
            child: const Text('Medium'),
          ),
          const SizedBox(height: 16),
          RetroButton.primary(
            onPressed: () {},
            minimumSize: const Size(200, 56),
            child: const Text('Large'),
          ),
        ],
      ),
    );
  });
}
```

### Form Golden Tests
```dart
// test/golden/form_golden_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_text_field.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_button.dart';

import 'golden_test_helper.dart';

void main() {
  group('Form Golden Tests', () {
    goldenTest(
      'Login Form',
      Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RetroTextField(
              label: 'Email',
              hint: 'you@company.com',
              prefixIcon: Icons.email,
            ),
            const SizedBox(height: 16),
            RetroTextField(
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            RetroButton.primary(
              onPressed: () {},
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
      surfaceSize: const Size(400, 600),
    );

    goldenTest(
      'Text Field States',
      Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RetroTextField(
              label: 'Normal Field',
              hint: 'Enter text',
            ),
            const SizedBox(height: 16),
            RetroTextField(
              label: 'Required Field',
              hint: 'This field is required',
              errorText: 'This field is required',
            ),
            const SizedBox(height: 16),
            RetroTextField(
              label: 'Success Field',
              hint: 'Valid input',
              prefixIcon: Icons.check_circle,
            ),
          ],
        ),
      ),
      surfaceSize: const Size(400, 600),
    );
  });
}
```

### Card Layout Golden Tests
```dart
// test/golden/card_layout_golden_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_measurement_display.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_status_badge.dart';

import 'golden_test_helper.dart';

void main() {
  group('Card Layout Golden Tests', () {
    goldenTest(
      'Measurement Card',
      Container(
        width: 300,
        child: RetroMeasurementDisplay.large(
          label: 'Room Area',
          value: '142.5',
          unit: 'm²',
          accuracy: '±2.1 cm',
          status: MeasurementStatus.verified,
        ),
      ),
      surfaceSize: const Size(400, 300),
    );

    goldenTest(
      'Status Badge Grid',
      Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            RetroStatusBadge.success(
              text: 'Verified',
              icon: Icons.verified,
            ),
            RetroStatusBadge.premium(
              text: 'Pro Feature',
              icon: Icons.star,
            ),
            RetroStatusBadge.warning(
              text: 'Warning',
              icon: Icons.warning,
            ),
            RetroStatusBadge.info(
              text: 'Trial Mode',
              icon: Icons.info,
            ),
          ],
        ),
      ),
      surfaceSize: const Size(400, 300),
    );
  });
}
```

---

## ⚡ **Performance Testing**

### Rendering Performance Tests
```dart
// test/performance/rendering_performance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_button.dart';

import '../helpers/test_app.dart';

void main() {
  group('Rendering Performance Tests', () {
    testWidgets('button renders within performance budget', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        TestApp(
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: RetroButton.primary(
                  onPressed: () {},
                  child: Text('Button $index'),
                ),
              );
            },
          ),
        ),
      );

      stopwatch.stop();

      // Should render 100 buttons in under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    testWidgets('scroll performance is smooth', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: ListView.builder(
            itemCount: 1000,
            itemBuilder: (context, index) {
              return RetroButton.outline(
                onPressed: () {},
                child: Text('Item $index'),
              );
            },
          ),
        ),
      );

      // Measure scroll performance
      final stopwatch = Stopwatch()..start();

      await tester.fling(
        find.byType(ListView),
        const Offset(0, -500),
        1000,
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      // Scrolling should settle quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });
  });
}
```

### Animation Performance Tests
```dart
// test/performance/animation_performance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_button.dart';

import '../helpers/test_app.dart';

void main() {
  group('Animation Performance Tests', () {
    testWidgets('button animation is smooth', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: () {},
            child: const Text('Animated Button'),
          ),
        ),
      );

      // Test tap animation
      await tester.press(find.byType(RetroButton));

      final frameCount = await tester.pumpAndSettle();

      // Animation should complete in reasonable frame count
      expect(frameCount, lessThan(10));
    });

    testWidgets('loading animation is efficient', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: () {},
            isLoading: true,
            child: const Text('Loading'),
          ),
        ),
      );

      // Let animation run for a bit
      await tester.pump(const Duration(milliseconds: 100));

      // Should show progress indicator without performance issues
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
```

---

## ♿ **Accessibility Testing**

### Semantic Testing
```dart
// test/accessibility/semantic_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_button.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_text_field.dart';

import '../helpers/test_app.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('buttons have proper semantics', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Column(
            children: [
              RetroButton.primary(
                onPressed: () {},
                child: const Text('Primary Action'),
              ),
              RetroButton.outline(
                onPressed: () {},
                child: const Text('Secondary Action'),
              ),
              RetroButton.danger(
                onPressed: () {},
                child: const Text('Delete Account'),
              ),
            ],
          ),
        ),
      );

      // Enable semantics
      final handle = tester.ensureSemantics();

      // Check button semantics
      expect(
        tester.getSemantics(find.text('Primary Action')),
        matchesSemantics(
          label: 'Primary Action',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      expect(
        tester.getSemantics(find.text('Delete Account')),
        matchesSemantics(
          label: 'Delete Account',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('text fields have proper labels', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Column(
            children: [
              RetroTextField(
                label: 'Email Address',
                hint: 'Enter your email',
              ),
              RetroTextField(
                label: 'Password',
                hint: 'Enter password',
                obscureText: true,
              ),
            ],
          ),
        ),
      );

      final handle = tester.ensureSemantics();

      // Check text field semantics
      expect(
        tester.getSemantics(find.byType(TextField).first),
        matchesSemantics(
          label: 'Email Address',
          hint: 'Enter your email',
          isTextField: true,
          hasShowOnScreenAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('disabled elements are properly marked', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroButton.primary(
            onPressed: null, // Disabled
            child: const Text('Disabled Button'),
          ),
        ),
      );

      final handle = tester.ensureSemantics();

      expect(
        tester.getSemantics(find.text('Disabled Button')),
        matchesSemantics(
          label: 'Disabled Button',
          isButton: true,
          isEnabled: false,
        ),
      );

      handle.dispose();
    });
  });
}
```

### Screen Reader Testing
```dart
// test/accessibility/screen_reader_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_measurement_display.dart';

import '../helpers/test_app.dart';

void main() {
  group('Screen Reader Tests', () {
    testWidgets('measurement display is readable', (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: RetroMeasurementDisplay.large(
            label: 'Room Area',
            value: '142.5',
            unit: 'square meters',
            accuracy: 'plus or minus 2.1 centimeters',
            status: MeasurementStatus.verified,
          ),
        ),
      );

      final handle = tester.ensureSemantics();

      // Verify the measurement is properly announced
      final semantics = tester.getSemantics(
        find.byType(RetroMeasurementDisplay),
      );

      expect(
        semantics.label,
        contains('Room Area 142.5 square meters'),
      );

      handle.dispose();
    });

    testWidgets('status changes are announced', (tester) async {
      // Test status change announcements
      await tester.pumpWidget(
        TestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  RetroMeasurementDisplay.large(
                    label: 'Scan Progress',
                    value: '75',
                    unit: 'percent',
                    status: MeasurementStatus.pending,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Update status - should announce change
                      });
                    },
                    child: const Text('Complete Scan'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Tap to change status
      await tester.tap(find.text('Complete Scan'));
      await tester.pumpAndSettle();

      // Verify status change is announced
      // This would require more complex setup with platform channels
    });
  });
}
```

---

## 📊 **Integration Testing**

### User Flow Testing
```dart
// integration_test/user_flows_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:room_o_matic/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Flow Integration Tests', () {
    testWidgets('complete login flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Fill login form
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@company.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // Submit form
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify navigation to dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('measurement creation flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to measurement screen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Start measurement
      await tester.tap(find.text('Start Scan'));
      await tester.pumpAndSettle();

      // Wait for scan completion (mock)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify results screen
      expect(find.text('Scan Complete'), findsOneWidget);
      expect(find.byType(RetroMeasurementDisplay), findsAtLeastNWidgets(1));
    });

    testWidgets('subscription upgrade flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to subscription screen
      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();

      // Select plan
      await tester.tap(find.text('Pro Plan'));
      await tester.pumpAndSettle();

      // Proceed to payment
      await tester.tap(find.text('Subscribe'));
      await tester.pumpAndSettle();

      // Verify payment screen
      expect(find.text('Payment'), findsOneWidget);
    });
  });
}
```

---

## 🛠️ **Test Helpers and Utilities**

### Test App Wrapper
```dart
// test/helpers/test_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_o_matic/interface/widgets/retro/retro_theme.dart';

class TestApp extends StatelessWidget {
  final Widget child;
  final List<Override> providerOverrides;

  const TestApp({
    required this.child,
    this.providerOverrides = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: providerOverrides,
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA),
          extensions: [RetroTheme.light()],
        ),
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }
}
```

### Mock Data Generators
```dart
// test/helpers/mock_data.dart
import 'package:room_o_matic/domain/entities/measurement.dart';

class MockDataGenerator {
  static MeasurementData generateMeasurement({
    String? label,
    double? value,
    String? unit,
    MeasurementStatus? status,
  }) {
    return MeasurementData(
      label: label ?? 'Test Measurement',
      value: value ?? 100.0,
      unit: unit ?? 'm',
      accuracy: 2.1,
      status: status ?? MeasurementStatus.verified,
    );
  }

  static List<MeasurementData> generateMeasurementList(int count) {
    return List.generate(count, (index) {
      return generateMeasurement(
        label: 'Measurement $index',
        value: (index + 1) * 10.0,
      );
    });
  }

  static UserAccount generateUserAccount({
    String? email,
    SubscriptionTier? tier,
  }) {
    return UserAccount(
      id: 'test-user-id',
      email: email ?? 'test@company.com',
      subscriptionTier: tier ?? SubscriptionTier.free,
      createdAt: DateTime.now(),
    );
  }
}
```

### Test Expectations
```dart
// test/helpers/custom_matchers.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

Matcher hasTextStyle(TextStyle expected) {
  return predicate<Text>((text) {
    return text.style?.fontSize == expected.fontSize &&
           text.style?.fontWeight == expected.fontWeight &&
           text.style?.color == expected.color;
  }, 'has text style matching $expected');
}

Matcher hasBackgroundColor(Color expected) {
  return predicate<Container>((container) {
    final decoration = container.decoration as BoxDecoration?;
    return decoration?.color == expected;
  }, 'has background color $expected');
}

Matcher isDisabled() {
  return predicate<Widget>((widget) {
    if (widget is ElevatedButton) {
      return widget.onPressed == null;
    } else if (widget is OutlinedButton) {
      return widget.onPressed == null;
    } else if (widget is TextButton) {
      return widget.onPressed == null;
    }
    return false;
  }, 'is disabled');
}
```

---

## 📋 **Test Execution Commands**

### Flutter Test Commands
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget/retro_button_test.dart

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run only unit tests
flutter test test/unit/

# Run only widget tests
flutter test test/widget/

# Run golden tests
flutter test test/golden/

# Update golden files
flutter test test/golden/ --update-goldens

# Run performance tests
flutter test test/performance/

# Run accessibility tests
flutter test test/accessibility/

# Run integration tests
flutter test integration_test/
```

### Test Coverage Analysis
```bash
# Generate detailed coverage report
flutter test --coverage
dart run coverage:format_coverage --lcov --in=coverage/test/ --out=coverage/lcov.info --packages=.packages --report-on=lib/

# View coverage in browser
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Continuous Integration Setup
```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Install dependencies
        run: flutter pub get

      - name: Run unit tests
        run: flutter test test/unit/

      - name: Run widget tests
        run: flutter test test/widget/

      - name: Run golden tests
        run: flutter test test/golden/

      - name: Run performance tests
        run: flutter test test/performance/

      - name: Run accessibility tests
        run: flutter test test/accessibility/

      - name: Generate coverage
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

---

*This comprehensive testing guide ensures the Room-O-Matic design system maintains the highest quality standards across all components and user interactions.*
