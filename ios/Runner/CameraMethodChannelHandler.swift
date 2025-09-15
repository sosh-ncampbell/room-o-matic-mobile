// 📸 Room-O-Matic Mobile: iOS Camera Method Channel Handler
// Platform channel bridge for iOS camera operations

import Flutter
import UIKit
import os.log

@objc class CameraMethodChannelHandler: NSObject, FlutterPlugin {
    private let logger = OSLog(subsystem: "com.roomomatic.mobile", category: "CameraMethodChannel")
    private var cameraService: IOSCameraService?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.roomomatic.camera", binaryMessenger: registrar.messenger())
        let instance = CameraMethodChannelHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        os_log("Method called: %{public}@", log: logger, type: .info, call.method)

        switch call.method {
        case "initialize":
            initialize(call: call, result: result)
        case "isCameraAvailable":
            isCameraAvailable(result: result)
        case "getAvailableCameras":
            getAvailableCameras(result: result)
        case "startPreview":
            startPreview(result: result)
        case "stopPreview":
            stopPreview(result: result)
        case "startScanSession":
            startScanSession(call: call, result: result)
        case "stopScanSession":
            stopScanSession(result: result)
        case "captureFrame":
            captureFrame(result: result)
        case "getCameraCapabilities":
            getCameraCapabilities(result: result)
        case "updateConfiguration":
            updateConfiguration(call: call, result: result)
        case "getCurrentConfiguration":
            getCurrentConfiguration(result: result)
        case "isConfigurationSupported":
            isConfigurationSupported(call: call, result: result)
        case "setFocusPoint":
            setFocusPoint(call: call, result: result)
        case "setExposurePoint":
            setExposurePoint(call: call, result: result)
        case "setZoomLevel":
            setZoomLevel(call: call, result: result)
        case "getZoomLevel":
            getZoomLevel(result: result)
        case "toggleFlash":
            toggleFlash(result: result)
        case "setFlashMode":
            setFlashMode(call: call, result: result)
        case "isFlashAvailable":
            isFlashAvailable(result: result)
        case "getCameraPermissionStatus":
            getCameraPermissionStatus(result: result)
        case "requestCameraPermission":
            requestCameraPermission(result: result)
        case "dispose":
            dispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Method Implementations

    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
            let configMap = args["configuration"] as? [String: Any]
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENT", message: "Configuration is required", details: nil))
            return
        }

        guard let configuration = parseCameraConfiguration(configMap) else {
            result(
                FlutterError(
                    code: "INVALID_CONFIGURATION", message: "Invalid camera configuration",
                    details: nil))
            return
        }

        // Create camera service if needed
        if cameraService == nil {
            cameraService = IOSCameraService()
        }

