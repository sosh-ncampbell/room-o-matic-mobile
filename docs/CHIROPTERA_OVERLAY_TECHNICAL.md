# Chiroptera Overlay Technical Implementation Guide

## Component Architecture

### Flutter Widget Hierarchy
```dart
ChiropteraOverlay
├── CameraViewfinder (background)
├── EchoVisualizationLayer
│   ├── ConcentricRings (animated)
│   ├── Crosshair (dynamic)
│   └── PulseAnimation (ultrasonic)
├── MeasurementDisplayLayer
│   ├── DistanceReading (primary)
│   ├── AccuracyIndicator
│   └── ConfidenceLevel
├── StatusIndicatorLayer
│   ├── SessionStatus
│   ├── AudioPermissions
│   └── BatteryOptimization
└── ControlButtonLayer
    ├── PingTrigger
    ├── ModeSelector
    └── SettingsAccess
```

## Visual Specifications

### Measurement Display
- **Distance Format**: "X.XXm" or "X'X\""
- **Font**: RobotoMono, 32sp, Bold (matching business aesthetic)
- **Color**: #B91C1C (primary red - active), #374151 (charcoal - standby)
- **Background**: Semi-transparent paper white with art deco border
- **Position**: Center-top, 25% from top edge

### Echo Visualization
- **Ring Count**: 3-5 expanding circles (vintage oscilloscope style)
- **Animation Duration**: 1.2 seconds
- **Frequency**: 18-22kHz (professional equipment representation)
- **Color Gradient**:
  - Center: #B91C1C (100% opacity) - business red
  - Edge: #B91C1C (0% opacity)
- **Expansion Rate**: Linear easing, max radius 200dp

### Crosshair Design
- **Size**: 40x40dp
- **Stroke Width**: 2dp
- **Color**: Dynamic based on signal quality (business palette)
- **Style**: Professional surveyor cross with art deco corner markers
- **Animation**: Subtle pulse (1.5s cycle) reminiscent of office equipment

## State Management

### Chiroptera State Types
```dart
enum ChiropteraOverlayState {
  idle,           // Session inactive
  initializing,   // Starting up
  active,         // Ready to ping
  pinging,        // Pulse in progress
  measuring,      // Processing echo
  error           // Fault condition
}

enum SignalQuality {
  excellent,      // 0-3m, strong echo
  good,          // 3-6m, clear echo
  fair,          // 6-8m, weak echo
  poor,          // 8-10m, very weak
  none           // No echo detected
}
```

### Real-time Data Flow
1. **Audio Input**: Microphone captures echo
2. **Signal Processing**: Cross-correlation analysis
3. **Distance Calculation**: Time-of-flight → distance
4. **UI Update**: Overlay refreshes at 60fps
5. **Quality Assessment**: Signal strength evaluation

## Animation Specifications

### Ping Animation Sequence
1. **Pre-Ping** (0.2s): Crosshair color change
2. **Pulse Emission** (0.1s): First ring appears
3. **Propagation** (1.0s): Rings expand outward
4. **Echo Return** (0.1s): Return signal indicator
5. **Measurement Update** (0.3s): Distance value transition

### Smooth Transitions
- **Value Updates**: 300ms ease-out
- **Color Changes**: 200ms linear
- **Opacity Fades**: 400ms ease-in-out
- **Scale Animations**: 250ms spring

## Accessibility Features

### Visual Accessibility
- **High Contrast Mode**: Enhanced color separation with business palette
- **Large Text Support**: Scalable professional typography
- **Business Color Support**: Executive-friendly color alternatives
- **Reduced Motion**: Optional animation disable for office environments

### Audio Accessibility
- **Haptic Feedback**: Vibration on successful ping
- **Voice Announcements**: TTS distance readings
- **Audio Cues**: Confirmation sounds
- **Silent Mode**: Visual-only operation

## Performance Considerations

### 60fps Target Maintenance
- **Frame Budget**: 16.67ms per frame
- **GPU Utilization**: Hardware-accelerated animations
- **Memory Management**: Efficient texture caching
- **CPU Optimization**: Background isolate processing

### Battery Optimization
- **Sensor Duty Cycling**: Pulse-based measurement
- **Display Brightness**: Auto-dimming in dark environments
- **Background Processing**: Minimal when inactive
- **Power-aware UI**: Reduced effects on low battery

## Integration Points

### Platform Channels
```dart
// Chiroptera measurement trigger
await platform.invokeMethod('performChiropteraPing', {
  'direction': {'x': 0.0, 'y': 0.0, 'z': 1.0},
  'maxRange': 10.0,
});

// Real-time measurement stream
platform.methodChannel.setMethodCallHandler((call) {
  if (call.method == 'onChiropteraMeasurement') {
    final data = call.arguments as Map<String, dynamic>;
    _updateOverlay(data);
  }
});
```

### Camera Integration
- **CameraController**: Background video feed
- **Overlay Rendering**: CustomPainter over camera
- **Aspect Ratio**: Maintains camera preview ratio
- **Orientation**: Auto-rotation support

## Error Handling

### Common Error States
1. **Audio Permission Denied**: Show permission prompt overlay
2. **Background Noise Too High**: Suggest quieter environment
3. **No Echo Detected**: Distance out of range indicator
4. **Hardware Limitation**: Graceful degradation message

### User Feedback
- **Visual Indicators**: Color-coded status messages
- **Contextual Help**: Inline tips and guidance
- **Recovery Actions**: Clear next steps for users
- **Progress Feedback**: Loading states and animations

## Testing Considerations

### UI Testing
- **Widget Tests**: Individual component behavior
- **Golden Tests**: Visual regression testing
- **Animation Tests**: Timing and smoothness verification
- **Accessibility Tests**: Screen reader compatibility

### Integration Testing
- **Platform Channel Mocking**: Simulated sensor data
- **Performance Testing**: Frame rate monitoring
- **Device Testing**: Various screen sizes and densities
- **Edge Case Testing**: Error conditions and recovery

---

This technical guide provides the implementation foundation for the Chiroptera overlay interface, ensuring consistent visual design and robust performance across all supported devices.
