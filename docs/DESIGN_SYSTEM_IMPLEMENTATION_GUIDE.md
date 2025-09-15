# 🛠️ Room-O-Matic Design System Implementation Guide

> *Complete developer guide for implementing the retro business design system*

---

## 🚀 Quick Start

### 1. **Theme Integration**

#### Add RetroTheme to Your App
```dart
import 'package:flutter/material.dart';
import 'lib/interface/widgets/retro/retro_theme.dart';

class RoomOMaticApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room-O-Matic',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Paper White
        extensions: [
          RetroTheme.light(), // Add retro theme extension
        ],
      ),
      darkTheme: ThemeData.dark().copyWith(
        extensions: [
          RetroTheme.dark(), // Dark theme support
        ],
      ),
      home: const HomeScreen(),
    );
  }
}
```

#### Access Theme in Widgets
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the retro theme
    final retroTheme = Theme.of(context).extension<RetroTheme>()!;

    return Container(
      color: retroTheme.paperWhite,
      child: Text(
        'Professional Text',
        style: RetroTextStyles.heading1.copyWith(
          color: retroTheme.primaryRed,
        ),
      ),
    );
  }
}
```

### 2. **Import Required Components**
```dart
// Import all retro components
import 'lib/interface/widgets/retro/retro_theme.dart';
import 'lib/interface/widgets/retro/retro_button.dart';
import 'lib/interface/widgets/retro/retro_text_field.dart';
import 'lib/interface/widgets/retro/retro_status_badge.dart';
import 'lib/interface/widgets/retro/retro_measurement_display.dart';
```

---

## 🎨 Component Implementation

### 🔘 **Button Implementation**

#### Basic Button Usage
```dart
// Primary action button
RetroButton.primary(
  onPressed: () {
    // Handle primary action
    print('Primary action pressed');
  },
  child: const Text('Start Scan'),
)

// Secondary action button
RetroButton.outline(
  onPressed: () {
    // Handle secondary action
    showInfoDialog();
  },
  child: const Text('Learn More'),
)

// Destructive action button
RetroButton.danger(
  onPressed: () {
    // Handle destructive action
    showDeleteConfirmation();
  },
  child: const Text('Delete Project'),
)

// Subtle text button
RetroButton.text(
  onPressed: () {
    // Handle subtle action
    Navigator.push(context, HelpRoute());
  },
  child: const Text('Need Help?'),
)
```

#### Advanced Button Features
```dart
// Button with loading state
class ActionButton extends StatefulWidget {
  @override
  _ActionButtonState createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _isLoading = false;

