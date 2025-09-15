# 🎨 Room-O-Matic UI Component Showcase

> *A visual demonstration of the retro business design system in action*

---

## 🎯 Component Gallery

### 🔘 Button Components

#### Primary Buttons - Business Authority
```dart
// Primary CTA Button
RetroButton.primary(
  onPressed: () => handleAction(),
  child: Text('Start Professional Trial'),
)

// Primary with Loading State
RetroButton.primary(
  onPressed: null,
  isLoading: true,
  child: Text('Creating Account...'),
)
```

**Visual Characteristics:**
- Background: Business Red (#B91C1C)
- Text: Paper White (#FAFAFA)
- Elevation: 1dp shadow
- Animation: 0.95x scale on press
- Border Radius: 8px

#### Outline Buttons - Secondary Actions
```dart
// Secondary Action Button
RetroButton.outline(
  onPressed: () => handleSecondary(),
  child: Text('Learn More'),
)

// Outline with Icon
RetroButton.outline(
  onPressed: () => showDetails(),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.info_outline),
      SizedBox(width: 8),
      Text('View Details'),
    ],
  ),
)
```

**Visual Characteristics:**
- Background: Transparent
- Border: Business Red (#B91C1C) 1.5px
- Text: Business Red (#B91C1C)
- Hover: Subtle fill effect

#### Danger Buttons - Destructive Actions
```dart
// Delete Action Button
RetroButton.danger(
  onPressed: () => showDeleteConfirmation(),
  child: Text('Delete Account'),
)

// Danger with Icon
RetroButton.danger(
  onPressed: () => handleRemove(),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.delete_outline),
      SizedBox(width: 8),
      Text('Remove'),
    ],
  ),
)
```

**Visual Characteristics:**
- Background: Warning Red (#EF4444)
- Text: Paper White (#FAFAFA)
- Icon: White outline style
- Elevation: 1dp shadow

#### Text Buttons - Subtle Actions
```dart
// Link-style Button
RetroButton.text(
  onPressed: () => navigate(),
  child: Text('Forgot Password?'),
)

// Text Button with Icon
RetroButton.text(
  onPressed: () => openHelp(),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.help_outline),
      SizedBox(width: 4),
      Text('Help'),
    ],
  ),
)
```

---

### 📝 Text Field Components

#### Standard Text Fields
```dart
// Email Input Field
RetroTextField(
  label: 'Email Address',
  hint: 'Enter your business email',
  prefixIcon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  validator: (value) => EmailValidator.validate(value),
)

// Password Input Field
RetroTextField(
  label: 'Password',
  hint: 'Enter secure password',
  prefixIcon: Icons.lock,
  obscureText: true,
  suffixIcon: IconButton(
    icon: Icon(Icons.visibility),
    onPressed: togglePasswordVisibility,
  ),
)
```

**Visual Characteristics:**
- Border: Light Gray (#E5E7EB) default, Business Red (#B91C1C) focus
- Background: Off White (#F9FAFB) default, Paper White focus
- Label: Floating animation on focus
- Focus Glow: Business Red shadow (0.2 opacity)

#### Search Field
```dart
// Professional Search Field
RetroSearchField(
  hint: 'Search measurements...',
  onChanged: (query) => filterResults(query),
  onSubmitted: (query) => performSearch(query),
)
```

#### Text Area
```dart
// Multi-line Text Input
RetroTextArea(
  label: 'Project Notes',
  hint: 'Add project description and notes...',
  minLines: 3,
  maxLines: 6,
  maxLength: 500,
)
```

---

### 🏷️ Status Badge Components

#### Success Badges
```dart
// Completed Status
RetroStatusBadge.success(
  text: 'Scan Complete',
  icon: Icons.check_circle,
)

// Verified Status
RetroStatusBadge.success(
  text: 'Email Verified',
  icon: Icons.verified_user,
)
```

**Visual Characteristics:**
- Background: Success Green (#10B981)
- Text: Paper White (#FAFAFA)
- Icon: White with 16px size
- Border Radius: 12px
- Padding: 8px horizontal, 4px vertical

#### Premium Badges
```dart
// Premium Feature Badge
RetroStatusBadge.premium(
  text: 'Pro Feature',
  icon: Icons.star,
)

// Enterprise Badge
RetroStatusBadge.premium(
  text: 'Enterprise',
  icon: Icons.business,
)
```

**Visual Characteristics:**
- Background: Accent Gold (#D97706)
- Text: Paper White (#FAFAFA)
- Icon: Star or business icons
- Subtle glow effect

#### Warning Badges
```dart
// Error Status
RetroStatusBadge.warning(
  text: 'Scan Failed',
  icon: Icons.error,
)

// Quota Exceeded
RetroStatusBadge.warning(
  text: 'Quota Exceeded',
  icon: Icons.warning,
)
```

#### Info Badges
```dart
// Trial Status
RetroStatusBadge.info(
  text: 'Trial Version',
  icon: Icons.access_time,
)

// Beta Feature
RetroStatusBadge.info(
  text: 'Beta',
  icon: Icons.science,
)
```

---

### 📊 Measurement Display Components

#### Room Area Display
```dart
// Large Measurement Card
RetroMeasurementDisplay.large(
  label: 'Room Area',
  value: '142.5',
  unit: 'm²',
  accuracy: '±2.1 cm',
  status: MeasurementStatus.verified,
)
```

**Visual Layout:**
```
┌─────────────────────────────────┐
│ 📏 Room Area                    │
│                                 │
│     142.5 m²                    │
│     ±2.1 cm accuracy            │
│                                 │
│ 🟢 Verified                     │
└─────────────────────────────────┘
```

#### Compact Measurement
```dart
// Inline Measurement Display
RetroMeasurementDisplay.compact(
  label: 'Width',
  value: '3.2',
  unit: 'm',
)
```

**Visual Layout:**
```
┌─────────────────┐
│ Width: 3.2 m    │
└─────────────────┘
```

#### Technical Data Grid
```dart
// Multiple Measurements
Column(
  children: [
    RetroMeasurementDisplay.row(
      measurements: [
        ('Length', '4.8', 'm'),
        ('Width', '3.2', 'm'),
        ('Height', '2.7', 'm'),
      ],
    ),
    RetroMeasurementDisplay.row(
      measurements: [
        ('Area', '15.4', 'm²'),
        ('Volume', '41.6', 'm³'),
        ('Perimeter', '16.0', 'm'),
      ],
    ),
  ],
)
```

---

### 🗂️ Card Components

#### Information Card
```dart
// Feature Information Card
Container(
  padding: RetroSpacing.cardPadding,
  decoration: BoxDecoration(
    color: theme.offWhite,
    borderRadius: BorderRadius.circular(RetroBorderRadius.card),
    border: Border.all(color: theme.lightGray),
    boxShadow: [
      BoxShadow(
        color: theme.charcoalGray.withOpacity(0.1),
        blurRadius: RetroElevation.card,
        offset: Offset(0, 1),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Professional Features',
        style: RetroTextStyles.heading3.copyWith(
          color: theme.charcoalGray,
        ),
      ),
      SizedBox(height: RetroSpacing.sm),
      Text(
        'Advanced room scanning with professional-grade accuracy and enterprise security.',
        style: RetroTextStyles.bodyMedium.copyWith(
          color: theme.darkGray,
        ),
      ),
      SizedBox(height: RetroSpacing.md),
      RetroButton.outline(
        onPressed: () => viewFeatures(),
        child: Text('Learn More'),
      ),
    ],
  ),
)
```

#### Data Display Card
```dart
// Measurement Results Card
Container(
  padding: RetroSpacing.cardPadding,
  decoration: BoxDecoration(
    color: theme.creamWhite,
    borderRadius: BorderRadius.circular(RetroBorderRadius.card),
    border: Border.all(color: theme.lightGray),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Scan Results',
            style: RetroTextStyles.heading3.copyWith(
              color: theme.charcoalGray,
            ),
          ),
          RetroStatusBadge.success(
            text: 'Verified',
            icon: Icons.verified,
          ),
        ],
      ),
      SizedBox(height: RetroSpacing.md),
      ...measurements.map((m) => RetroMeasurementDisplay.compact(
        label: m.label,
        value: m.value,
        unit: m.unit,
      )),
    ],
  ),
)
```

---

### 🎛️ Navigation Components

#### App Bar
```dart
AppBar(
  title: Text(
    'Room-O-Matic',
    style: RetroTextStyles.heading2.copyWith(
      color: Colors.white,
    ),
  ),
  backgroundColor: theme.primaryRed,
  elevation: RetroElevation.appBar,
  actions: [
    IconButton(
      icon: Icon(Icons.account_circle),
      onPressed: () => openAccount(),
    ),
  ],
)
```

#### Bottom Navigation
```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  backgroundColor: theme.paperWhite,
  selectedItemColor: theme.primaryRed,
  unselectedItemColor: theme.mediumGray,
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.camera_alt),
      label: 'Scan',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.folder),
      label: 'Projects',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Account',
    ),
  ],
)
```

---

### 💬 Dialog Components

#### Confirmation Dialog
```dart
AlertDialog(
  backgroundColor: theme.paperWhite,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(RetroBorderRadius.medium),
  ),
  title: Text(
    'Delete Project',
    style: RetroTextStyles.heading3.copyWith(
      color: theme.charcoalGray,
    ),
  ),
  content: Text(
    'Are you sure you want to delete this project? This action cannot be undone.',
    style: RetroTextStyles.bodyMedium.copyWith(
      color: theme.darkGray,
    ),
  ),
  actions: [
    RetroButton.text(
      onPressed: () => Navigator.pop(context),
      child: Text('Cancel'),
    ),
    RetroButton.danger(
      onPressed: () => confirmDelete(),
      child: Text('Delete'),
    ),
  ],
)
```

#### Information Modal
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    backgroundColor: theme.paperWhite,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RetroBorderRadius.large),
    ),
    child: Container(
      padding: RetroSpacing.sectionPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Measurement Details',
                style: RetroTextStyles.heading2.copyWith(
                  color: theme.charcoalGray,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: RetroSpacing.md),
          // Content here
        ],
      ),
    ),
  ),
)
```

---

### 📋 Form Components

#### Professional Login Form
```dart
Form(
  key: _formKey,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Professional Sign In',
        style: RetroTextStyles.heading1.copyWith(
          color: theme.primaryRed,
        ),
      ),
      SizedBox(height: RetroSpacing.xl),

      RetroTextField(
        controller: _emailController,
        label: 'Business Email',
        hint: 'you@company.com',
        prefixIcon: Icons.business,
        keyboardType: TextInputType.emailAddress,
        validator: validateEmail,
      ),
      SizedBox(height: RetroSpacing.md),

      RetroTextField(
        controller: _passwordController,
        label: 'Password',
        hint: 'Enter your password',
        prefixIcon: Icons.lock,
        obscureText: true,
        validator: validatePassword,
      ),
      SizedBox(height: RetroSpacing.lg),

      RetroButton.primary(
        onPressed: _isLoading ? null : handleSignIn,
        isLoading: _isLoading,
        child: Text('Sign In'),
      ),
      SizedBox(height: RetroSpacing.md),

      RetroButton.text(
        onPressed: () => showForgotPassword(),
        child: Text('Forgot Password?'),
      ),
    ],
  ),
)
```

#### Registration Form
```dart
Form(
  child: Column(
    children: [
      RetroTextField(
        label: 'Full Name',
        hint: 'John Smith',
        prefixIcon: Icons.person,
        validator: validateName,
      ),
      SizedBox(height: RetroSpacing.md),

      RetroTextField(
        label: 'Business Email',
        hint: 'john@company.com',
        prefixIcon: Icons.business,
        keyboardType: TextInputType.emailAddress,
        validator: validateEmail,
      ),
      SizedBox(height: RetroSpacing.md),

      RetroTextField(
        label: 'Company Name',
        hint: 'Your Company Ltd.',
        prefixIcon: Icons.domain,
        validator: validateCompany,
      ),
      SizedBox(height: RetroSpacing.md),

      RetroTextField(
        label: 'Password',
        hint: 'Minimum 8 characters',
        prefixIcon: Icons.lock,
        obscureText: true,
        validator: validatePassword,
      ),
      SizedBox(height: RetroSpacing.lg),

      RetroButton.primary(
        onPressed: handleRegister,
        child: Text('Create Professional Account'),
      ),
    ],
  ),
)
```

---

### 📊 Data Visualization Components

#### Progress Indicator
```dart
// Quota Usage Display
Container(
  padding: RetroSpacing.cardPadding,
  decoration: BoxDecoration(
    color: theme.offWhite,
    borderRadius: BorderRadius.circular(RetroBorderRadius.card),
    border: Border.all(color: theme.lightGray),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'API Usage',
            style: RetroTextStyles.heading3.copyWith(
              color: theme.charcoalGray,
            ),
          ),
          Text(
            '847 / 1000',
            style: RetroTextStyles.dataMedium.copyWith(
              color: theme.primaryRed,
            ),
          ),
        ],
      ),
      SizedBox(height: RetroSpacing.sm),
      LinearProgressIndicator(
        value: 0.847,
        backgroundColor: theme.lightGray,
        valueColor: AlwaysStoppedAnimation<Color>(
          theme.primaryRed,
        ),
      ),
      SizedBox(height: RetroSpacing.xs),
      Text(
        '84.7% of monthly quota used',
        style: RetroTextStyles.caption.copyWith(
          color: theme.mediumGray,
        ),
      ),
    ],
  ),
)
```

#### Chart Container
```dart
// Measurement History Chart
Container(
  height: 200,
  padding: RetroSpacing.cardPadding,
  decoration: BoxDecoration(
    color: theme.creamWhite,
    borderRadius: BorderRadius.circular(RetroBorderRadius.card),
    border: Border.all(color: theme.lightGray),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Scan Accuracy Trend',
        style: RetroTextStyles.heading3.copyWith(
          color: theme.charcoalGray,
        ),
      ),
      SizedBox(height: RetroSpacing.sm),
      Expanded(
        child: CustomPaint(
          painter: AccuracyChartPainter(data: accuracyData),
          size: Size.infinite,
        ),
      ),
    ],
  ),
)
```

---

### 🎨 Theme Implementation

#### Light Theme Configuration
```dart
ThemeData(
  primarySwatch: Colors.red,
  scaffoldBackgroundColor: RetroTheme.light().paperWhite,
  appBarTheme: AppBarTheme(
    backgroundColor: RetroTheme.light().primaryRed,
    elevation: RetroElevation.appBar,
    titleTextStyle: RetroTextStyles.heading2.copyWith(
      color: Colors.white,
    ),
  ),
  cardTheme: CardTheme(
    color: RetroTheme.light().offWhite,
    elevation: RetroElevation.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RetroBorderRadius.card),
    ),
  ),
  extensions: [
    RetroTheme.light(),
  ],
)
```

#### Dark Theme Configuration
```dart
ThemeData.dark().copyWith(
  primaryColor: RetroTheme.dark().primaryRed,
  scaffoldBackgroundColor: RetroTheme.dark().charcoalGray,
  cardColor: RetroTheme.dark().offWhite,
  extensions: [
    RetroTheme.dark(),
  ],
)
```

---

## 🎯 Implementation Best Practices

### **Consistent Component Usage**
1. Always use RetroTheme colors through `Theme.of(context).extension<RetroTheme>()`
2. Apply RetroTextStyles for all text elements
3. Use RetroSpacing constants for all layout spacing
4. Implement RetroBorderRadius for consistent corner rounding

### **Professional Styling Patterns**
1. **Card Layouts**: Always include subtle shadows and proper padding
2. **Form Elements**: Group related fields with appropriate spacing
3. **Data Display**: Use monospace fonts for measurements and technical data
4. **Status Indicators**: Clear visual hierarchy with appropriate color coding

### **Animation Guidelines**
1. **Button Interactions**: Subtle scale animations (0.95x) for tactile feedback
2. **Focus States**: Smooth color transitions with 200ms duration
3. **Loading States**: Professional spinner with brand color
4. **Page Transitions**: Consistent slide animations for navigation

---

*This showcase demonstrates the complete retro business design system implementation, providing a professional, cohesive user experience that sets Room-O-Matic apart in the mobile measurement market.*
