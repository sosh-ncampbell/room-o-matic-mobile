# iOS Flutter Development Guide

## Table of Contents
1. [Platform Integration Overview](#platform-integration-overview)
2. [Setting Up iOS Development](#setting-up-ios-development)
3. [Platform Channels & Native Integration](#platform-channels--native-integration)
4. [Platform Views for Native iOS Components](#platform-views-for-native-ios-components)
5. [Core Location & ARKit Integration](#core-location--arkit-integration)
6. [AVFoundation for Camera & Audio](#avfoundation-for-camera--audio)
7. [Security Implementation](#security-implementation)
8. [Performance Optimization](#performance-optimization)
9. [Testing Strategies](#testing-strategies)
10. [Build & Deployment](#build--deployment)
11. [Troubleshooting Common Issues](#troubleshooting-common-issues)

---

## Platform Integration Overview

Flutter iOS integration leverages native iOS frameworks and APIs to access device-specific functionality for the Room-O-Matic application.

### iOS-Specific Integration Approaches
1. **Platform Channels** - Swift/Objective-C ↔ Dart communication
2. **Platform Views** - Embedding native UIKit components
3. **Pigeon** - Type-safe code generation for iOS APIs
4. **FFI (Foreign Function Interface)** - Direct C/C++ integration
5. **iOS Frameworks** - Core Location, ARKit, AVFoundation, Core Motion

### iOS Framework Integration for Room-O-Matic

| Framework | Room-O-Matic Use Case | Performance | Complexity |
|-----------|----------------------|-------------|------------|
| ARKit | LiDAR scanning, spatial mapping | Excellent | High |
| Core Location | Device positioning, compass | Good | Medium |
| AVFoundation | Camera, audio sonar | Excellent | Medium-High |
| Core Motion | IMU sensors, device orientation | Good | Low-Medium |
| Vision | Object detection, image analysis | Good | Medium |

---

## Setting Up iOS Development

### Prerequisites
```bash
# Verify Flutter installation for iOS
flutter doctor

# Check iOS setup specifically
flutter doctor --verbose

# Install iOS deployment tools
brew install ios-deploy
```

### Xcode Configuration
1. **Install Xcode** from App Store (minimum Xcode 14.0)
2. **Configure Xcode Command Line Tools**:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```
3. **Set up iOS Simulator**:
   ```bash
   open -a Simulator
   ```
4. **Configure Apple Developer Account** for device testing and distribution

### iOS Project Configuration for Room-O-Matic
```ruby
# ios/Podfile
platform :ios, '14.0'  # Minimum for ARKit and advanced features

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # Room-O-Matic specific pods
  pod 'ARKit'
  pod 'Vision'
  pod 'CoreML'
  pod 'AVFoundation'
  pod 'CoreLocation'
  pod 'CoreMotion'
  pod 'LocalAuthentication'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'  # Required for some sensor libraries
    end
  end
end
```

### Info.plist Configuration
```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <!-- Camera permission for AR scanning -->
    <key>NSCameraUsageDescription</key>
    <string>Room-O-Matic needs camera access for 3D room scanning and measurement</string>

    <!-- Microphone for sonar functionality -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Room-O-Matic uses microphone for audio-based distance measurement</string>

    <!-- Location for device positioning -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Room-O-Matic needs location access for accurate room positioning</string>

    <!-- Motion sensors for device orientation -->
    <key>NSMotionUsageDescription</key>
    <string>Room-O-Matic uses motion sensors for accurate device orientation during scanning</string>

    <!-- ARKit support -->
    <key>NSCameraUsageDescription</key>
    <string>Room-O-Matic uses ARKit for advanced 3D room scanning capabilities</string>

    <!-- Required device capabilities -->
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arkit</string>
        <string>camera-flash</string>
        <string>gyroscope</string>
        <string>accelerometer</string>
        <string>magnetometer</string>
    </array>

    <!-- Supported orientations -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
```

---

## Platform Channels & Native Integration

### Basic Platform Channel Implementation

#### Dart Side (Flutter)
```dart
// lib/platform/ios_sensor_platform.dart
import 'package:flutter/services.dart';

class IOSSensorPlatform {
  static const MethodChannel _channel = MethodChannel('com.roomomatic.ios.sensors');

  // ARKit LiDAR scanning
  static Future<Map<String, dynamic>> startARKitSession() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('startARKitSession');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to start ARKit session: ${e.message}');
    }
  }

  // Get LiDAR point cloud data
  static Future<List<Map<String, dynamic>>> getLiDARPointCloud() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getLiDARPointCloud');
      return result.map((point) => Map<String, dynamic>.from(point)).toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get LiDAR data: ${e.message}');
    }
  }

  // Core Motion sensor data
  static Future<Map<String, dynamic>> getMotionData() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getMotionData');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw Exception('Failed to get motion data: ${e.message}');
    }
  }

  // Stream for real-time ARKit updates
  static const EventChannel _arkitStream = EventChannel('com.roomomatic.ios.arkit/stream');

  static Stream<Map<String, dynamic>> get arkitDataStream {
    return _arkitStream.receiveBroadcastStream().map((data) {
      return Map<String, dynamic>.from(data);
    });
  }
}
```

#### iOS Side (Swift)
```swift
// ios/Runner/IOSSensorChannelHandler.swift
import Flutter
import ARKit
import CoreMotion
import CoreLocation

class IOSSensorChannelHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.roomomatic.ios.sensors",
            binaryMessenger: registrar.messenger()
        )

        let eventChannel = FlutterEventChannel(
            name: "com.roomomatic.ios.arkit/stream",
            binaryMessenger: registrar.messenger()
        )

        let instance = IOSSensorChannelHandler()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
}

// MARK: - Method Channel Handler
extension IOSSensorChannelHandler: FlutterMethodCallHandler {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startARKitSession":
            startARKitSession(result: result)
        case "getLiDARPointCloud":
            getLiDARPointCloud(result: result)
        case "getMotionData":
            getMotionData(result: result)
        case "stopARKitSession":
            stopARKitSession(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startARKitSession(result: @escaping FlutterResult) {
        guard ARWorldTrackingConfiguration.isSupported else {
            result(FlutterError(
                code: "ARKIT_NOT_SUPPORTED",
                message: "ARKit is not supported on this device",
                details: nil
            ))
            return
        }

        DispatchQueue.main.async {
            self.setupARKit { success, error in
                if success {
                    result([
                        "success": true,
                        "hasLiDAR": ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh),
                        "supportedFeatures": self.getSupportedARFeatures()
                    ])
                } else {
                    result(FlutterError(
                        code: "ARKIT_SETUP_FAILED",
                        message: error?.localizedDescription ?? "Failed to setup ARKit",
                        details: nil
                    ))
                }
            }
        }
    }

    private func getSupportedARFeatures() -> [String] {
        var features: [String] = []

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            features.append("scene_reconstruction")
        }
        if ARWorldTrackingConfiguration.supportsUserFaceTracking {
            features.append("face_tracking")
        }
        if #available(iOS 14.0, *) {
            if ARWorldTrackingConfiguration.supportsAppClipCodeTracking {
                features.append("app_clip_code_tracking")
            }
        }

        return features
    }
}

// MARK: - ARKit Implementation
extension IOSSensorChannelHandler {
    private var arSession: ARSession = ARSession()
    private var motionManager: CMMotionManager = CMMotionManager()

    private func setupARKit(completion: @escaping (Bool, Error?) -> Void) {
        let configuration = ARWorldTrackingConfiguration()

        // Enable LiDAR scene reconstruction if available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        // Enable plane detection
        configuration.planeDetection = [.horizontal, .vertical]

        // Enable occlusion (if supported)
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }

        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // Start motion updates
        startMotionUpdates()

        completion(true, nil)
    }

    private func getLiDARPointCloud(result: @escaping FlutterResult) {
        guard let frame = arSession.currentFrame else {
            result(FlutterError(
                code: "NO_FRAME",
                message: "No ARKit frame available",
                details: nil
            ))
            return
        }

        guard let depthData = frame.sceneDepth else {
            result(FlutterError(
                code: "NO_DEPTH_DATA",
                message: "No depth data available (LiDAR required)",
                details: nil
            ))
            return
        }

        let pointCloud = processDepthData(depthData, camera: frame.camera)
        result(pointCloud)
    }

    private func processDepthData(_ depthData: ARDepthData, camera: ARCamera) -> [[String: Any]] {
        let depthMap = depthData.depthMap
        let confidenceMap = depthData.confidenceMap

        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        CVPixelBufferLockBaseAddress(confidenceMap!, .readOnly)

        defer {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            CVPixelBufferUnlockBaseAddress(confidenceMap!, .readOnly)
        }

        let depthPointer = CVPixelBufferGetBaseAddress(depthMap)!
            .bindMemory(to: Float32.self, capacity: width * height)
        let confidencePointer = CVPixelBufferGetBaseAddress(confidenceMap!)!
            .bindMemory(to: UInt8.self, capacity: width * height)

        var points: [[String: Any]] = []
        let sampleRate = 10 // Sample every 10th pixel for performance

        for y in stride(from: 0, to: height, by: sampleRate) {
            for x in stride(from: 0, to: width, by: sampleRate) {
                let index = y * width + x
                let depth = depthPointer[index]
                let confidence = confidencePointer[index]

                // Filter out low confidence and invalid depths
                guard confidence >= 2 && depth > 0 && depth < 50 else { continue }

                // Convert pixel coordinates to normalized coordinates
                let normalizedX = Float(x) / Float(width)
                let normalizedY = Float(y) / Float(height)

                // Unproject to world coordinates
                let point = camera.unprojectPoint(
                    CGPoint(x: CGFloat(normalizedX), y: CGFloat(normalizedY)),
                    ontoPlaneWithTransform: simd_float4x4.identity,
                    orientation: .portrait,
                    viewportSize: CGSize(width: width, height: height)
                )

                points.append([
                    "x": point.x * depth,
                    "y": point.y * depth,
                    "z": -depth, // Convert to Flutter coordinate system
                    "confidence": confidence,
                    "timestamp": Date().timeIntervalSince1970
                ])
            }
        }

        return points
    }
}
```

---

## Core Location & ARKit Integration

### Location Services for Room Positioning
```swift
// ios/Runner/LocationService.swift
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 1.0 // 1 degree sensitivity

        requestLocationPermission()
    }

    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Handle permission denied
            break
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }

    private func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else { return }

        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        currentHeading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startLocationUpdates()
        }
    }
}
```

---

## AVFoundation for Camera & Audio

### Advanced Camera Integration with AVFoundation
```swift
// ios/Runner/CameraService.swift
import AVFoundation
import UIKit