  Future<void> _handleAction() async {
    setState(() => _isLoading = true);

    try {
      await performAsyncAction();
      // Handle success
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RetroButton.primary(
      onPressed: _isLoading ? null : _handleAction,
      isLoading: _isLoading,
      child: const Text('Process Data'),
    );
  }
}

// Button with custom padding and size
RetroButton.primary(
  onPressed: handleAction,
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  minimumSize: const Size(200, 48),
  child: const Text('Custom Sized Button'),
)

// Button with icon
RetroButton.outline(
  onPressed: openSettings,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: const [
      Icon(Icons.settings),
      SizedBox(width: 8),
      Text('Settings'),
    ],
  ),
)
```

### 📝 **Text Field Implementation**

#### Basic Text Field Usage
```dart
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          RetroTextField(
            controller: _emailController,
            label: 'Business Email',
            hint: 'you@company.com',
            prefixIcon: Icons.business,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Email is required';
              }
              if (!value!.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          RetroTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Icons.lock,
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Password is required';
              }
              if (value!.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

#### Advanced Text Field Features
```dart
// Text field with real-time validation
class ValidatedTextField extends StatefulWidget {
  @override
  _ValidatedTextFieldState createState() => _ValidatedTextFieldState();
}

class _ValidatedTextFieldState extends State<ValidatedTextField> {
  final _controller = TextEditingController();
  String? _errorText;

  void _validateInput(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = 'This field is required';
      } else if (value.length < 3) {
        _errorText = 'Minimum 3 characters required';
      } else {
        _errorText = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RetroTextField(
      controller: _controller,
      label: 'Project Name',
      hint: 'Enter project name',
      prefixIcon: Icons.folder,
      errorText: _errorText,
      onChanged: _validateInput,
    );
  }
}

// Search field with debounced input
class SearchField extends StatefulWidget {
  final Function(String) onSearch;

  const SearchField({required this.onSearch});

  @override
  _SearchFieldState createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RetroSearchField(
      controller: _controller,
      hint: 'Search projects...',
      onChanged: _onSearchChanged,
      onClear: () {
        _controller.clear();
        widget.onSearch('');
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}

// Text area for longer content
RetroTextArea(
  label: 'Project Description',
  hint: 'Describe your measurement project...',
  minLines: 3,
  maxLines: 6,
  maxLength: 500,
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return 'Description is required';
    }
    return null;
  },
)
```

### 🏷️ **Status Badge Implementation**

#### Basic Badge Usage
```dart
// Success status
RetroStatusBadge.success(
  text: 'Scan Complete',
  icon: Icons.check_circle,
)

// Premium feature badge
RetroStatusBadge.premium(
  text: 'Pro Feature',
  icon: Icons.star,
)

// Warning status
RetroStatusBadge.warning(
  text: 'Low Battery',
  icon: Icons.battery_alert,
)

// Info status
RetroStatusBadge.info(
  text: 'Trial Version',
  icon: Icons.access_time,
)
```

#### Dynamic Status Badges
```dart
class StatusBadgeDisplay extends StatelessWidget {
  final String status;
  final String message;

  const StatusBadgeDisplay({
    required this.status,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'complete':
      case 'verified':
        return RetroStatusBadge.success(
          text: message,
          icon: Icons.check_circle,
        );

      case 'premium':
      case 'pro':
      case 'enterprise':
        return RetroStatusBadge.premium(
          text: message,
          icon: Icons.star,
        );

      case 'error':
      case 'failed':
      case 'warning':
        return RetroStatusBadge.warning(
          text: message,
          icon: Icons.error,
        );

      case 'info':
      case 'trial':
      case 'beta':
      default:
        return RetroStatusBadge.info(
          text: message,
          icon: Icons.info,
        );
    }
  }
}

// Usage
StatusBadgeDisplay(
  status: scanResult.status,
  message: scanResult.message,
)
```

### 📊 **Measurement Display Implementation**

#### Basic Measurement Display
```dart
// Large measurement card
RetroMeasurementDisplay.large(
  label: 'Room Area',
  value: '142.5',
  unit: 'm²',
  accuracy: '±2.1 cm',
  status: MeasurementStatus.verified,
)

// Compact measurement
RetroMeasurementDisplay.compact(
  label: 'Width',
  value: '3.2',
  unit: 'm',
)
```

#### Measurement Grid Layout
```dart
class MeasurementGrid extends StatelessWidget {
  final Map<String, MeasurementData> measurements;

  const MeasurementGrid({required this.measurements});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final entry = measurements.entries.elementAt(index);
        final measurement = entry.value;

        return RetroMeasurementDisplay.compact(
          label: entry.key,
          value: measurement.value.toStringAsFixed(1),
          unit: measurement.unit,
        );
      },
    );
  }
}

// Data model
class MeasurementData {
  final double value;
  final String unit;
  final double? accuracy;
  final MeasurementStatus status;

  const MeasurementData({
    required this.value,
    required this.unit,
    this.accuracy,
    this.status = MeasurementStatus.pending,
  });
}
```

#### Dynamic Measurement Display
```dart
class DynamicMeasurementCard extends StatelessWidget {
  final MeasurementData measurement;
  final bool showAccuracy;
  final VoidCallback? onTap;

  const DynamicMeasurementCard({
    required this.measurement,
    this.showAccuracy = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final retroTheme = Theme.of(context).extension<RetroTheme>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: RetroSpacing.cardPadding,
        decoration: BoxDecoration(
          color: retroTheme.offWhite,
          borderRadius: BorderRadius.circular(RetroBorderRadius.card),
          border: Border.all(color: retroTheme.lightGray),
          boxShadow: [
            BoxShadow(
              color: retroTheme.charcoalGray.withOpacity(0.1),
              blurRadius: RetroElevation.card,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              measurement.label,
              style: RetroTextStyles.heading3.copyWith(
                color: retroTheme.charcoalGray,
              ),
            ),
            const SizedBox(height: RetroSpacing.sm),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  measurement.value.toStringAsFixed(1),
                  style: RetroTextStyles.dataLarge.copyWith(
                    color: retroTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  measurement.unit,
                  style: RetroTextStyles.dataMedium.copyWith(
                    color: retroTheme.darkGray,
                  ),
                ),
              ],
            ),

            if (showAccuracy && measurement.accuracy != null) ...[
              const SizedBox(height: RetroSpacing.xs),
              Text(
                '±${measurement.accuracy!.toStringAsFixed(1)} cm',
                style: RetroTextStyles.caption.copyWith(
                  color: retroTheme.successGreen,
                ),
              ),
            ],

            const SizedBox(height: RetroSpacing.sm),
            _buildStatusBadge(measurement.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MeasurementStatus status) {
    switch (status) {
      case MeasurementStatus.verified:
        return RetroStatusBadge.success(
          text: 'Verified',
          icon: Icons.verified,
        );
      case MeasurementStatus.pending:
        return RetroStatusBadge.info(
          text: 'Processing',
          icon: Icons.hourglass_empty,
        );
      case MeasurementStatus.error:
        return RetroStatusBadge.warning(
          text: 'Error',
          icon: Icons.error,
        );
    }
  }
}
```

---

## 🎨 **Layout Patterns**

### Professional Card Layout
```dart
class ProfessionalCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;

  const ProfessionalCard({
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final retroTheme = Theme.of(context).extension<RetroTheme>()!;

    return Container(
      padding: RetroSpacing.cardPadding,
      decoration: BoxDecoration(
        color: retroTheme.offWhite,
        borderRadius: BorderRadius.circular(RetroBorderRadius.card),
        border: Border.all(color: retroTheme.lightGray),
        boxShadow: [
          BoxShadow(
            color: retroTheme.charcoalGray.withOpacity(0.1),
            blurRadius: RetroElevation.card,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: RetroTextStyles.heading3.copyWith(
                        color: retroTheme.charcoalGray,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: RetroTextStyles.bodySmall.copyWith(
                          color: retroTheme.mediumGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),

          const SizedBox(height: RetroSpacing.md),

          // Content
          child,
        ],
      ),
    );
  }
}
```

### Professional Screen Layout
```dart
class ProfessionalScreenLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const ProfessionalScreenLayout({
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final retroTheme = Theme.of(context).extension<RetroTheme>()!;

    return Scaffold(
      backgroundColor: retroTheme.paperWhite,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: RetroTextStyles.heading2.copyWith(
                color: Colors.white,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: RetroTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
          ],
        ),
        backgroundColor: retroTheme.primaryRed,
        elevation: RetroElevation.appBar,
        actions: actions,
      ),
      body: SafeArea(
        child: Padding(
          padding: RetroSpacing.screenPadding,
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
```

---

## 🎯 **Professional Patterns**

### Loading States
```dart
class LoadingStateWidget extends StatelessWidget {
  final String message;
  final bool showSpinner;

  const LoadingStateWidget({
    this.message = 'Loading...',
    this.showSpinner = true,
  });

  @override
  Widget build(BuildContext context) {
    final retroTheme = Theme.of(context).extension<RetroTheme>()!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSpinner) ...[
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: retroTheme.primaryRed,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: RetroSpacing.lg),
          ],
          Text(
            message,
            style: RetroTextStyles.bodyMedium.copyWith(
              color: retroTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Error States
```dart
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final retroTheme = Theme.of(context).extension<RetroTheme>()!;

    return Center(
      child: Padding(
        padding: RetroSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: retroTheme.warningRed,
            ),
            const SizedBox(height: RetroSpacing.lg),

            Text(
              title,
              style: RetroTextStyles.heading2.copyWith(
                color: retroTheme.charcoalGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RetroSpacing.sm),

            Text(
              message,
              style: RetroTextStyles.bodyMedium.copyWith(
                color: retroTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: RetroSpacing.xl),
              RetroButton.outline(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Empty States
```dart
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    required this.title,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final retroTheme = Theme.of(context).extension<RetroTheme>()!;

    return Center(
      child: Padding(
        padding: RetroSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: retroTheme.lightGray,
            ),
            const SizedBox(height: RetroSpacing.lg),

            Text(
              title,
              style: RetroTextStyles.heading2.copyWith(
                color: retroTheme.charcoalGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RetroSpacing.sm),

            Text(
              message,
              style: RetroTextStyles.bodyMedium.copyWith(
                color: retroTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),

            if (actionText != null && onAction != null) ...[
              const SizedBox(height: RetroSpacing.xl),
              RetroButton.primary(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 🔧 **Advanced Implementation**

### Custom Theme Extensions
```dart
// Extend RetroTheme for app-specific needs
class AppRetroTheme extends RetroTheme {
  final Color scanningColor;
  final Color measurementColor;

  const AppRetroTheme({
    required this.scanningColor,
    required this.measurementColor,
    required Color primaryRed,
    required Color charcoalGray,
    required Color paperWhite,
    // ... other required parameters
  }) : super(
    primaryRed: primaryRed,
    charcoalGray: charcoalGray,
    paperWhite: paperWhite,
    // ... pass other parameters
  );

  factory AppRetroTheme.light() {
    return AppRetroTheme(
      scanningColor: const Color(0xFF2563EB), // Blue for scanning
      measurementColor: const Color(0xFF059669), // Green for measurements
      primaryRed: const Color(0xFFB91C1C),
      charcoalGray: const Color(0xFF374151),
      paperWhite: const Color(0xFFFAFAFA),
      // ... other colors
    );
  }
}
```

### Responsive Design Helper
```dart
class ScreenBreakpoints {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ScreenBreakpoints.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (ScreenBreakpoints.isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}
```

### Animation Helper
```dart
class RetroAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;

  static Widget fadeIn({
    required Widget child,
    Duration duration = medium,
    double opacity = 1.0,
  }) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: duration,
      curve: easeInOut,
      child: child,
    );
  }

  static Widget slideIn({
    required Widget child,
    Duration duration = medium,
    Offset offset = const Offset(0, 0.1),
  }) {
    return AnimatedSlide(
      offset: offset,
      duration: duration,
      curve: easeOut,
      child: child,
    );
  }

  static Widget scaleIn({
    required Widget child,
    Duration duration = fast,
    double scale = 1.0,
  }) {
    return AnimatedScale(
      scale: scale,
      duration: duration,
      curve: easeInOut,
      child: child,
    );
  }
}
```

---

## 📋 **Testing Components**

### Widget Testing Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('RetroButton Tests', () {
    testWidgets('Primary button renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [RetroTheme.light()]),
          home: Scaffold(
            body: RetroButton.primary(
              onPressed: () {},
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(RetroButton), findsOneWidget);
    });

    testWidgets('Button press triggers callback', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [RetroTheme.light()]),
          home: Scaffold(
            body: RetroButton.primary(
              onPressed: () => pressed = true,
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RetroButton));
      await tester.pump();

      expect(pressed, isTrue);
    });
  });
}
```

### Integration Testing
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:room_o_matic/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Design System Integration Tests', () {
    testWidgets('Theme loads correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify theme colors are applied
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, const Color(0xFFB91C1C));
    });

    testWidgets('Components respond to interactions', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test button interactions
      await tester.tap(find.byType(RetroButton).first);
      await tester.pumpAndSettle();

      // Verify navigation or state change
      expect(find.text('Expected Result'), findsOneWidget);
    });
  });
}
```

---

## 📚 **Best Practices Checklist**

### ✅ **Implementation Checklist**

- [ ] **Theme Setup**: RetroTheme extension added to MaterialApp
- [ ] **Color Usage**: All colors accessed through RetroTheme
- [ ] **Typography**: All text uses RetroTextStyles
- [ ] **Spacing**: All layouts use RetroSpacing constants
- [ ] **Border Radius**: All corners use RetroBorderRadius
- [ ] **Elevation**: All shadows use RetroElevation
- [ ] **Components**: All UI uses retro components
- [ ] **Responsive**: Layout adapts to different screen sizes
- [ ] **Accessibility**: Proper contrast and semantic labels
- [ ] **Testing**: Components have adequate test coverage

### 🔧 **Performance Optimization**

```dart
// Use const constructors where possible
const RetroButton.primary(
  onPressed: handleAction,
  child: Text('Constant Button'),
)

// Cache theme access
class OptimizedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final retroTheme = Theme.of(context).extension<RetroTheme>()!;

    return _buildContent(retroTheme);
  }

  Widget _buildContent(RetroTheme theme) {
    // Use theme parameter to avoid multiple lookups
    return Container(
      color: theme.paperWhite,
      child: Text(
        'Optimized',
        style: RetroTextStyles.bodyMedium.copyWith(
          color: theme.charcoalGray,
        ),
      ),
    );
  }
}
```

### 🎨 **Consistency Guidelines**

1. **Always** use RetroTheme colors instead of hardcoded colors
2. **Always** use RetroTextStyles instead of custom TextStyle
3. **Always** use RetroSpacing for consistent layouts
4. **Always** use Retro components instead of default Flutter widgets
5. **Never** introduce new colors without updating the theme system
6. **Never** use arbitrary spacing values
7. **Never** mix design systems within the same screen

---

*This implementation guide ensures consistent, professional usage of the Room-O-Matic retro business design system across all development teams.*
