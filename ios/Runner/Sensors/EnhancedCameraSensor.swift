//
//  EnhancedCameraSensor.swift
//  Runner
//
//  Enhanced Camera Sensor for Room-O-Matic Mobile
//  Provides advanced camera features including depth, ARKit integration, and frame analysis
//

import ARKit
import AVFoundation
import CoreImage
import Foundation
import Vision

@available(iOS 11.3, *)
class EnhancedCameraSensor: NSObject {

    // MARK: - Properties

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var depthOutput: AVCaptureDepthDataOutput?
    private var device: AVCaptureDevice?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // ARKit properties
    private var arSession: ARSession?
    private var arConfiguration: ARWorldTrackingConfiguration?

    // Frame analysis
    private let visionQueue = DispatchQueue(label: "com.roomomatic.vision", qos: .userInitiated)
    private let sessionQueue = DispatchQueue(label: "com.roomomatic.camera", qos: .userInitiated)

    // Capabilities
    private var capabilities: [String: Any] = [:]
    private var isSessionRunning = false
    private var isARSessionRunning = false

    // Callbacks
    private var frameCallback: ((String, [String: Any]) -> Void)?
    private var depthCallback: ((String, [String: Any]) -> Void)?
    private var arFrameCallback: ((String, [String: Any]) -> Void)?

    // MARK: - Initialization

    override init() {
        super.init()
        setupCapabilities()
    }

    // MARK: - Public Methods