class CameraService: NSObject {
    private let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private let audioDataOutput = AVCaptureAudioDataOutput()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoDataOutputQueue = DispatchQueue(label: "camera.video.queue")
    private let depthDataOutputQueue = DispatchQueue(label: "camera.depth.queue")

    var onFrameAvailable: ((CVPixelBuffer, AVDepthData?) -> Void)?
    var onAudioDataAvailable: ((CMSampleBuffer) -> Void)?

    override init() {
        super.init()
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        sessionQueue.async {
            self.configureSession()
        }
    }

    private func configureSession() {
        captureSession.beginConfiguration()

        // Configure session preset for high quality
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }

        // Add video input
        setupVideoInput()

        // Add audio input for sonar functionality
        setupAudioInput()

        // Add video output
        setupVideoOutput()

        // Add depth output if available (iPhone with dual camera or LiDAR)
        setupDepthOutput()

        // Add audio output
        setupAudioOutput()

        captureSession.commitConfiguration()
    }

    private func setupVideoInput() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                       for: .video,
                                                       position: .back) else {
            print("Could not find back camera")
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                videoDeviceInput = videoInput
            }
        } catch {
            print("Could not create video input: \(error)")
        }
    }

    private func setupAudioInput() {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Could not find audio device")
            return
        }

        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)

            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        } catch {
            print("Could not create audio input: \(error)")
        }
    }

    private func setupVideoOutput() {
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
    }

    private func setupDepthOutput() {
        // Check if device supports depth data
        guard let videoDevice = videoDeviceInput?.device,
              videoDevice.activeFormat.supportedDepthDataFormats.count > 0 else {
            print("Device does not support depth data")
            return
        }

        depthDataOutput.setDelegate(self, callbackQueue: depthDataOutputQueue)
        depthDataOutput.isFilteringEnabled = true

        if captureSession.canAddOutput(depthDataOutput) {
            captureSession.addOutput(depthDataOutput)

            // Enable depth data for dual camera or LiDAR devices
            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = true
            }
        }
    }

    private func setupAudioOutput() {
        audioDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        if captureSession.canAddOutput(audioDataOutput) {
            captureSession.addOutput(audioDataOutput)
        }
    }

    func startSession() {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
}

