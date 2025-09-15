// 📸 Room-O-Matic Mobile: Camera Integration Tests
// Comprehensive testing for camera functionality

import 'package:flutter_test/flutter_test.dart';
import 'package:room_o_matic_mobile/domain/entities/camera/camera_data.dart';
import 'package:room_o_matic_mobile/domain/repositories/camera_repository.dart';
import 'package:room_o_matic_mobile/domain/use_cases/camera_use_cases.dart';

void main() {
  group('Camera Data Entities', () {
    test('CameraConfiguration should create with default values', () {
      const config = CameraConfiguration();

      expect(config.lensDirection, CameraLensDirection.back);
      expect(config.resolution, CameraResolution.high);
      expect(config.frameRate, 30);
      expect(config.enableImageStabilization, true);
      expect(config.enableAutoFocus, true);
      expect(config.flashMode, CameraFlashMode.off);
      expect(config.exposureMode, CameraExposureMode.auto);
      expect(config.focusMode, CameraFocusMode.auto);
      expect(config.enableDepthData, false);
      expect(config.format, CameraFormat.yuv420);
    });

    test('CameraConfiguration should validate correctly', () {
      const validConfig = CameraConfiguration(frameRate: 30);
      const invalidConfig = CameraConfiguration(frameRate: 0);

      expect(validConfig.isValid, true);
      expect(invalidConfig.isValid, false);
    });

    test('CameraConfiguration should check depth data support', () {
      const backCameraWithDepth = CameraConfiguration(
        lensDirection: CameraLensDirection.back,
        enableDepthData: true,
      );
      const frontCameraWithDepth = CameraConfiguration(
        lensDirection: CameraLensDirection.front,
        enableDepthData: true,
      );

      expect(backCameraWithDepth.supportsDepthData, true);
      expect(frontCameraWithDepth.supportsDepthData, false);
    });

    test('CameraConfiguration should calculate buffer sizes correctly', () {
      const highResConfig = CameraConfiguration(
        resolution: CameraResolution.high,
        format: CameraFormat.yuv420,
      );
      const ultraResConfig = CameraConfiguration(
        resolution: CameraResolution.ultra,
        format: CameraFormat.rgba8888,
      );

      expect(highResConfig.getBufferSize(), (1920 * 1080 * 1.5).round());
      expect(ultraResConfig.getBufferSize(), 3840 * 2160 * 4);
    });

    test('CameraFrame should have correct properties', () {
      final frame = CameraFrame(
        frameId: 'test-frame-123',
        timestamp: DateTime.now(),
        format: CameraFrameFormat.yuv420,
        width: 1920,
        height: 1080,
        data: List.generate(1920 * 1080, (i) => i % 256),
      );

      expect(frame.frameId, 'test-frame-123');
      expect(frame.aspectRatio, 1920 / 1080);
      expect(frame.dataSizeBytes, 1920 * 1080);
      expect(frame.hasDepthData, false);
      expect(frame.hasDetectedObjects, false);
      expect(frame.detectedObjectCount, 0);
    });

    test('CameraFrame should detect recent frames', () {
      final recentFrame = CameraFrame(
        frameId: 'recent',
        timestamp: DateTime.now(),
        format: CameraFrameFormat.yuv420,
        width: 640,
        height: 480,
        data: [],
      );

      final oldFrame = CameraFrame(
        frameId: 'old',
        timestamp: DateTime.now().subtract(const Duration(seconds: 1)),
        format: CameraFrameFormat.yuv420,
        width: 640,
        height: 480,
        data: [],
      );

      expect(recentFrame.isRecent, true);
      expect(oldFrame.isRecent, false);
    });

    test('CameraFrame should detect depth data', () {
      final frameWithDepth = CameraFrame(
        frameId: 'depth-frame',
        timestamp: DateTime.now(),
        format: CameraFrameFormat.yuv420,
        width: 640,
        height: 480,
        data: [],
        depthData: const CameraDepthData(
          width: 640,
          height: 480,
          depthMap: [1.0, 2.0, 3.0],
          minDepth: 0.1,
          maxDepth: 10.0,
          accuracy: CameraDepthAccuracy.absolute,
          format: CameraDepthFormat.float32,
        ),
      );

      final frameWithoutDepth = CameraFrame(
        frameId: 'no-depth',
        timestamp: DateTime.now(),
        format: CameraFrameFormat.yuv420,
        width: 640,
        height: 480,
        data: [],
      );

      expect(frameWithDepth.hasDepthData, true);
      expect(frameWithoutDepth.hasDepthData, false);
    });

    test('CameraFrame should detect objects', () {
      final frameWithObjects = CameraFrame(
        frameId: 'objects-frame',
        timestamp: DateTime.now(),
        format: CameraFrameFormat.yuv420,
        width: 640,
        height: 480,
        data: [],
        metadata: const CameraFrameMetadata(
          exposureTime: 1.0 / 60,
          iso: 100,
          focalLength: 28.0,
          aperture: 2.8,
          whiteBalance: CameraWhiteBalance.auto,
          orientation: CameraOrientation.portrait,
          detectedObjects: [
            CameraObject(
              objectId: 'obj1',
              label: 'person',
              confidence: 0.95,
              boundingBox: CameraRect(left: 0, top: 0, right: 100, bottom: 100),
            ),
          ],
        ),
      );

      expect(frameWithObjects.hasDetectedObjects, true);
      expect(frameWithObjects.detectedObjectCount, 1);
    });

    test('CameraScanSession should calculate duration correctly', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(minutes: 5));

      final session = CameraScanSession(
        sessionId: 'test-session',
        startTime: startTime,
        endTime: endTime,
        configuration: const CameraConfiguration(),
        status: CameraScanStatus.completed,
      );

      expect(session.duration, const Duration(minutes: 5));
      expect(session.isActive, false);
    });

    test('CameraScanSession should detect active status', () {
      final activeSession = CameraScanSession(
        sessionId: 'active-session',
        startTime: DateTime.now(),
        configuration: const CameraConfiguration(),
        status: CameraScanStatus.scanning,
      );

      final completedSession = CameraScanSession(
        sessionId: 'completed-session',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        configuration: const CameraConfiguration(),
        status: CameraScanStatus.completed,
      );

      expect(activeSession.isActive, true);
      expect(completedSession.isActive, false);
    });

    test('CameraScanSession should calculate frame metrics', () {
      final frames = List.generate(
        10,
        (i) => CameraFrame(
          frameId: 'frame-$i',
          timestamp: DateTime.now(),
          format: CameraFrameFormat.yuv420,
          width: 640,
          height: 480,
          data: [],
          depthData: i % 2 == 0
              ? const CameraDepthData(
                  width: 640,
                  height: 480,
                  depthMap: [],
                  minDepth: 0.1,
                  maxDepth: 10.0,
                  accuracy: CameraDepthAccuracy.absolute,
                  format: CameraDepthFormat.float32,
                )
              : null,
          metadata: i % 3 == 0
              ? const CameraFrameMetadata(
                  exposureTime: 1.0 / 60,
                  iso: 100,
                  focalLength: 28.0,
                  aperture: 2.8,
                  whiteBalance: CameraWhiteBalance.auto,
                  orientation: CameraOrientation.portrait,
                  detectedObjects: [
                    CameraObject(
                      objectId: 'obj1',
                      label: 'test',
                      confidence: 0.8,
                      boundingBox:
                          CameraRect(left: 0, top: 0, right: 50, bottom: 50),
                    ),
                  ],
                )
              : null,
        ),
      );

      final session = CameraScanSession(
        sessionId: 'metrics-session',
        startTime: DateTime.now().subtract(const Duration(seconds: 10)),
        endTime: DateTime.now(),
        configuration: const CameraConfiguration(),
        frames: frames,
        status: CameraScanStatus.completed,
      );

      expect(session.framesWithDepthData, 5); // Even indices
      expect(session.totalDetectedObjects, 4); // Indices 0, 3, 6, 9
      expect(session.averageFrameRate, 1.0); // 10 frames / 10 seconds
    });
  });

  group('Camera Use Cases', () {
    late CameraRepository mockRepository;
    late InitializeCameraServicesUseCase initializeUseCase;
    late StartVisualScanSessionUseCase startScanUseCase;
    late ProcessCameraFramesUseCase processFramesUseCase;
    late OptimizeCameraSettingsUseCase optimizeSettingsUseCase;
    late CaptureMeasurementFramesUseCase captureFramesUseCase;

    setUp(() {
      mockRepository = MockCameraRepository();
      initializeUseCase = InitializeCameraServicesUseCase(mockRepository);
      startScanUseCase = StartVisualScanSessionUseCase(mockRepository);
      processFramesUseCase = ProcessCameraFramesUseCase(mockRepository);
      optimizeSettingsUseCase = OptimizeCameraSettingsUseCase(mockRepository);
      captureFramesUseCase = CaptureMeasurementFramesUseCase(mockRepository);
    });

    test(
        'InitializeCameraServicesUseCase should create optimized configuration',
        () async {
      final result = await initializeUseCase.execute();

      expect(result.isSuccess, true);
      expect(result.configuration, isNotNull);
      expect(result.capabilities, isNotNull);
    });

    test('StartVisualScanSessionUseCase should start scan session', () async {
      const config = CameraConfiguration(resolution: CameraResolution.high);
      final result = await startScanUseCase.execute(configuration: config);

      expect(result.isSuccess, true);
      expect(result.session, isNotNull);
      expect(result.configuration, isNotNull);
    });

    test('OptimizeCameraSettingsUseCase should optimize for indoor environment',
        () async {
      const config = CameraConfiguration();
      final result = await optimizeSettingsUseCase.execute(
        environment: CameraScanEnvironment.indoor,
        goal: CameraOptimizationGoal.quality,
      );

      expect(result.isSuccess, true);
      expect(result.configuration, isNotNull);
      expect(result.improvements, isNotNull);
      expect(result.improvements!.isNotEmpty, true);
    });

    test('OptimizeCameraSettingsUseCase should optimize for low light',
        () async {
      const config = CameraConfiguration();
      final result = await optimizeSettingsUseCase.execute(
        environment: CameraScanEnvironment.lowLight,
        goal: CameraOptimizationGoal.balanced,
      );

      expect(result.isSuccess, true);
      expect(result.configuration!.frameRate, 24); // Lower for better exposure
    });

    test('CaptureMeasurementFramesUseCase should capture multiple frames',
        () async {
      final result = await captureFramesUseCase.execute(
        frameCount: 5,
        interval: const Duration(milliseconds: 100),
        requireDepthData: false,
      );

      expect(result.isSuccess, true);
      expect(result.frames, isNotNull);
      expect(result.capturedCount, 5);
      expect(result.successRate, 1.0);
    });

    test('CaptureMeasurementFramesUseCase should filter frames by quality',
        () async {
      final result = await captureFramesUseCase.execute(
        frameCount: 10,
        requireDepthData: false,
        minQualityThreshold: 0.8,
      );

      expect(result.isSuccess, true);
      // Note: In real implementation, this would filter based on actual quality
    });
  });

  group('Camera Enumerations', () {
    test('CameraLensDirection should have correct values', () {
      expect(CameraLensDirection.values.length, 3);
      expect(
          CameraLensDirection.values.contains(CameraLensDirection.front), true);
      expect(
          CameraLensDirection.values.contains(CameraLensDirection.back), true);
      expect(CameraLensDirection.values.contains(CameraLensDirection.external),
          true);
    });

    test('CameraResolution should have correct values', () {
      expect(CameraResolution.values.length, 4);
      expect(CameraResolution.values.contains(CameraResolution.low), true);
      expect(CameraResolution.values.contains(CameraResolution.medium), true);
      expect(CameraResolution.values.contains(CameraResolution.high), true);
      expect(CameraResolution.values.contains(CameraResolution.ultra), true);
    });

    test('CameraScanStatus should have correct values', () {
      expect(CameraScanStatus.values.length, 6);
      expect(CameraScanStatus.values.contains(CameraScanStatus.idle), true);
      expect(CameraScanStatus.values.contains(CameraScanStatus.scanning), true);
      expect(
          CameraScanStatus.values.contains(CameraScanStatus.completed), true);
    });

    test('CameraPermissionStatus should have correct values', () {
      expect(CameraPermissionStatus.values.length, 5);
      expect(
          CameraPermissionStatus.values
              .contains(CameraPermissionStatus.granted),
          true);
      expect(
          CameraPermissionStatus.values.contains(CameraPermissionStatus.denied),
          true);
    });
  });

  group('Camera Result Classes', () {
    test('CameraInitializationResult should handle success', () {
      const config = CameraConfiguration();
      const capabilities = CameraCapabilities(
        supportedResolutions: [CameraResolution.high],
        supportedFormats: [CameraFormat.yuv420],
        supportedFlashModes: [CameraFlashMode.off],
        supportedExposureModes: [CameraExposureMode.auto],
        supportedFocusModes: [CameraFocusMode.auto],
        supportsImageStabilization: true,
        supportsAutoFocus: true,
        supportsDepthData: false,
        supportsFaceDetection: true,
        supportsObjectDetection: true,
        zoomRange: CameraZoomRange(minZoom: 1.0, maxZoom: 4.0),
        supportedFrameRates: [30],
      );

      final result = CameraInitializationResult.success(
        configuration: config,
        capabilities: capabilities,
      );

      expect(result.isSuccess, true);
      expect(result.error, isNull);
      expect(result.configuration, config);
      expect(result.capabilities, capabilities);
    });

    test('CameraInitializationResult should handle failure', () {
      final result = CameraInitializationResult.failure('Test error');

      expect(result.isSuccess, false);
      expect(result.error, 'Test error');
      expect(result.configuration, isNull);
      expect(result.capabilities, isNull);
    });

    test('MeasurementFrameCaptureResult should calculate success rate', () {
      final result = MeasurementFrameCaptureResult.success(
        frames: [],
        requestedCount: 10,
        capturedCount: 8,
      );

      expect(result.successRate, 0.8);
    });

    test('MeasurementFrameCaptureResult should handle zero requested count',
        () {
      final result = MeasurementFrameCaptureResult.success(
        frames: [],
        requestedCount: 0,
        capturedCount: 0,
      );

      expect(result.successRate, 0.0);
    });
  });

  group('Camera Quality Analysis', () {
    test('CameraFrameQuality should determine good quality for scanning', () {
      const goodQuality = CameraFrameQuality(
        sharpness: 0.8,
        brightness: 0.5,
        contrast: 0.7,
        noiseLevel: 0.2,
        isBlurred: false,
        isOverexposed: false,
        isUnderexposed: false,
      );

      const poorQuality = CameraFrameQuality(
        sharpness: 0.5,
        brightness: 0.3,
        contrast: 0.4,
        noiseLevel: 0.6,
        isBlurred: true,
        isOverexposed: false,
        isUnderexposed: true,
      );

      expect(goodQuality.isGoodForScanning, true);
      expect(poorQuality.isGoodForScanning, false);
    });

    test('CameraFrameQuality should reject blurred frames', () {
      const blurredQuality = CameraFrameQuality(
        sharpness: 0.9,
        brightness: 0.5,
        contrast: 0.7,
        noiseLevel: 0.1,
        isBlurred: true,
        isOverexposed: false,
        isUnderexposed: false,
      );

      expect(blurredQuality.isGoodForScanning, false);
    });

    test('CameraFrameQuality should reject overexposed frames', () {
      const overexposedQuality = CameraFrameQuality(
        sharpness: 0.9,
        brightness: 0.5,
        contrast: 0.7,
        noiseLevel: 0.1,
        isBlurred: false,
        isOverexposed: true,
        isUnderexposed: false,
      );

      expect(overexposedQuality.isGoodForScanning, false);
    });
  });
}

