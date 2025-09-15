// 📸 Room-O-Matic Mobile: iOS Camera Service
// Advanced camera integration using AVFoundation for room scanning

import AVFoundation
import CoreML
import UIKit
import Vision
import os.log

@objc class IOSCameraService: NSObject {
    private let logger = OSLog(subsystem: "com.roomomatic.mobile", category: "Camera")

    // Camera session and configuration
    private var captureSession: AVCaptureSession?
    private var videoDevice: AVCaptureDevice?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var depthDataOutput: AVCaptureDepthDataOutput?

    // Session management
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoDataOutputQueue = DispatchQueue(label: "camera.video.queue")

    // Configuration and state
    private var currentConfiguration: CameraConfigurationData?
    private var isInitialized = false
    private var isPreviewStarted = false
    private var currentScanSession: CameraScanSessionData?

    // Frame processing
    private var frameHandler: ((CameraFrameData) -> Void)?
    private var isProcessingFrames = false

    // MARK: - Initialization

    func initialize(
        configuration: CameraConfigurationData, completion: @escaping (Bool, String?) -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(false, "Service deallocated") }
                return
            }

            os_log("Initializing camera with configuration", log: self.logger, type: .info)

            do {
                // Check authorization
                let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
                guard authStatus == .authorized else {
                    DispatchQueue.main.async {
                        completion(false, "Camera permission not authorized")
                    }
                    return
                }

                // Setup capture session
                try self.setupCaptureSession(with: configuration)

                self.currentConfiguration = configuration
                self.isInitialized = true

                DispatchQueue.main.async { completion(true, nil) }

            } catch {
                os_log(
                    "Camera initialization failed: %{public}@", log: self.logger, type: .error,
                    error.localizedDescription)
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        }
    }

    private func setupCaptureSession(with configuration: CameraConfigurationData) throws {
        // Create capture session
        let session = AVCaptureSession()
        session.sessionPreset = getSessionPreset(for: configuration.resolution)

        // Setup video device
        guard let videoDevice = getVideoDevice(for: configuration.lensDirection) else {
            throw CameraError.deviceNotFound
        }

        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        guard session.canAddInput(videoDeviceInput) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(videoDeviceInput)

        // Setup video data output
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        // Configure video settings
        let videoSettings = getVideoSettings(for: configuration)
        videoDataOutput.videoSettings = videoSettings

        guard session.canAddOutput(videoDataOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(videoDataOutput)

        // Setup photo output
        let photoOutput = AVCapturePhotoOutput()
        guard session.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(photoOutput)

        // Setup depth data output if supported and enabled
        if configuration.enableDepthData
            && videoDevice.activeFormat.supportedDepthDataFormats.count > 0
        {
            let depthDataOutput = AVCaptureDepthDataOutput()
            depthDataOutput.setDelegate(self, callbackQueue: videoDataOutputQueue)

            guard session.canAddOutput(depthDataOutput) else {
                throw CameraError.cannotAddOutput
            }
            session.addOutput(depthDataOutput)

            // Enable depth data delivery
            depthDataOutput.isFilteringEnabled = false

            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = true
            }

            self.depthDataOutput = depthDataOutput
        }

        // Configure device settings
        try configureDevice(videoDevice, with: configuration)

        // Store references
        self.captureSession = session
        self.videoDevice = videoDevice
        self.videoDeviceInput = videoDeviceInput
        self.videoDataOutput = videoDataOutput
        self.photoOutput = photoOutput
    }

    private func configureDevice(
        _ device: AVCaptureDevice, with configuration: CameraConfigurationData
    ) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        // Configure focus mode
        if device.isFocusModeSupported(getFocusMode(for: configuration.focusMode)) {
            device.focusMode = getFocusMode(for: configuration.focusMode)
        }

        // Configure exposure mode
        if device.isExposureModeSupported(getExposureMode(for: configuration.exposureMode)) {
            device.exposureMode = getExposureMode(for: configuration.exposureMode)
        }

        // Configure image stabilization
        if configuration.enableImageStabilization {
            for format in device.formats {
                for range in format.videoSupportedFrameRateRanges {
                    if range.maxFrameRate >= Double(configuration.frameRate) {
                        device.activeFormat = format
                        device.activeVideoMinFrameDuration = CMTimeMake(
                            value: 1, timescale: Int32(configuration.frameRate))
                        device.activeVideoMaxFrameDuration = CMTimeMake(
                            value: 1, timescale: Int32(configuration.frameRate))
                        break
                    }
                }
            }
        }

        // Configure flash mode (for photo capture)
        if device.hasFlash {
            // Flash configuration will be set per photo capture
        }
    }

    // MARK: - Camera Control

    func isCameraAvailable(completion: @escaping (Bool) -> Void) {
        let hasCamera = AVCaptureDevice.default(for: .video) != nil
        DispatchQueue.main.async { completion(hasCamera) }
    }

    func getAvailableCameras(completion: @escaping ([CameraInfoData]) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            var cameras: [CameraInfoData] = []

            // Get all available video devices
            let deviceTypes: [AVCaptureDevice.DeviceType] = [
                .builtInWideAngleCamera,
                .builtInTelephotoCamera,
                .builtInUltraWideCamera,
                .builtInDualCamera,
                .builtInTripleCamera,
                .builtInTrueDepthCamera,
            ]

            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: .unspecified
            )

            for device in discoverySession.devices {
                let cameraInfo = self.createCameraInfo(from: device)
                cameras.append(cameraInfo)
            }

            DispatchQueue.main.async { completion(cameras) }
        }
    }

    private func createCameraInfo(from device: AVCaptureDevice) -> CameraInfoData {
        let lensDirection = device.position == .front ? "front" : "back"

        // Analyze supported resolutions
        var supportedResolutions: [String] = []
        for format in device.formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let width = Int(dimensions.width)

            switch width {
            case 3840...:
                if !supportedResolutions.contains("ultra") { supportedResolutions.append("ultra") }
            case 1920...:
                if !supportedResolutions.contains("high") { supportedResolutions.append("high") }
            case 1280...:
                if !supportedResolutions.contains("medium") {
                    supportedResolutions.append("medium")
                }
            case 640...:
                if !supportedResolutions.contains("low") { supportedResolutions.append("low") }
            default:
                break
            }
        }

        // Check depth data support
        let supportsDepthData = !device.activeFormat.supportedDepthDataFormats.isEmpty

        // Get zoom range
        let maxZoom = device.activeFormat.videoMaxZoomFactor

        return CameraInfoData(
            id: device.uniqueID,
            lensDirection: lensDirection,
            name: device.localizedName,
            supportedResolutions: supportedResolutions.isEmpty ? ["medium"] : supportedResolutions,
            supportsDepthData: supportsDepthData,
            supportsFaceDetection: true,
            supportsObjectDetection: true,
            minZoom: 1.0,
            maxZoom: Double(maxZoom)
        )
    }

    func startPreview(completion: @escaping (Bool, String?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession else {
                DispatchQueue.main.async { completion(false, "Camera not initialized") }
                return
            }

            if !session.isRunning {
                session.startRunning()
                self.isPreviewStarted = true
                os_log("Camera preview started", log: self.logger, type: .info)
                DispatchQueue.main.async { completion(true, nil) }
            } else {
                DispatchQueue.main.async { completion(true, nil) }
            }
        }
    }

    func stopPreview(completion: @escaping (Bool, String?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession else {
                DispatchQueue.main.async { completion(false, "Camera not initialized") }
                return
            }

            if session.isRunning {
                session.stopRunning()
                self.isPreviewStarted = false
                os_log("Camera preview stopped", log: self.logger, type: .info)
                DispatchQueue.main.async { completion(true, nil) }
            } else {
                DispatchQueue.main.async { completion(true, nil) }
            }
        }
    }

    // MARK: - Scan Session Management

    func startScanSession(
        configuration: CameraConfigurationData,
        completion: @escaping (CameraScanSessionData?, String?) -> Void
    ) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil, "Service deallocated") }
                return
            }

            let sessionId = UUID().uuidString
            let session = CameraScanSessionData(
                sessionId: sessionId,
                startTime: Date().timeIntervalSince1970,
                configuration: configuration,
                status: "scanning"
            )

            self.currentScanSession = session
            self.isProcessingFrames = true

            os_log(
                "Camera scan session started: %{public}@", log: self.logger, type: .info, sessionId)
            DispatchQueue.main.async { completion(session, nil) }
        }
    }

    func stopScanSession(completion: @escaping (Bool, String?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(false, "Service deallocated") }
                return
            }

            if var session = self.currentScanSession {
                session.endTime = Date().timeIntervalSince1970
                session.status = "completed"
                self.currentScanSession = session
            }

            self.isProcessingFrames = false

            os_log("Camera scan session stopped", log: self.logger, type: .info)
            DispatchQueue.main.async { completion(true, nil) }
        }
    }

    // MARK: - Frame Capture

    func captureFrame(completion: @escaping (CameraFrameData?, String?) -> Void) {
        guard let photoOutput = self.photoOutput else {
            completion(nil, "Photo output not available")
            return
        }

        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true

        // Configure depth data if available
        if let depthDataOutput = self.depthDataOutput {
            settings.isDepthDataDeliveryEnabled = depthDataOutput.isDepthDataDeliveryEnabled
        }

        let photoCaptureProcessor = PhotoCaptureProcessor { [weak self] result in
            switch result {
            case .success(let frameData):
                completion(frameData, nil)
            case .failure(let error):
                completion(nil, error.localizedDescription)
            }
        }

        photoOutput.capturePhoto(with: settings, delegate: photoCaptureProcessor)
    }

    func setFrameHandler(_ handler: @escaping (CameraFrameData) -> Void) {
        self.frameHandler = handler
    }

    // MARK: - Camera Capabilities

    func getCameraCapabilities(completion: @escaping (CameraCapabilitiesData) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.videoDevice else {
                let defaultCapabilities = CameraCapabilitiesData(
                    supportedResolutions: ["medium"],
                    supportedFormats: ["yuv420"],
                    supportedFlashModes: ["off"],
                    supportedExposureModes: ["auto"],
                    supportedFocusModes: ["auto"],
                    supportsImageStabilization: false,
                    supportsAutoFocus: true,
                    supportsDepthData: false,
                    supportsFaceDetection: false,
                    supportsObjectDetection: false,
                    minZoom: 1.0,
                    maxZoom: 1.0,
                    supportedFrameRates: [30]
                )
                DispatchQueue.main.async { completion(defaultCapabilities) }
                return
            }

            let capabilities = self.createCameraCapabilities(for: device)
            DispatchQueue.main.async { completion(capabilities) }
        }
    }

    private func createCameraCapabilities(for device: AVCaptureDevice) -> CameraCapabilitiesData {
        // Analyze supported resolutions
        var supportedResolutions: [String] = []
        var supportedFrameRates: [Int] = []

        for format in device.formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let width = Int(dimensions.width)

            switch width {
            case 3840...:
                if !supportedResolutions.contains("ultra") { supportedResolutions.append("ultra") }
            case 1920...:
                if !supportedResolutions.contains("high") { supportedResolutions.append("high") }
            case 1280...:
                if !supportedResolutions.contains("medium") {
                    supportedResolutions.append("medium")
                }
            case 640...:
                if !supportedResolutions.contains("low") { supportedResolutions.append("low") }
            default:
                break
            }

            // Collect frame rates
            for range in format.videoSupportedFrameRateRanges {
                let maxRate = Int(range.maxFrameRate)
                if !supportedFrameRates.contains(maxRate) {
                    supportedFrameRates.append(maxRate)
                }
            }
        }

        supportedFrameRates.sort()

        return CameraCapabilitiesData(
            supportedResolutions: supportedResolutions.isEmpty ? ["medium"] : supportedResolutions,
            supportedFormats: ["yuv420", "bgra8888"],
            supportedFlashModes: device.hasFlash ? ["off", "on", "auto"] : ["off"],
            supportedExposureModes: ["auto", "manual", "locked"],
            supportedFocusModes: ["auto", "manual", "continuous"],
            supportsImageStabilization: device.activeFormat.isVideoStabilizationModeSupported(
                .auto),
            supportsAutoFocus: device.isFocusModeSupported(.autoFocus),
            supportsDepthData: !device.activeFormat.supportedDepthDataFormats.isEmpty,
            supportsFaceDetection: true,
            supportsObjectDetection: true,
            minZoom: 1.0,
            maxZoom: Double(device.activeFormat.videoMaxZoomFactor),
            supportedFrameRates: supportedFrameRates.isEmpty ? [30] : supportedFrameRates
        )
    }

    // MARK: - Helper Methods

    private func getVideoDevice(for lensDirection: String) -> AVCaptureDevice? {
        let position: AVCaptureDevice.Position = lensDirection == "front" ? .front : .back

        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .builtInTelephotoCamera,
            .builtInUltraWideCamera,
            .builtInDualCamera,
            .builtInTripleCamera,
        ]

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )

        return discoverySession.devices.first
    }

    private func getSessionPreset(for resolution: String) -> AVCaptureSession.Preset {
        switch resolution {
        case "ultra":
            return .hd4K3840x2160
        case "high":
            return .hd1920x1080
        case "medium":
            return .hd1280x720
        case "low":
            return .vga640x480
        default:
            return .hd1920x1080
        }
    }

    private func getVideoSettings(for configuration: CameraConfigurationData) -> [String: Any] {
        switch configuration.format {
        case "bgra8888":
            return [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        case "yuv420":
            return [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
        default:
            return [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            ]
        }
    }

    private func getFocusMode(for mode: String) -> AVCaptureDevice.FocusMode {
        switch mode {
        case "auto":
            return .autoFocus
        case "manual":
            return .locked
        case "continuous":
            return .continuousAutoFocus
        default:
            return .autoFocus
        }
    }

    private func getExposureMode(for mode: String) -> AVCaptureDevice.ExposureMode {
        switch mode {
        case "auto":
            return .autoExpose
        case "manual":
            return .custom
        case "locked":
            return .locked
        default:
            return .autoExpose
        }
    }

    func dispose() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.captureSession?.stopRunning()
            self.captureSession = nil
            self.videoDevice = nil
            self.videoDeviceInput = nil
            self.videoDataOutput = nil
            self.photoOutput = nil
            self.depthDataOutput = nil
            self.frameHandler = nil
            self.isInitialized = false
            self.isPreviewStarted = false

            os_log("Camera service disposed", log: self.logger, type: .info)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension IOSCameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isProcessingFrames, let frameHandler = frameHandler else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let frameData = processPixelBuffer(pixelBuffer)
        frameHandler(frameData)
    }

    private func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CameraFrameData {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return CameraFrameData(
                frameId: UUID().uuidString,
                timestamp: Date().timeIntervalSince1970,
                format: "yuv420",
                width: width,
                height: height,
                data: Data()
            )
        }

        let dataSize = bytesPerRow * height
        let data = Data(bytes: baseAddress, count: dataSize)

        return CameraFrameData(
            frameId: UUID().uuidString,
            timestamp: Date().timeIntervalSince1970,
            format: "yuv420",
            width: width,
            height: height,
            data: data
        )
    }
}