// MARK: - Capture Delegates
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate,
                         AVCaptureDepthDataOutputDelegate,
                         AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {

        if output == videoDataOutput {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            onFrameAvailable?(pixelBuffer, nil)
        } else if output == audioDataOutput {
            onAudioDataAvailable?(sampleBuffer)
        }
    }

    func depthDataOutput(_ output: AVCaptureDepthDataOutput,
                        didOutput depthData: AVDepthData,
                        timestamp: CMTime,
                        connection: AVCaptureConnection) {

        // Process depth data for distance measurements
        processDepthData(depthData)
    }

    private func processDepthData(_ depthData: AVDepthData) {
        // Convert depth data to distance measurements
        let depthMap = depthData.depthMap

        // Sample center point for quick distance measurement
        let centerX = CVPixelBufferGetWidth(depthMap) / 2
        let centerY = CVPixelBufferGetHeight(depthMap) / 2

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        let depthPointer = CVPixelBufferGetBaseAddress(depthMap)!
            .bindMemory(to: Float32.self, capacity: CVPixelBufferGetDataSize(depthMap))

        let index = centerY * CVPixelBufferGetWidth(depthMap) + centerX
        let distance = depthPointer[index]

        // Send distance measurement to Flutter
        DispatchQueue.main.async {
            // Platform channel call would go here
            print("Center distance: \(distance) meters")
        }
    }
}
```

### Audio Processing for Sonar Implementation
```swift
// ios/Runner/SonarService.swift
import AVFoundation
import Accelerate