    /// Initialize enhanced camera sensor with configuration
    func initialize(config: [String: Any], completion: @escaping (Bool, [String: Any]?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                completion(false, ["error": "Sensor deallocated"])
                return
            }

            do {
                try self.setupCaptureSession(config: config)

                if config["enableAR"] as? Bool == true {
                    self.setupARSession(config: config)
                }

                DispatchQueue.main.async {
                    completion(true, self.capabilities)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, ["error": error.localizedDescription])
                }
            }
        }
    }

    /// Start camera session
    func startSession(completion: @escaping (Bool, String?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                completion(false, "Sensor deallocated")
                return
            }

            guard let session = self.captureSession else {
                completion(false, "Capture session not initialized")
                return
            }

            if !session.isRunning {
                session.startRunning()
                self.isSessionRunning = true
            }

            if let arSession = self.arSession, !self.isARSessionRunning {
                arSession.run(self.arConfiguration ?? ARWorldTrackingConfiguration())
                self.isARSessionRunning = true
            }

            DispatchQueue.main.async {
                completion(true, nil)
            }
        }
    }

    /// Stop camera session
    func stopSession(completion: @escaping (Bool, String?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self else {
                completion(false, "Sensor deallocated")
                return
            }

            self.captureSession?.stopRunning()
            self.isSessionRunning = false

            if self.isARSessionRunning {
                self.arSession?.pause()
                self.isARSessionRunning = false
            }

            DispatchQueue.main.async {
                completion(true, nil)
            }
        }
    }

    /// Capture photo with depth data
    func capturePhoto(settings: [String: Any], completion: @escaping (Bool, [String: Any]?) -> Void)
    {
        guard let photoOutput = self.photoOutput else {
            completion(false, ["error": "Photo output not available"])
            return
        }

        let photoSettings = AVCapturePhotoSettings()
        photoSettings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
        photoSettings.isPortraitEffectsMatteDeliveryEnabled =
            photoOutput.isPortraitEffectsMatteDeliverySupported

        if let format = settings["format"] as? String {
            switch format {
            case "heif":
                photoSettings.photoCodecType = .hevc
            case "jpeg":
                photoSettings.photoCodecType = .jpeg
            default:
                break
            }
        }

        let delegate = PhotoCaptureDelegate { [weak self] result in
            completion(result.success, result.data)
        }

        photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
    }

    /// Set frame callback for real-time processing
    func setFrameCallback(_ callback: @escaping (String, [String: Any]) -> Void) {
        self.frameCallback = callback
    }

    /// Set depth callback for depth data processing
    func setDepthCallback(_ callback: @escaping (String, [String: Any]) -> Void) {
        self.depthCallback = callback
    }

    /// Set AR frame callback for ARKit data
    func setARFrameCallback(_ callback: @escaping (String, [String: Any]) -> Void) {
        self.arFrameCallback = callback
    }

    /// Get current camera capabilities
    func getCapabilities() -> [String: Any] {
        return capabilities
    }

    /// Measure distance using depth data
    func measureDepthDistance(
        fromPoint: CGPoint, toPoint: CGPoint, completion: @escaping (Bool, [String: Any]?) -> Void
    ) {
        // This would use the latest depth frame to calculate distance
        // Implementation would require storing the latest depth data
        completion(false, ["error": "Depth distance measurement not yet implemented"])
    }

    // MARK: - Private Methods

    private func setupCapabilities() {
        var caps: [String: Any] = [:]

        // Basic camera capabilities
        caps["hasCamera"] = !AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices.isEmpty

        // Depth capabilities
        if #available(iOS 11.1, *) {
            caps["supportsDepth"] =
                AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil
                || AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
                    != nil
        } else {
            caps["supportsDepth"] = false
        }

        // ARKit capabilities
        caps["supportsARKit"] = ARWorldTrackingConfiguration.isSupported
        caps["supportsLiDAR"] = false

        if #available(iOS 13.4, *) {
            caps["supportsLiDAR"] = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        }

        // Advanced features
        caps["supportsPortraitMatte"] = true
        caps["supportsHEIF"] = true
        caps["supportsBurstCapture"] = true
        caps["supportsVideoStabilization"] = true

        self.capabilities = caps
    }

    private func setupCaptureSession(config: [String: Any]) throws {
        let session = AVCaptureSession()

        // Configure session preset
        if let preset = config["sessionPreset"] as? String {
            switch preset {
            case "high":
                session.sessionPreset = .high
            case "medium":
                session.sessionPreset = .medium
            case "low":
                session.sessionPreset = .low
            case "photo":
                session.sessionPreset = .photo
            case "4K":
                if session.canSetSessionPreset(.hd4K3840x2160) {
                    session.sessionPreset = .hd4K3840x2160
                }
            default:
                session.sessionPreset = .high
            }
        }

        // Setup camera device
        let devicePosition: AVCaptureDevice.Position =
            config["cameraPosition"] as? String == "front" ? .front : .back

        guard let device = getBestCameraDevice(for: devicePosition) else {
            throw CameraSensorError.deviceNotAvailable
        }

        let input = try AVCaptureDeviceInput(device: device)

        if session.canAddInput(input) {
            session.addInput(input)
            self.device = device
        } else {
            throw CameraSensorError.cannotAddInput
        }

        // Setup photo output
        let photoOutput = AVCapturePhotoOutput()
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            self.photoOutput = photoOutput

            // Enable depth data if supported
            if photoOutput.isDepthDataDeliverySupported {
                photoOutput.isDepthDataDeliveryEnabled = true
            }
        }

        // Setup video output for frame processing
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }

        // Setup depth output if available
        if #available(iOS 11.0, *) {
            let depthOutput = AVCaptureDepthDataOutput()
            depthOutput.setDelegate(self, callbackQueue: sessionQueue)

            if session.canAddOutput(depthOutput) {
                session.addOutput(depthOutput)
                self.depthOutput = depthOutput

                // Synchronize depth with video
                if let videoConnection = videoOutput.connection(with: .video),
                    let depthConnection = depthOutput.connection(with: .depthData)
                {
                    depthOutput.isFilteringEnabled = true
                }
            }
        }

        self.captureSession = session
    }

    private func setupARSession(config: [String: Any]) {
        guard ARWorldTrackingConfiguration.isSupported else { return }

        let arSession = ARSession()
        let configuration = ARWorldTrackingConfiguration()

        // Configure ARKit features
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic

        if #available(iOS 13.4, *) {
            if config["enableSceneReconstruction"] as? Bool == true {
                configuration.sceneReconstruction = .mesh
            }
        }

        if #available(iOS 13.0, *) {
            configuration.frameSemantics = .personSegmentationWithDepth
        }

        arSession.delegate = self

        self.arSession = arSession
        self.arConfiguration = configuration
    }

    private func getBestCameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // Try to get the best available camera for the position
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera,
            .builtInDualWideCamera,
            .builtInDualCamera,
            .builtInWideAngleCamera,
        ]

        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: position
        )

        return discovery.devices.first
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension EnhancedCameraSensor: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let frameCallback = frameCallback else { return }

        visionQueue.async { [weak self] in
            guard let self = self else { return }

            let frameData = self.processVideoFrame(sampleBuffer)

            DispatchQueue.main.async {
                frameCallback("frame", frameData)
            }
        }
    }

    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) -> [String: Any] {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        var frameData: [String: Any] = [
            "timestamp": Int64(timestamp.seconds * 1000),
            "frameId": UUID().uuidString,
        ]

        // Extract frame resolution
        if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            frameData["width"] = Int(dimensions.width)
            frameData["height"] = Int(dimensions.height)
        }

        // Process with Vision framework for additional analysis
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return frameData
        }

        frameData["pixelFormat"] = CVPixelBufferGetPixelFormatType(pixelBuffer)

        return frameData
    }
}