// Mock repository for testing
class MockCameraRepository implements CameraRepository {
  @override
  Future<void> initialize(CameraConfiguration configuration) async {
    // Mock implementation
  }

  @override
  Future<bool> isCameraAvailable() async => true;

  @override
  Future<List<CameraInfo>> getAvailableCameras() async {
    return [
      const CameraInfo(
        id: 'back-camera',
        lensDirection: CameraLensDirection.back,
        name: 'Back Camera',
        supportedResolutions: [CameraResolution.high, CameraResolution.ultra],
        supportsDepthData: true,
        supportsFaceDetection: true,
        supportsObjectDetection: true,
        zoomRange: CameraZoomRange(minZoom: 1.0, maxZoom: 4.0),
      ),
    ];
  }

  @override
  Future<void> startPreview() async {}

  @override
  Future<void> stopPreview() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<CameraScanSession> startScanSession(
      CameraConfiguration configuration) async {
    return CameraScanSession(
      sessionId: 'mock-session',
      startTime: DateTime.now(),
      configuration: configuration,
      status: CameraScanStatus.scanning,
    );
  }

  @override
  Future<void> stopScanSession() async {}

  @override
  CameraScanSession? getCurrentSession() => null;

  @override
  Future<CameraFrame> captureFrame() async {
    return CameraFrame(
      frameId: 'mock-frame',
      timestamp: DateTime.now(),
      format: CameraFrameFormat.yuv420,
      width: 1920,
      height: 1080,
      data: List.generate(1920 * 1080, (i) => i % 256),
    );
  }