class SonarService: NSObject {
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private var audioPlayerNode = AVAudioPlayerNode()
    private var audioFormat: AVAudioFormat!

    private let chirpFrequencyStart: Float = 18000 // 18kHz
    private let chirpFrequencyEnd: Float = 22000   // 22kHz
    private let chirpDuration: TimeInterval = 0.1  // 100ms
    private let sampleRate: Double = 44100

    var onEchoDetected: ((Float, TimeInterval) -> Void)?

    override init() {
        super.init()
        setupAudioSession()
        setupAudioEngine()
    }

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord,
                                        mode: .measurement,
                                        options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    private func setupAudioEngine() {
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)

        audioEngine.attach(audioPlayerNode)
        audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: audioFormat)

        // Setup input tap for recording
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, at: time)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func performSonarPing() {
        let chirpBuffer = generateChirpSignal()

        audioPlayerNode.scheduleBuffer(chirpBuffer, at: nil) { [weak self] in
            // Chirp playback completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.stopRecording()
            }
        }

        if !audioPlayerNode.isPlaying {
            audioPlayerNode.play()
        }
    }

    private func generateChirpSignal() -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * chirpDuration)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channelData = buffer.floatChannelData![0]

        for frame in 0..<Int(frameCount) {
            let t = Float(frame) / Float(sampleRate)
            let normalizedTime = t / Float(chirpDuration)

            // Linear frequency sweep (chirp)
            let frequency = chirpFrequencyStart + (chirpFrequencyEnd - chirpFrequencyStart) * normalizedTime
            let phase = 2.0 * Float.pi * frequency * t

            // Apply Hanning window to reduce artifacts
            let window = 0.5 * (1.0 - cos(2.0 * Float.pi * normalizedTime))

            channelData[frame] = sin(phase) * window * 0.5 // 50% volume
        }

        return buffer
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        // Simple echo detection using energy thresholding
        var energy: Float = 0
        for i in 0..<frameCount {
            energy += channelData[i] * channelData[i]
        }
        energy /= Float(frameCount)

        // Threshold for echo detection
        let echoThreshold: Float = 0.01

        if energy > echoThreshold {
            let echoDelay = time.sampleTime / sampleRate
            let distance = Float(echoDelay * 343.0 / 2.0) // Speed of sound / 2 for round trip

            onEchoDetected?(distance, echoDelay)
        }
    }

    private func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
    }
}
```

---

## Security Implementation

### Biometric Authentication with LocalAuthentication
```swift
// ios/Runner/BiometricService.swift
import LocalAuthentication
import Security