// MARK: - AVCaptureDepthDataOutputDelegate

@available(iOS 11.0, *)
extension EnhancedCameraSensor: AVCaptureDepthDataOutputDelegate {

    func depthDataOutput(
        _ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime,
        connection: AVCaptureConnection
    ) {
        guard let depthCallback = depthCallback else { return }

        visionQueue.async { [weak self] in
            guard let self = self else { return }

            let depthInfo = self.processDepthData(depthData, timestamp: timestamp)

            DispatchQueue.main.async {
                depthCallback("depth", depthInfo)
            }
        }
    }

    private func processDepthData(_ depthData: AVDepthData, timestamp: CMTime) -> [String: Any] {
        var depthInfo: [String: Any] = [
            "timestamp": Int64(timestamp.seconds * 1000),
            "depthId": UUID().uuidString,
        ]

        // Extract depth map properties
        let depthMap = depthData.depthDataMap
        depthInfo["width"] = CVPixelBufferGetWidth(depthMap)
        depthInfo["height"] = CVPixelBufferGetHeight(depthMap)
        depthInfo["pixelFormat"] = CVPixelBufferGetPixelFormatType(depthMap)

        // Calibration data
        if let calibrationData = depthData.cameraCalibrationData {
            var calibration: [String: Any] = [:]

            let intrinsics = calibrationData.intrinsicMatrix
            calibration["intrinsicMatrix"] = [
                [intrinsics.columns.0.x, intrinsics.columns.1.x, intrinsics.columns.2.x],
                [intrinsics.columns.0.y, intrinsics.columns.1.y, intrinsics.columns.2.y],
                [intrinsics.columns.0.z, intrinsics.columns.1.z, intrinsics.columns.2.z],
            ]

            calibration["pixelSize"] = calibrationData.pixelSize
            calibration["lensDistortionLookupTable"] =
                calibrationData.lensDistortionLookupTable?.bytes

            depthInfo["calibration"] = calibration
        }

        // Quality and accuracy
        depthInfo["quality"] = depthData.depthDataQuality.rawValue
        depthInfo["accuracy"] = depthData.depthDataAccuracy.rawValue
        depthInfo["isFiltered"] = depthData.isDepthDataFiltered

        return depthInfo
    }
}

// MARK: - ARSessionDelegate