// MARK: - AVCaptureDepthDataOutputDelegate

extension IOSCameraService: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(
        _ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime,
        connection: AVCaptureConnection
    ) {
        // Process depth data for 3D reconstruction
        // This would be implemented based on specific depth data requirements
    }
}

// MARK: - Data Structures

struct CameraConfigurationData {
    let lensDirection: String
    let resolution: String
    let frameRate: Int
    let enableImageStabilization: Bool
    let enableAutoFocus: Bool
    let flashMode: String
    let exposureMode: String
    let focusMode: String
    let enableDepthData: Bool
    let format: String
}

struct CameraFrameData {
    let frameId: String
    let timestamp: TimeInterval
    let format: String
    let width: Int
    let height: Int
    let data: Data
}

struct CameraScanSessionData {
    let sessionId: String
    let startTime: TimeInterval
    var endTime: TimeInterval?
    let configuration: CameraConfigurationData
    var status: String
}

struct CameraInfoData {
    let id: String
    let lensDirection: String
    let name: String
    let supportedResolutions: [String]
    let supportsDepthData: Bool
    let supportsFaceDetection: Bool
    let supportsObjectDetection: Bool
    let minZoom: Double
    let maxZoom: Double
}

struct CameraCapabilitiesData {
    let supportedResolutions: [String]
    let supportedFormats: [String]
    let supportedFlashModes: [String]
    let supportedExposureModes: [String]
    let supportedFocusModes: [String]
    let supportsImageStabilization: Bool
    let supportsAutoFocus: Bool
    let supportsDepthData: Bool
    let supportsFaceDetection: Bool
    let supportsObjectDetection: Bool
    let minZoom: Double
    let maxZoom: Double
    let supportedFrameRates: [Int]
}

// MARK: - Error Types

enum CameraError: Error {
    case deviceNotFound
    case cannotAddInput
    case cannotAddOutput
    case configurationFailed
    case captureFailed
}

// MARK: - Photo Capture Processor

class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<CameraFrameData, Error>) -> Void

    init(completion: @escaping (Result<CameraFrameData, Error>) -> Void) {
        self.completion = completion
        super.init()
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            completion(.failure(CameraError.captureFailed))
            return
        }

        let frameData = CameraFrameData(
            frameId: UUID().uuidString,
            timestamp: Date().timeIntervalSince1970,
            format: "jpeg",
            width: Int(photo.resolvedSettings.photoDimensions.width),
            height: Int(photo.resolvedSettings.photoDimensions.height),
            data: imageData
        )

        completion(.success(frameData))
    }
}