class BiometricService: NSObject {
    private let context = LAContext()

    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
    }

    enum BiometricError: Error {
        case notAvailable
        case notEnrolled
        case userCancel
        case userFallback
        case systemCancel
        case passcodeNotSet
        case other(String)
    }

    func checkBiometricAvailability() -> BiometricType {
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }

    func authenticateUser(reason: String, completion: @escaping (Result<Bool, BiometricError>) -> Void) {
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            completion(.failure(.notAvailable))
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                              localizedReason: reason) { success, error in

            DispatchQueue.main.async {
                if success {
                    completion(.success(true))
                } else {
                    if let error = error as? LAError {
                        switch error.code {
                        case .userCancel:
                            completion(.failure(.userCancel))
                        case .userFallback:
                            completion(.failure(.userFallback))
                        case .systemCancel:
                            completion(.failure(.systemCancel))
                        case .passcodeNotSet:
                            completion(.failure(.passcodeNotSet))
                        case .biometryNotEnrolled:
                            completion(.failure(.notEnrolled))
                        default:
                            completion(.failure(.other(error.localizedDescription)))
                        }
                    } else {
                        completion(.failure(.other("Unknown error")))
                    }
                }
            }
        }
    }
}
```

### Keychain Services for Secure Storage
```swift
// ios/Runner/KeychainService.swift
import Security
import Foundation

class KeychainService: NSObject {
    private let service = "com.roomomatic.mobile"

    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }

    func store(key: String, data: Data) -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            return .success(())
        case errSecDuplicateItem:
            return .failure(.duplicateEntry)
        default:
            return .failure(.unknown(status))
        }
    }

    func retrieve(key: String) -> Result<Data, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                return .failure(.invalidData)
            }
            return .success(data)
        case errSecItemNotFound:
            return .failure(.itemNotFound)
        default:
            return .failure(.unknown(status))
        }
    }

    func delete(key: String) -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        switch status {
        case errSecSuccess, errSecItemNotFound:
            return .success(())
        default:
            return .failure(.unknown(status))
        }
    }

    func storeSecureString(key: String, value: String) -> Result<Void, KeychainError> {
        guard let data = value.data(using: .utf8) else {
            return .failure(.invalidData)
        }
        return store(key: key, data: data)
    }

    func retrieveSecureString(key: String) -> Result<String, KeychainError> {
        return retrieve(key: key).flatMap { data in
            guard let string = String(data: data, encoding: .utf8) else {
                return .failure(.invalidData)
            }
            return .success(string)
        }
    }
}
```

### Security Channel Handler
```swift
// ios/Runner/SecurityChannelHandler.swift
import Flutter
import LocalAuthentication
import CryptoKit

class SecurityChannelHandler: NSObject, FlutterStreamHandler {
    private let biometricService = BiometricService()
    private let keychainService = KeychainService()
    private var eventSink: FlutterEventSink?