@available(iOS 11.0, *)
extension EnhancedCameraSensor: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let arFrameCallback = arFrameCallback else { return }

        visionQueue.async { [weak self] in
            guard let self = self else { return }

            let arData = self.processARFrame(frame)

            DispatchQueue.main.async {
                arFrameCallback("arFrame", arData)
            }
        }
    }

    private func processARFrame(_ frame: ARFrame) -> [String: Any] {
        var arData: [String: Any] = [
            "timestamp": Int64(frame.timestamp * 1000),
            "frameId": UUID().uuidString,
        ]

        // Camera transform
        let transform = frame.camera.transform
        arData["cameraTransform"] = [
            "matrix": [
                [
                    transform.columns.0.x, transform.columns.1.x, transform.columns.2.x,
                    transform.columns.3.x,
                ],
                [
                    transform.columns.0.y, transform.columns.1.y, transform.columns.2.y,
                    transform.columns.3.y,
                ],
                [
                    transform.columns.0.z, transform.columns.1.z, transform.columns.2.z,
                    transform.columns.3.z,
                ],
                [
                    transform.columns.0.w, transform.columns.1.w, transform.columns.2.w,
                    transform.columns.3.w,
                ],
            ]
        ]

        // Camera intrinsics
        let intrinsics = frame.camera.intrinsics
        arData["intrinsics"] = [
            "matrix": [
                [intrinsics.columns.0.x, intrinsics.columns.1.x, intrinsics.columns.2.x],
                [intrinsics.columns.0.y, intrinsics.columns.1.y, intrinsics.columns.2.y],
                [intrinsics.columns.0.z, intrinsics.columns.1.z, intrinsics.columns.2.z],
            ]
        ]

        // Anchors
        var anchors: [[String: Any]] = []
        for anchor in frame.anchors {
            var anchorData: [String: Any] = [
                "identifier": anchor.identifier.uuidString,
                "transform": [
                    "matrix": [
                        [
                            anchor.transform.columns.0.x, anchor.transform.columns.1.x,
                            anchor.transform.columns.2.x, anchor.transform.columns.3.x,
                        ],
                        [
                            anchor.transform.columns.0.y, anchor.transform.columns.1.y,
                            anchor.transform.columns.2.y, anchor.transform.columns.3.y,
                        ],
                        [
                            anchor.transform.columns.0.z, anchor.transform.columns.1.z,
                            anchor.transform.columns.2.z, anchor.transform.columns.3.z,
                        ],
                        [
                            anchor.transform.columns.0.w, anchor.transform.columns.1.w,
                            anchor.transform.columns.2.w, anchor.transform.columns.3.w,
                        ],
                    ]
                ],
            ]

            if let planeAnchor = anchor as? ARPlaneAnchor {
                anchorData["type"] = "plane"
                anchorData["alignment"] = planeAnchor.alignment.rawValue
                anchorData["center"] = [
                    planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z,
                ]
                anchorData["extent"] = [
                    planeAnchor.extent.x, planeAnchor.extent.y, planeAnchor.extent.z,
                ]
            }

            anchors.append(anchorData)
        }
        arData["anchors"] = anchors

        // Light estimation
        if let lightEstimate = frame.lightEstimate {
            arData["lightEstimate"] = [
                "ambientIntensity": lightEstimate.ambientIntensity,
                "ambientColorTemperature": lightEstimate.ambientColorTemperature,
            ]
        }

        return arData
    }
}

// MARK: - Photo Capture Delegate

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {

    private let completion: (PhotoCaptureResult) -> Void

    init(completion: @escaping (PhotoCaptureResult) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            completion(
                PhotoCaptureResult(success: false, data: ["error": error.localizedDescription]))
            return
        }

        var photoData: [String: Any] = [
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "photoId": UUID().uuidString,
        ]

        // Photo data
        if let imageData = photo.fileDataRepresentation() {
            photoData["imageData"] = imageData.base64EncodedString()
            photoData["dataSize"] = imageData.count
        }

        // Depth data
        if let depthData = photo.depthData {
            let depthMap = depthData.depthDataMap
            photoData["depthData"] = [
                "width": CVPixelBufferGetWidth(depthMap),
                "height": CVPixelBufferGetHeight(depthMap),
                "pixelFormat": CVPixelBufferGetPixelFormatType(depthMap),
                "quality": depthData.depthDataQuality.rawValue,
            ]
        }

        // Portrait effects matte
        if let portraitMatte = photo.portraitEffectsMatte {
            let matteMap = portraitMatte.mattingImage
            photoData["portraitMatte"] = [
                "width": CVPixelBufferGetWidth(matteMap),
                "height": CVPixelBufferGetHeight(matteMap),
            ]
        }

        completion(PhotoCaptureResult(success: true, data: photoData))
    }
}

// MARK: - Supporting Types

private struct PhotoCaptureResult {
    let success: Bool
    let data: [String: Any]?
}

private enum CameraSensorError: Error {
    case deviceNotAvailable
    case cannotAddInput
    case cannotAddOutput
    case sessionNotRunning

    var localizedDescription: String {
        switch self {
        case .deviceNotAvailable:
            return "Camera device not available"
        case .cannotAddInput:
            return "Cannot add camera input to session"
        case .cannotAddOutput:
            return "Cannot add output to session"
        case .sessionNotRunning:
            return "Camera session not running"
        }
    }
}
#endif // iOS