  @override
  Stream<CameraFrame> getFrameStream() => const Stream.empty();

  @override
  Future<void> updateConfiguration(CameraConfiguration configuration) async {}

  @override
  Future<CameraConfiguration> getCurrentConfiguration() async {
    return const CameraConfiguration();
  }

  @override
  Future<bool> isConfigurationSupported(
          CameraConfiguration configuration) async =>
      true;

  @override
  Future<CameraCapabilities> getCameraCapabilities() async {
    return const CameraCapabilities(
      supportedResolutions: [CameraResolution.high, CameraResolution.ultra],
      supportedFormats: [CameraFormat.yuv420, CameraFormat.rgba8888],
      supportedFlashModes: [CameraFlashMode.off, CameraFlashMode.on],
      supportedExposureModes: [CameraExposureMode.auto],
      supportedFocusModes: [CameraFocusMode.auto, CameraFocusMode.continuous],
      supportsImageStabilization: true,
      supportsAutoFocus: true,
      supportsDepthData: true,
      supportsFaceDetection: true,
      supportsObjectDetection: true,
      zoomRange: CameraZoomRange(minZoom: 1.0, maxZoom: 4.0),
      supportedFrameRates: [30, 60],
    );
  }

  @override
  Future<bool> isDepthDataSupported() async => true;