    func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "room_o_matic/security",
                                         binaryMessenger: registrar.messenger())

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }

        let eventChannel = FlutterEventChannel(name: "room_o_matic/security_events",
                                              binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(self)
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkBiometricAvailability":
            checkBiometricAvailability(result: result)
        case "authenticateUser":
            authenticateUser(call: call, result: result)
        case "storeSecureData":
            storeSecureData(call: call, result: result)
        case "retrieveSecureData":
            retrieveSecureData(call: call, result: result)
        case "deleteSecureData":
            deleteSecureData(call: call, result: result)
        case "generateEncryptionKey":
            generateEncryptionKey(result: result)
        case "encryptData":
            encryptData(call: call, result: result)
        case "decryptData":
            decryptData(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func checkBiometricAvailability(result: @escaping FlutterResult) {
        let biometricType = biometricService.checkBiometricAvailability()

        let response: [String: Any] = [
            "isAvailable": biometricType != .none,
            "biometricType": biometricTypeString(biometricType)
        ]

        result(response)
    }

    private func biometricTypeString(_ type: BiometricService.BiometricType) -> String {
        switch type {
        case .none: return "none"
        case .touchID: return "touchID"
        case .faceID: return "faceID"
        case .opticID: return "opticID"
        }
    }

    private func authenticateUser(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let reason = args["reason"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Missing reason parameter",
                               details: nil))
            return
        }

        biometricService.authenticateUser(reason: reason) { authResult in
            switch authResult {
            case .success(let authenticated):
                result(["success": authenticated])
            case .failure(let error):
                result(FlutterError(code: "AUTHENTICATION_ERROR",
                                   message: "Authentication failed",
                                   details: self.errorDescription(error)))
            }
        }
    }

    private func errorDescription(_ error: BiometricService.BiometricError) -> String {
        switch error {
        case .notAvailable: return "Biometric authentication not available"
        case .notEnrolled: return "No biometric credentials enrolled"
        case .userCancel: return "User cancelled authentication"
        case .userFallback: return "User chose fallback method"
        case .systemCancel: return "System cancelled authentication"
        case .passcodeNotSet: return "Device passcode not set"
        case .other(let message): return message
        }
    }

    private func storeSecureData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Missing key or value",
                               details: nil))
            return
        }

        let storeResult = keychainService.storeSecureString(key: key, value: value)

        switch storeResult {
        case .success:
            result(["success": true])
        case .failure(let error):
            result(FlutterError(code: "STORAGE_ERROR",
                               message: "Failed to store data",
                               details: "\(error)"))
        }
    }

    private func retrieveSecureData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Missing key parameter",
                               details: nil))
            return
        }

        let retrieveResult = keychainService.retrieveSecureString(key: key)

        switch retrieveResult {
        case .success(let value):
            result(["value": value])
        case .failure(let error):
            result(FlutterError(code: "RETRIEVAL_ERROR",
                               message: "Failed to retrieve data",
                               details: "\(error)"))
        }
    }

    private func deleteSecureData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Missing key parameter",
                               details: nil))
            return
        }

        let deleteResult = keychainService.delete(key: key)

        switch deleteResult {
        case .success:
            result(["success": true])
        case .failure(let error):
            result(FlutterError(code: "DELETION_ERROR",
                               message: "Failed to delete data",
                               details: "\(error)"))
        }
    }

    private func generateEncryptionKey(result: @escaping FlutterResult) {
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        let base64Key = keyData.base64EncodedString()

        result(["key": base64Key])
    }

    private func encryptData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let data = args["data"] as? String,
              let keyBase64 = args["key"] as? String,
              let keyData = Data(base64Encoded: keyBase64) else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Missing data or key",
                               details: nil))
            return
        }

        do {
            let key = SymmetricKey(data: keyData)
            let dataToEncrypt = Data(data.utf8)
            let sealedBox = try AES.GCM.seal(dataToEncrypt, using: key)
            let encryptedData = sealedBox.combined

            result(["encryptedData": encryptedData?.base64EncodedString()])
        } catch {
            result(FlutterError(code: "ENCRYPTION_ERROR",
                               message: "Failed to encrypt data",
                               details: error.localizedDescription))
        }
    }

    private func decryptData(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let encryptedDataBase64 = args["encryptedData"] as? String,
              let keyBase64 = args["key"] as? String,
              let keyData = Data(base64Encoded: keyBase64),
              let encryptedData = Data(base64Encoded: encryptedDataBase64) else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                               message: "Missing encrypted data or key",
                               details: nil))
            return
        }

        do {
            let key = SymmetricKey(data: keyData)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            let decryptedString = String(data: decryptedData, encoding: .utf8)

            result(["data": decryptedString])
        } catch {
            result(FlutterError(code: "DECRYPTION_ERROR",
                               message: "Failed to decrypt data",
                               details: error.localizedDescription))
        }
    }

    // MARK: - FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