        cameraService?.initialize(configuration: configuration) { [weak self] success, error in
            if success {
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "INITIALIZATION_FAILED", message: error ?? "Unknown error",
                        details: nil))
            }
        }
    }

    private func isCameraAvailable(result: @escaping FlutterResult) {
        getCameraService().isCameraAvailable { isAvailable in
            result(isAvailable)
        }
    }

    private func getAvailableCameras(result: @escaping FlutterResult) {
        getCameraService().getAvailableCameras { cameras in
            let cameraList = cameras.map { camera in
                return [
                    "id": camera.id,
                    "lensDirection": camera.lensDirection,
                    "name": camera.name,
                    "supportedResolutions": camera.supportedResolutions,
                    "supportsDepthData": camera.supportsDepthData,
                    "supportsFaceDetection": camera.supportsFaceDetection,
                    "supportsObjectDetection": camera.supportsObjectDetection,
                    "minZoom": camera.minZoom,
                    "maxZoom": camera.maxZoom,
                ]
            }
            result(cameraList)
        }
    }

    private func startPreview(result: @escaping FlutterResult) {
        guard let service = cameraService else {
            result(
                FlutterError(
                    code: "NOT_INITIALIZED", message: "Camera not initialized", details: nil))
            return
        }

        service.startPreview { success, error in
            if success {
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "PREVIEW_START_ERROR", message: error ?? "Unknown error", details: nil
                    ))
            }
        }
    }

    private func stopPreview(result: @escaping FlutterResult) {
        guard let service = cameraService else {
            result(
                FlutterError(
                    code: "NOT_INITIALIZED", message: "Camera not initialized", details: nil))
            return
        }

        service.stopPreview { success, error in
            if success {
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "PREVIEW_STOP_ERROR", message: error ?? "Unknown error", details: nil)
                )
            }
        }
    }

    private func startScanSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let service = cameraService else {
            result(
                FlutterError(
                    code: "NOT_INITIALIZED", message: "Camera not initialized", details: nil))
            return
        }

        guard let args = call.arguments as? [String: Any],
            let configMap = args["configuration"] as? [String: Any],
            let configuration = parseCameraConfiguration(configMap)
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENT", message: "Configuration is required", details: nil))
            return
        }

        service.startScanSession(configuration: configuration) { session, error in
            if let session = session {
                let sessionMap = [
                    "sessionId": session.sessionId,
                    "startTime": session.startTime,
                    "endTime": session.endTime as Any,
                    "configuration": self.serializeCameraConfiguration(session.configuration),
                    "status": session.status,
                ]
                result(sessionMap)
            } else {
                result(
                    FlutterError(
                        code: "SCAN_SESSION_START_ERROR", message: error ?? "Unknown error",
                        details: nil))
            }
        }
    }

    private func stopScanSession(result: @escaping FlutterResult) {
        guard let service = cameraService else {
            result(
                FlutterError(
                    code: "NOT_INITIALIZED", message: "Camera not initialized", details: nil))
            return
        }

        service.stopScanSession { success, error in
            if success {
                result(true)
            } else {
                result(
                    FlutterError(
                        code: "SCAN_SESSION_STOP_ERROR", message: error ?? "Unknown error",
                        details: nil))
            }
        }
    }

    private func captureFrame(result: @escaping FlutterResult) {
        guard let service = cameraService else {
            result(
                FlutterError(
                    code: "NOT_INITIALIZED", message: "Camera not initialized", details: nil))
            return
        }

        service.captureFrame { frameData, error in
            if let frame = frameData {
                let frameMap = [
                    "frameId": frame.frameId,
                    "timestamp": frame.timestamp,
                    "format": frame.format,
                    "width": frame.width,
                    "height": frame.height,
                    "data": FlutterStandardTypedData(bytes: frame.data),
                ]
                result(frameMap)
            } else {
                result(
                    FlutterError(
                        code: "FRAME_CAPTURE_ERROR", message: error ?? "Capture failed",
                        details: nil))
            }
        }
    }

    private func getCameraCapabilities(result: @escaping FlutterResult) {
        getCameraService().getCameraCapabilities { capabilities in
            let capabilitiesMap = [
                "supportedResolutions": capabilities.supportedResolutions,
                "supportedFormats": capabilities.supportedFormats,
                "supportedFlashModes": capabilities.supportedFlashModes,
                "supportedExposureModes": capabilities.supportedExposureModes,
                "supportedFocusModes": capabilities.supportedFocusModes,
                "supportsImageStabilization": capabilities.supportsImageStabilization,
                "supportsAutoFocus": capabilities.supportsAutoFocus,
                "supportsDepthData": capabilities.supportsDepthData,
                "supportsFaceDetection": capabilities.supportsFaceDetection,
                "supportsObjectDetection": capabilities.supportsObjectDetection,
                "minZoom": capabilities.minZoom,
                "maxZoom": capabilities.maxZoom,
                "supportedFrameRates": capabilities.supportedFrameRates,
            ]
            result(capabilitiesMap)
        }
    }

    private func updateConfiguration(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Camera configuration update implementation would go here
        result(true)
    }

    private func getCurrentConfiguration(result: @escaping FlutterResult) {
        // Return current camera configuration - for now return nil
        result(nil)
    }

    private func isConfigurationSupported(call: FlutterMethodCall, result: @escaping FlutterResult)
    {
        // Configuration support check implementation would go here
        result(true)
    }

    private func setFocusPoint(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Focus point setting implementation would go here
        result(true)
    }

    private func setExposurePoint(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Exposure point setting implementation would go here
        result(true)
    }

    private func setZoomLevel(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Zoom level setting implementation would go here
        result(true)
    }

    private func getZoomLevel(result: @escaping FlutterResult) {
        // Return current zoom level - for now return 1.0 (no zoom)
        result(1.0)
    }

    private func toggleFlash(result: @escaping FlutterResult) {
        // Flash toggle implementation would go here
        result(true)
    }

    private func setFlashMode(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Flash mode setting implementation would go here
        result(true)
    }

    private func isFlashAvailable(result: @escaping FlutterResult) {
        // Flash availability check implementation would go here
        result(true)
    }

    private func getCameraPermissionStatus(result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let statusString = authorizationStatusToString(status)
        result(statusString)
    }

    private func requestCameraPermission(result: @escaping FlutterResult) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                result(granted ? "granted" : "denied")
            }
        }
    }

    private func dispose(result: @escaping FlutterResult) {
        cameraService?.dispose()
        cameraService = nil
        result(true)
    }

    // MARK: - Helper Methods

    private func getCameraService() -> IOSCameraService {
        if let service = cameraService {
            return service
        }

        let service = IOSCameraService()
        cameraService = service
        return service
    }

    private func parseCameraConfiguration(_ configMap: [String: Any]) -> CameraConfigurationData? {
        return CameraConfigurationData(
            lensDirection: configMap["lensDirection"] as? String ?? "back",
            resolution: configMap["resolution"] as? String ?? "high",
            frameRate: configMap["frameRate"] as? Int ?? 30,
            enableImageStabilization: configMap["enableImageStabilization"] as? Bool ?? true,
            enableAutoFocus: configMap["enableAutoFocus"] as? Bool ?? true,
            flashMode: configMap["flashMode"] as? String ?? "off",
            exposureMode: configMap["exposureMode"] as? String ?? "auto",
            focusMode: configMap["focusMode"] as? String ?? "auto",
            enableDepthData: configMap["enableDepthData"] as? Bool ?? false,
            format: configMap["format"] as? String ?? "yuv420"
        )
    }

    private func serializeCameraConfiguration(_ config: CameraConfigurationData) -> [String: Any] {
        return [
            "lensDirection": config.lensDirection,
            "resolution": config.resolution,
            "frameRate": config.frameRate,
            "enableImageStabilization": config.enableImageStabilization,
            "enableAutoFocus": config.enableAutoFocus,
            "flashMode": config.flashMode,
            "exposureMode": config.exposureMode,
            "focusMode": config.focusMode,
            "enableDepthData": config.enableDepthData,
            "format": config.format,
        ]
    }

    private func authorizationStatusToString(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized:
            return "granted"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "notDetermined"
        @unknown default:
            return "notDetermined"
        }
    }
}