  @override
  Future<bool> isFaceDetectionSupported() async => true;

  @override
  Future<bool> isObjectDetectionSupported() async => true;

  @override
  Future<void> setFocusPoint(CameraPoint point) async {}

  @override
  Future<void> setExposurePoint(CameraPoint point) async {}

  @override
  Future<void> setZoomLevel(double zoomLevel) async {}

  @override
  Future<double> getZoomLevel() async => 1.0;

  @override
  Future<CameraZoomRange> getZoomRange() async {
    return const CameraZoomRange(minZoom: 1.0, maxZoom: 4.0);
  }

  @override
  Future<void> toggleFlash() async {}

  @override
  Future<void> setFlashMode(CameraFlashMode mode) async {}

  @override
  Future<bool> isFlashAvailable() async => true;

  @override
  Future<List<CameraObject>> detectObjects(CameraFrame frame) async => [];

  @override
  Future<List<CameraFace>> detectFaces(CameraFrame frame) async => [];

  @override
  Future<CameraDepthData?> extractDepthData(CameraFrame frame) async => null;

  @override
  Future<CameraFrameQuality> analyzeFrameQuality(CameraFrame frame) async {
    return const CameraFrameQuality(
      sharpness: 0.8,
      brightness: 0.5,
      contrast: 0.7,
      noiseLevel: 0.2,
      isBlurred: false,
      isOverexposed: false,
      isUnderexposed: false,
    );
  }

  @override
  Future<void> saveScanSession(CameraScanSession session) async {}

  @override
  Future<CameraScanSession?> loadScanSession(String sessionId) async => null;

  @override
  Future<List<CameraScanSession>> getAllScanSessions() async => [];

  @override
  Future<void> deleteScanSession(String sessionId) async {}

  @override
  Future<CameraPermissionStatus> getCameraPermissionStatus() async {
    return CameraPermissionStatus.granted;
  }

  @override
  Future<CameraPermissionStatus> requestCameraPermission() async {
    return CameraPermissionStatus.granted;
  }

  @override
  Future<CameraPermissionStatus> getMicrophonePermissionStatus() async {
    return CameraPermissionStatus.granted;
  }

  @override
  Future<CameraPermissionStatus> requestMicrophonePermission() async {
    return CameraPermissionStatus.granted;
  }
}