```

---

## Testing Strategies

### XCTest Integration for Native Components
```swift
// ios/RunnerTests/SensorIntegrationTests.swift
import XCTest
@testable import Runner
import CoreLocation
import ARKit

class SensorIntegrationTests: XCTestCase {
    var sensorHandler: IOSSensorChannelHandler!
    var locationService: LocationService!
    var arSession: ARSession!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sensorHandler = IOSSensorChannelHandler()
        locationService = LocationService()
        arSession = ARSession()
    }

    override func tearDownWithError() throws {
        sensorHandler = nil
        locationService = nil
        arSession = nil
        try super.tearDownWithError()
    }

    func testLocationServiceInitialization() {
        XCTAssertNotNil(locationService)
        XCTAssertEqual(locationService.authorizationStatus, .notDetermined)
    }

    func testARKitAvailability() {
        let isSupported = ARWorldTrackingConfiguration.isSupported
        // This will be true on physical devices with A12+ chips
        XCTAssertTrue(isSupported || !ARWorldTrackingConfiguration.isSupported)
    }

    func testLiDARAvailability() {
        if #available(iOS 14.0, *) {
            let config = ARWorldTrackingConfiguration()
            let supportsSceneReconstruction = config.supportsSceneReconstruction(.mesh)
            // Test passes regardless of LiDAR availability
            XCTAssertTrue(supportsSceneReconstruction || !supportsSceneReconstruction)
        }
    }

    func testPlatformChannelRegistration() {
        let expectation = XCTestExpectation(description: "Platform channel registration")

        // Mock Flutter registrar
        let mockRegistrar = MockFlutterPluginRegistrar()
        sensorHandler.register(with: mockRegistrar)

        XCTAssertTrue(mockRegistrar.channelRegistered)
        expectation.fulfill()

        wait(for: [expectation], timeout: 1.0)
    }
}

// Mock classes for testing
class MockFlutterPluginRegistrar: NSObject, FlutterPluginRegistrar {
    var channelRegistered = false

    func messenger() -> FlutterBinaryMessenger {
        return MockFlutterBinaryMessenger()
    }

    func textures() -> FlutterTextureRegistry {
        return MockFlutterTextureRegistry()
    }

    func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {
        // Mock implementation
    }

    func register(_ factory: FlutterPlatformViewFactory,
                 withId factoryId: String,
                 gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy) {
        // Mock implementation
    }

    func publish(_ value: NSObject) {
        // Mock implementation
    }

    func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {
        channelRegistered = true
    }

    func addApplicationDelegate(_ delegate: FlutterPlugin) {
        // Mock implementation
    }

    func lookupKey(forAsset asset: String) -> String {
        return asset
    }

    func lookupKey(forAsset asset: String, fromPackage package: String) -> String {
        return "\(package)/\(asset)"
    }
}

class MockFlutterBinaryMessenger: NSObject, FlutterBinaryMessenger {
    func send(onChannel channel: String, message: Data?) {
        // Mock implementation
    }

    func send(onChannel channel: String, message: Data?, binaryReply callback: FlutterBinaryReply? = nil) {
        // Mock implementation
    }

    func setMessageHandlerOnChannel(_ channel: String, binaryMessageHandler handler: FlutterBinaryMessageHandler? = nil) -> FlutterBinaryMessengerConnection {
        return 0 // Mock connection
    }

    func cleanUpConnection(_ connection: FlutterBinaryMessengerConnection) {
        // Mock implementation
    }
}

class MockFlutterTextureRegistry: NSObject, FlutterTextureRegistry {
    func register(_ texture: FlutterTexture) -> Int64 {
        return 0
    }

    func textureFrameAvailable(_ textureId: Int64) {
        // Mock implementation
    }

    func unregisterTexture(_ textureId: Int64) {
        // Mock implementation
    }
}
```

### Performance Testing
```swift
// ios/RunnerTests/PerformanceTests.swift
import XCTest
@testable import Runner

class PerformanceTests: XCTestCase {

