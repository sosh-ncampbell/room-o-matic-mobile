#if os(iOS)
    #if canImport(ARKit)
        import ARKit
    #endif
    import AVFoundation
    import CoreLocation
    import CoreMotion
    #if canImport(Flutter)
        import Flutter
    #endif
    import Foundation

    @available(iOS 11.0, *)
    public class SensorChannelManager: NSObject, FlutterPlugin {
        private var channel: FlutterMethodChannel
        private var arSession: ARSession?
        private var motionManager: CMMotionManager?
        private var isScanning = false

        // Advanced LiDAR support for iOS 14+
        @available(iOS 14.0, *)
        private var lidarSensor: ARKitLiDARSensor?

        // Location sensor
        private var locationSensor: CoreLocationSensor?

        // Enhanced camera sensor
        private var enhancedCameraSensor: EnhancedCameraSensor?

        public static func register(with registrar: FlutterPluginRegistrar) {
            let channel = FlutterMethodChannel(
                name: "com.roomomatic.sensors/lidar",
                binaryMessenger: registrar.messenger()
            )
            let instance = SensorChannelManager(channel: channel)
            registrar.addMethodCallDelegate(instance, channel: channel)
        }

        private init(channel: FlutterMethodChannel) {
            self.channel = channel
            super.init()
            setupMotionManager()

            // Initialize advanced LiDAR sensor on supported devices
            if #available(iOS 14.0, *) {
                lidarSensor = ARKitLiDARSensor(methodChannel: channel)
            }

            // Initialize location sensor
            locationSensor = CoreLocationSensor()

            // Initialize enhanced camera sensor
            if #available(iOS 11.3, *) {
                enhancedCameraSensor = EnhancedCameraSensor()
            }
        }

        public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
            switch call.method {
            case "startLiDARScan":
                startLiDARScan(result: result)
            case "stopLiDARScan":
                stopLiDARScan(result: result)
            case "isLiDARAvailable":
                checkLiDARAvailability(result: result)
            case "startMotionSensors":
                startMotionSensors(result: result)
            case "stopMotionSensors":
                stopMotionSensors(result: result)
            case "getCameraFrame":
                getCameraFrame(result: result)
            case "requestLocationPermission":
                requestLocationPermission(result: result)
            case "startLocationTracking":
                startLocationTracking(result: result)
            case "stopLocationTracking":
                stopLocationTracking(result: result)
            case "getCurrentLocation":
                getCurrentLocation(result: result)
            case "getLocationCapabilities":
                handleGetLocationCapabilities(result: result)

            // Enhanced Camera methods
            case "initializeEnhancedCamera":
                handleInitializeEnhancedCamera(call: call, result: result)
            case "startCameraSession":
                handleStartCameraSession(result: result)
            case "stopCameraSession":
                handleStopCameraSession(result: result)
            case "captureEnhancedPhoto":
                handleCaptureEnhancedPhoto(call: call, result: result)
            case "getEnhancedCameraCapabilities":
                handleGetEnhancedCameraCapabilities(result: result)
            case "measureCameraDistance":
                handleMeasureCameraDistance(call: call, result: result)
            case "measureLocationDistance":
                measureLocationDistance(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // MARK: - LiDAR Methods

        private func checkLiDARAvailability(result: @escaping FlutterResult) {
            if #available(iOS 13.4, *) {
                let isAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
                result(isAvailable)
            } else {
                result(false)
            }
        }

        private func startLiDARScan(result: @escaping FlutterResult) {
            guard !isScanning else {
                result(
                    FlutterError(
                        code: "SCAN_IN_PROGRESS",
                        message: "LiDAR scan is already in progress",
                        details: nil
                    ))
                return
            }

            guard #available(iOS 13.4, *),
                ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
            else {
                result(
                    FlutterError(
                        code: "LIDAR_NOT_AVAILABLE",
                        message: "LiDAR is not available on this device",
                        details: nil
                    ))
                return
            }

            arSession = ARSession()
            let configuration = ARWorldTrackingConfiguration()
            configuration.frameSemantics = .sceneDepth
            configuration.planeDetection = [.horizontal, .vertical]

            arSession?.delegate = self
            arSession?.run(configuration)
            isScanning = true

            result(true)
        }

        private func stopLiDARScan(result: @escaping FlutterResult) {
            arSession?.pause()
            arSession = nil
            isScanning = false
            result(true)
        }

        // MARK: - Motion Sensor Methods

        private func setupMotionManager() {
            motionManager = CMMotionManager()
            motionManager?.accelerometerUpdateInterval = 0.1
            motionManager?.gyroUpdateInterval = 0.1
            motionManager?.magnetometerUpdateInterval = 0.1
        }

        private func startMotionSensors(result: @escaping FlutterResult) {
            guard let motionManager = motionManager else {
                result(
                    FlutterError(
                        code: "MOTION_MANAGER_ERROR",
                        message: "Motion manager not available",
                        details: nil
                    ))
                return
            }

            if motionManager.isAccelerometerAvailable {
                motionManager.startAccelerometerUpdates(to: OperationQueue.current!) {
                    [weak self] (data, error) in
                    guard let data = data else { return }
                    self?.sendMotionData(type: "accelerometer", data: data)
                }
            }

            if motionManager.isGyroAvailable {
                motionManager.startGyroUpdates(to: OperationQueue.current!) {
                    [weak self] (data, error) in
                    guard let data = data else { return }
                    self?.sendMotionData(type: "gyroscope", data: data)
                }
            }

            if motionManager.isMagnetometerAvailable {
                motionManager.startMagnetometerUpdates(to: OperationQueue.current!) {
                    [weak self] (data, error) in
                    guard let data = data else { return }
                    self?.sendMotionData(type: "magnetometer", data: data)
                }
            }

            result(true)
        }

        private func stopMotionSensors(result: @escaping FlutterResult) {
            motionManager?.stopAccelerometerUpdates()
            motionManager?.stopGyroUpdates()
            motionManager?.stopMagnetometerUpdates()
            result(true)
        }

        private func sendMotionData(type: String, data: CMLogItem) {
            var motionData: [String: Any] = [
                "type": type,
                "timestamp": data.timestamp,
            ]

            switch data {
            case let accelerometerData as CMAccelerometerData:
                motionData["x"] = accelerometerData.acceleration.x
                motionData["y"] = accelerometerData.acceleration.y
                motionData["z"] = accelerometerData.acceleration.z
            case let gyroData as CMGyroData:
                motionData["x"] = gyroData.rotationRate.x
                motionData["y"] = gyroData.rotationRate.y
                motionData["z"] = gyroData.rotationRate.z
            case let magnetometerData as CMMagnetometerData:
                motionData["x"] = magnetometerData.magneticField.x
                motionData["y"] = magnetometerData.magneticField.y
                motionData["z"] = magnetometerData.magneticField.z
            default:
                break
            }

            channel.invokeMethod("onMotionData", arguments: motionData)
        }

        // MARK: - Camera Methods

        private func getCameraFrame(result: @escaping FlutterResult) {
            guard let arSession = arSession,
                let currentFrame = arSession.currentFrame
            else {
                result(
                    FlutterError(
                        code: "NO_CAMERA_FRAME",
                        message: "No camera frame available",
                        details: nil
                    ))
                return
            }

            let cameraTransform = currentFrame.camera.transform
            let cameraData: [String: Any] = [
                "timestamp": currentFrame.timestamp,
                "transform": [
                    cameraTransform.columns.0.x, cameraTransform.columns.0.y,
                    cameraTransform.columns.0.z, cameraTransform.columns.0.w,
                    cameraTransform.columns.1.x, cameraTransform.columns.1.y,
                    cameraTransform.columns.1.z, cameraTransform.columns.1.w,
                    cameraTransform.columns.2.x, cameraTransform.columns.2.y,
                    cameraTransform.columns.2.z, cameraTransform.columns.2.w,
                    cameraTransform.columns.3.x, cameraTransform.columns.3.y,
                    cameraTransform.columns.3.z, cameraTransform.columns.3.w,
                ],
            ]

            result(cameraData)
        }

        // MARK: - Location Methods

        private func requestLocationPermission(result: @escaping FlutterResult) {
            guard let locationSensor = locationSensor else {
                result(
                    FlutterError(
                        code: "LOCATION_SENSOR_ERROR",
                        message: "Location sensor not available",
                        details: nil
                    ))
                return
            }

            let success = locationSensor.requestLocationPermission()
            result(success)
        }

        private func startLocationTracking(result: @escaping FlutterResult) {
            guard let locationSensor = locationSensor else {
                result(
                    FlutterError(
                        code: "LOCATION_SENSOR_ERROR",
                        message: "Location sensor not available",
                        details: nil
                    ))
                return
            }

            let success = locationSensor.startLocationTracking()
            result(success)
        }

        private func stopLocationTracking(result: @escaping FlutterResult) {
            guard let locationSensor = locationSensor else {
                result(
                    FlutterError(
                        code: "LOCATION_SENSOR_ERROR",
                        message: "Location sensor not available",
                        details: nil
                    ))
                return
            }

            locationSensor.stopLocationTracking()
            result(true)
        }

        private func getCurrentLocation(result: @escaping FlutterResult) {
            guard let locationSensor = locationSensor else {
                result(
                    FlutterError(
                        code: "LOCATION_SENSOR_ERROR",
                        message: "Location sensor not available",
                        details: nil
                    ))
                return
            }

            if let locationData = locationSensor.getCurrentLocation() {
                result(locationData)
            } else {
                result(
                    FlutterError(
                        code: "NO_LOCATION_DATA",
                        message: "No location data available",
                        details: nil
                    ))
            }
        }

        private func getLocationCapabilities(result: @escaping FlutterResult) {
            guard let locationSensor = locationSensor else {
                result(
                    FlutterError(
                        code: "LOCATION_SENSOR_ERROR",
                        message: "Location sensor not available",
                        details: nil
                    ))
                return
            }

            let capabilities = locationSensor.checkLocationCapabilities()
            result(capabilities)
        }

        private func measureLocationDistance(
            call: FlutterMethodCall, result: @escaping FlutterResult
        ) {
            guard let locationSensor = locationSensor,
                let arguments = call.arguments as? [String: Any],
                let targetLocation = arguments["targetLocation"] as? [String: Double]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Invalid arguments for location distance measurement",
                        details: nil
                    ))
                return
            }

            if let distanceData = locationSensor.measureDistance(to: targetLocation) {
                result(distanceData)
            } else {
                result(
                    FlutterError(
                        code: "LOCATION_MEASUREMENT_FAILED",
                        message: "Failed to measure location distance",
                        details: nil
                    ))
            }
        }
    }

    // MARK: - ARSessionDelegate

    @available(iOS 13.4, *)
    extension SensorChannelManager: ARSessionDelegate {
        public func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let sceneDepth = frame.sceneDepth else { return }

            let depthData = sceneDepth.depthMap
            let confidenceData = sceneDepth.confidenceMap

            // Process depth data and send to Flutter
            processDepthData(depthData: depthData, confidenceData: confidenceData, frame: frame)
        }

        private func processDepthData(
            depthData: CVPixelBuffer, confidenceData: CVPixelBuffer?, frame: ARFrame
        ) {
            CVPixelBufferLockBaseAddress(depthData, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }

            let width = CVPixelBufferGetWidth(depthData)
            let height = CVPixelBufferGetHeight(depthData)
            let depthPointer = CVPixelBufferGetBaseAddress(depthData)

            var points: [[String: Any]] = []

            // Sample every 4th pixel to reduce data volume
            let stride = 4
            for y in stride(from: 0, to: height, by: stride) {
                for x in stride(from: 0, to: width, by: stride) {
                    let pixelIndex = y * width + x
                    let depth =
                        depthPointer?.load(
                            fromByteOffset: pixelIndex * MemoryLayout<Float32>.size,
                            as: Float32.self)
                        ?? 0

                    // Skip invalid depth values
                    guard depth > 0 && depth < 10.0 else { continue }

                    // Convert 2D pixel to 3D world coordinates
                    let screenPoint = CGPoint(x: x, y: y)
                    let worldPosition = frame.camera.unprojectPoint(
                        screenPoint,
                        ontoPlaneWithTransform: matrix_identity_float4x4,
                        orientation: .portrait,
                        viewportSize: CGSize(width: width, height: height)
                    )

                    let point: [String: Any] = [
                        "x": worldPosition.x,
                        "y": worldPosition.y,
                        "z": worldPosition.z,
                        "depth": depth,
                        "pixelX": x,
                        "pixelY": y,
                    ]

                    points.append(point)
                }
            }

            let lidarData: [String: Any] = [
                "timestamp": frame.timestamp,
                "points": points,
                "width": width,
                "height": height,
            ]

            channel.invokeMethod("onLiDARData", arguments: lidarData)
        }

        public func session(_ session: ARSession, didFailWithError error: Error) {
            let errorData: [String: Any] = [
                "error": error.localizedDescription
            ]
            channel.invokeMethod("onLiDARError", arguments: errorData)
        }

        // MARK: - Enhanced Camera Methods

        private func handleInitializeEnhancedCamera(
            call: FlutterMethodCall, result: @escaping FlutterResult
        ) {
            guard #available(iOS 11.3, *), let enhancedCamera = enhancedCameraSensor else {
                result(
                    FlutterError(
                        code: "UNAVAILABLE", message: "Enhanced camera not available", details: nil)
                )
                return
            }

            let config = call.arguments as? [String: Any] ?? [:]

            enhancedCamera.initialize(config: config) { success, capabilities in
                if success {
                    result(capabilities)
                } else {
                    result(
                        FlutterError(
                            code: "INIT_FAILED", message: "Failed to initialize enhanced camera",
                            details: capabilities))
                }
            }
        }

        private func handleStartCameraSession(result: @escaping FlutterResult) {
            guard #available(iOS 11.3, *), let enhancedCamera = enhancedCameraSensor else {
                result(
                    FlutterError(
                        code: "UNAVAILABLE", message: "Enhanced camera not available", details: nil)
                )
                return
            }

            enhancedCamera.startSession { success, error in
                if success {
                    result(true)
                } else {
                    result(
                        FlutterError(
                            code: "SESSION_FAILED", message: error ?? "Unknown error", details: nil)
                    )
                }
            }
        }

        private func handleStopCameraSession(result: @escaping FlutterResult) {
            guard #available(iOS 11.3, *), let enhancedCamera = enhancedCameraSensor else {
                result(
                    FlutterError(
                        code: "UNAVAILABLE", message: "Enhanced camera not available", details: nil)
                )
                return
            }

            enhancedCamera.stopSession { success, error in
                if success {
                    result(true)
                } else {
                    result(
                        FlutterError(
                            code: "SESSION_FAILED", message: error ?? "Unknown error", details: nil)
                    )
                }
            }
        }

        private func handleCaptureEnhancedPhoto(
            call: FlutterMethodCall, result: @escaping FlutterResult
        ) {
            guard #available(iOS 11.3, *), let enhancedCamera = enhancedCameraSensor else {
                result(
                    FlutterError(
                        code: "UNAVAILABLE", message: "Enhanced camera not available", details: nil)
                )
                return
            }

            let settings = call.arguments as? [String: Any] ?? [:]

            enhancedCamera.capturePhoto(settings: settings) { success, photoData in
                if success {
                    result(photoData)
                } else {
                    result(
                        FlutterError(
                            code: "CAPTURE_FAILED", message: "Failed to capture photo",
                            details: photoData))
                }
            }
        }

        private func handleGetEnhancedCameraCapabilities(result: @escaping FlutterResult) {
            guard #available(iOS 11.3, *), let enhancedCamera = enhancedCameraSensor else {
                result(
                    FlutterError(
                        code: "UNAVAILABLE", message: "Enhanced camera not available", details: nil)
                )
                return
            }

            let capabilities = enhancedCamera.getCapabilities()
            result(capabilities)
        }

        private func handleMeasureCameraDistance(
            call: FlutterMethodCall, result: @escaping FlutterResult
        ) {
            guard #available(iOS 11.3, *), let enhancedCamera = enhancedCameraSensor else {
                result(
                    FlutterError(
                        code: "UNAVAILABLE", message: "Enhanced camera not available", details: nil)
                )
                return
            }

            guard let args = call.arguments as? [String: Any],
                let fromPointData = args["fromPoint"] as? [String: Double],
                let toPointData = args["toPoint"] as? [String: Double]
            else {
                result(
                    FlutterError(
                        code: "INVALID_ARGS",
                        message: "Invalid arguments for camera distance measurement", details: nil))
                return
            }

            let fromPoint = CGPoint(x: fromPointData["x"] ?? 0.0, y: fromPointData["y"] ?? 0.0)
            let toPoint = CGPoint(x: toPointData["x"] ?? 0.0, y: toPointData["y"] ?? 0.0)

            enhancedCamera.measureDepthDistance(fromPoint: fromPoint, toPoint: toPoint) {
                success, distanceData in
                if success {
                    result(distanceData)
                } else {
                    result(
                        FlutterError(
                            code: "MEASUREMENT_FAILED",
                            message: "Failed to measure camera distance",
                            details: distanceData))
                }
            }
        }
    }
#endif  // iOS