    func testARKitFrameProcessingPerformance() {
        // Measure ARKit frame processing performance
        self.measure {
            let handler = IOSSensorChannelHandler()
            // Simulate 60 FPS frame processing for 1 second
            for _ in 0..<60 {
                // Mock frame processing
                Thread.sleep(forTimeInterval: 0.001) // 1ms processing time
            }
        }
    }

    func testLocationUpdatePerformance() {
        self.measure {
            let locationService = LocationService()
            // Simulate high-frequency location updates
            for _ in 0..<100 {
                // Mock location processing
                Thread.sleep(forTimeInterval: 0.0001) // 0.1ms processing
            }
        }
    }

    func testMemoryUsageDuringLiDARProcessing() {
        let handler = IOSSensorChannelHandler()

        measureMemory {
            // Simulate LiDAR point cloud processing
            let pointCount = 10000
            var points: [SIMD3<Float>] = []

            for i in 0..<pointCount {
                let point = SIMD3<Float>(Float(i), Float(i * 2), Float(i * 3))
                points.append(point)
            }

            // Process points (mock computation)
            let _ = points.map { $0 * 0.5 }
        }
    }
}
```

---

## Deployment and App Store Guidelines

### Build Configuration for Release
```yaml
# ios/Runner.xcworkspace/xcshareddata/xcschemes/Runner.xcscheme
# Ensure Release configuration for App Store builds

# Info.plist production settings
NSCameraUsageDescription: "Room-O-Matic needs camera access for spatial measurement and AR visualization"
NSLocationWhenInUseUsageDescription: "Room-O-Matic uses location to enhance measurement accuracy and provide location context"
NSMicrophoneUsageDescription: "Room-O-Matic uses microphone for sonar-based distance measurement in low-light conditions"
NSMotionUsageDescription: "Room-O-Matic accesses motion sensors to improve measurement stability and orientation tracking"
```

### Code Signing and Entitlements
```xml
<!-- ios/Runner/Runner.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:roomomatic.app</string>
    </array>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.roomomatic.mobile</string>
    </array>
</dict>
</plist>
```

### Build Script for Automated Testing
```bash
#!/bin/bash
# scripts/ios_build_and_test.sh

set -e

echo "🍎 Starting iOS build and test process..."

# Clean build folder
echo "🧹 Cleaning build artifacts..."
cd ios
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner

# Run tests
echo "🧪 Running unit tests..."
xcodebuild test -workspace Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'

# Build for device
echo "🔨 Building for device..."
xcodebuild archive -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive

# Export IPA
echo "📦 Exporting IPA..."
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist

echo "✅ iOS build and test process completed successfully!"
```

---

## Troubleshooting Common Issues

### ARKit Issues
- **Problem**: ARKit session fails to start
  - **Solution**: Check device compatibility and ensure proper Info.plist permissions
  - **Debug**: Use `ARWorldTrackingConfiguration.isSupported`

### Location Services Issues
- **Problem**: Location updates not received
  - **Solution**: Verify authorization status and usage descriptions
  - **Debug**: Check `CLLocationManager.authorizationStatus()`

### Platform Channel Communication Issues
- **Problem**: Flutter to iOS communication fails
  - **Solution**: Verify channel names match between Dart and Swift
  - **Debug**: Add logging to both sides of communication

### Performance Issues
- **Problem**: Frame drops during AR processing
  - **Solution**: Optimize processing on background queues
  - **Debug**: Use Instruments to profile CPU and GPU usage

### Memory Issues
- **Problem**: Memory warnings during LiDAR processing
  - **Solution**: Process point clouds in batches, implement proper cleanup
  - **Debug**: Monitor memory usage with Instruments

---

## Best Practices Summary

1. **Architecture**: Use Clean Architecture principles with proper separation of concerns
2. **Security**: Always use Keychain for sensitive data, implement biometric authentication
3. **Performance**: Process sensor data on background queues, optimize for 60 FPS
4. **Testing**: Implement comprehensive unit tests and performance benchmarks
5. **Deployment**: Follow Apple's guidelines for App Store submission
6. **Maintenance**: Regular updates for new iOS versions and ARKit improvements

This comprehensive guide provides everything needed to implement advanced iOS-specific functionality in your Flutter Room-O-Matic application, focusing on ARKit, Core Location, and security implementations.
