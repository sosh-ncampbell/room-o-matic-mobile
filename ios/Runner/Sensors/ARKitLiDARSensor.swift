#if os(iOS)
    #if canImport(ARKit)
        import ARKit
    #endif
    #if canImport(Flutter)
        import Flutter
    #endif
    import CoreLocation
    import Foundation

    /// Advanced ARKit-based LiDAR sensor implementation for iOS
    /// Provides high-precision distance measurements and 3D point cloud generation
    #if canImport(ARKit)
        @available(iOS 14.0, *)
        class ARKitLiDARSensor: NSObject {

            // MARK: - Properties

            private let methodChannel: FlutterMethodChannel
            private var arSession: ARSession?
            private var arSessionConfig: ARWorldTrackingConfiguration?
            private var isSessionRunning = false

            // Data collection
            private var pointCloudBuffer: [ARPointCloud] = []
            private var meshAnchors: [ARMeshAnchor] = []
            private let maxPointCloudBuffer = 100

            // Device capabilities
            private var supportsLiDAR: Bool {
                return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            }

            // MARK: - Initialization

            init(methodChannel: FlutterMethodChannel) {
                self.methodChannel = methodChannel
                super.init()
                setupARSession()
            }

            // MARK: - Public Methods

            /// Check if device supports LiDAR scanning
            func checkLiDARCapabilities() -> [String: Any] {
                let capabilities = [
                    "hasLiDAR": supportsLiDAR,
                    "supportsSceneReconstruction":
                        ARWorldTrackingConfiguration.supportsSceneReconstruction(
                            .mesh),
                    "supportsDepthData": ARWorldTrackingConfiguration.supportsFrameSemantics(
                        .sceneDepth),
                    "deviceModel": getDeviceModel(),
                ]

                return capabilities
            }

            /// Start LiDAR scanning session
            func startLiDARSession() -> Bool {
                guard supportsLiDAR else {
                    sendError("Device does not support LiDAR", code: "UNSUPPORTED_DEVICE")
                    return false
                }

                guard let config = arSessionConfig else {
                    sendError("Failed to configure AR session", code: "CONFIG_ERROR")
                    return false
                }

                arSession?.run(config)
                isSessionRunning = true

                // Notify Flutter of successful start
                methodChannel.invokeMethod(
                    "onLiDARSessionStarted",
                    arguments: [
                        "status": "started",
                        "timestamp": Date().timeIntervalSince1970,
                    ])

                return true
            }

            /// Stop LiDAR scanning session
            func stopLiDARSession() {
                arSession?.pause()
                isSessionRunning = false
                pointCloudBuffer.removeAll()
                meshAnchors.removeAll()

                // Notify Flutter of session stop
                methodChannel.invokeMethod(
                    "onLiDARSessionStopped",
                    arguments: [
                        "status": "stopped",
                        "timestamp": Date().timeIntervalSince1970,
                    ])
            }

            /// Get current point cloud data
            func getCurrentPointCloud() -> [String: Any] {
                guard let frame = arSession?.currentFrame else {
                    return ["error": "No current AR frame available"]
                }

                let pointCloud = extractPointCloudFromFrame(frame)
                return [
                    "pointCount": pointCloud.count,
                    "points": pointCloud,
                    "timestamp": Date().timeIntervalSince1970,
                    "confidence": calculatePointCloudConfidence(pointCloud),
                ]
            }

            /// Perform distance measurement between two points
            func measureDistance(from startPoint: [Float], to endPoint: [Float]) -> [String: Any] {
                let start = SIMD3<Float>(startPoint[0], startPoint[1], startPoint[2])
                let end = SIMD3<Float>(endPoint[0], endPoint[1], endPoint[2])

                let distance = simd_distance(start, end)

                return [
                    "distance": distance,
                    "unit": "meters",
                    "accuracy": calculateMeasurementAccuracy(),
                    "timestamp": Date().timeIntervalSince1970,
                ]
            }

            // MARK: - Private Methods

            private func setupARSession() {
                arSession = ARSession()
                arSession?.delegate = self

                // Configure for LiDAR with scene reconstruction
                arSessionConfig = ARWorldTrackingConfiguration()
                arSessionConfig?.sceneReconstruction = .mesh
                arSessionConfig?.frameSemantics.insert(.sceneDepth)
                arSessionConfig?.planeDetection = [.horizontal, .vertical]

                // Enable environmental understanding
                if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
                    arSessionConfig?.frameSemantics.insert(.smoothedSceneDepth)
                }
            }

            private func extractPointCloudFromFrame(_ frame: ARFrame) -> [[String: Any]] {
                var points: [[String: Any]] = []

                // Extract from depth data if available
                if let depthData = frame.sceneDepth {
                    let depthMap = depthData.depthMap
                    let confidenceMap = depthData.confidenceMap

                    points.append(
                        contentsOf: processDepthMap(
                            depthMap, confidence: confidenceMap, camera: frame.camera))
                }

                // Extract from raw feature points
                if let rawPoints = frame.rawFeaturePoints {
                    for i in 0..<rawPoints.points.count {
                        let point = rawPoints.points[i]
                        points.append([
                            "x": point.x,
                            "y": point.y,
                            "z": point.z,
                            "identifier": rawPoints.identifiers[i],
                            "type": "feature",
                        ])
                    }
                }

                return points
            }

            private func processDepthMap(
                _ depthMap: CVPixelBuffer, confidence: CVPixelBuffer?, camera: ARCamera
            ) -> [[String: Any]] {
                var points: [[String: Any]] = []

                CVPixelBufferLockBaseAddress(depthMap, .readOnly)
                defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

                let width = CVPixelBufferGetWidth(depthMap)
                let height = CVPixelBufferGetHeight(depthMap)
                let depthPointer = unsafeBitCast(
                    CVPixelBufferGetBaseAddress(depthMap), to: UnsafeMutablePointer<Float32>.self)

                // Sample points across the depth map (subsample for performance)
                let sampleRate = 10
                for y in stride(from: 0, to: height, by: sampleRate) {
                    for x in stride(from: 0, to: width, by: sampleRate) {
                        let pixelIndex = y * width + x
                        let depth = depthPointer[pixelIndex]

                        // Skip invalid depth values
                        guard depth > 0 && depth < 100 else { continue }

                        // Convert 2D pixel to 3D world coordinates
                        let pixelCoords = CGPoint(x: x, y: y)
                        let worldPosition = camera.unprojectPoint(
                            pixelCoords, ontoPlaneWithTransform: matrix_identity_float4x4,
                            orientation: .portrait,
                            viewportSize: CGSize(width: width, height: height))

                        points.append([
                            "x": worldPosition.x,
                            "y": worldPosition.y,
                            "z": worldPosition.z,
                            "depth": depth,
                            "pixel_x": x,
                            "pixel_y": y,
                            "type": "depth",
                        ])
                    }
                }

                return points
            }

            private func calculatePointCloudConfidence(_ points: [[String: Any]]) -> Float {
                guard !points.isEmpty else { return 0.0 }

                // Calculate confidence based on point density and distribution
                let pointCount = Float(points.count)
                let baseConfidence = min(pointCount / 1000.0, 1.0)  // Normalize to 0-1

                return baseConfidence * 0.95  // LiDAR generally has high confidence
            }

            private func calculateMeasurementAccuracy() -> Float {
                // LiDAR accuracy is typically ±1-2cm
                return 0.02  // 2cm accuracy
            }

            private func getDeviceModel() -> String {
                var systemInfo = utsname()
                uname(&systemInfo)
                let modelCode = withUnsafePointer(to: &systemInfo.machine) {
                    $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                        ptr in String.init(validatingUTF8: ptr)
                    }
                }
                return modelCode ?? "Unknown"
            }

            private func sendError(_ message: String, code: String) {
                methodChannel.invokeMethod(
                    "onLiDARError",
                    arguments: [
                        "error": message,
                        "code": code,
                        "timestamp": Date().timeIntervalSince1970,
                    ])
            }
        }

        // MARK: - ARSessionDelegate

        @available(iOS 14.0, *)
        extension ARKitLiDARSensor: ARSessionDelegate {

            func session(_ session: ARSession, didUpdate frame: ARFrame) {
                // Process frame data and send to Flutter
                guard isSessionRunning else { return }

                let frameData = [
                    "timestamp": Date().timeIntervalSince1970,
                    "camera_transform": formatMatrix(frame.camera.transform),
                    "has_depth_data": frame.sceneDepth != nil,
                    "feature_point_count": frame.rawFeaturePoints?.points.count ?? 0,
                ]

                methodChannel.invokeMethod("onLiDARFrameUpdate", arguments: frameData)
            }

            func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
                for anchor in anchors {
                    if let meshAnchor = anchor as? ARMeshAnchor {
                        meshAnchors.append(meshAnchor)

                        let meshData = [
                            "anchor_id": anchor.identifier.uuidString,
                            "vertex_count": meshAnchor.geometry.vertices.count,
                            "face_count": meshAnchor.geometry.faces.count,
                            "timestamp": Date().timeIntervalSince1970,
                        ]

                        methodChannel.invokeMethod("onMeshAnchorAdded", arguments: meshData)
                    }
                }
            }

            func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
                for anchor in anchors {
                    if let meshAnchor = anchor as? ARMeshAnchor {
                        // Update existing mesh anchor
                        if let index = meshAnchors.firstIndex(where: {
                            $0.identifier == meshAnchor.identifier
                        }) {
                            meshAnchors[index] = meshAnchor
                        }

                        let updateData = [
                            "anchor_id": anchor.identifier.uuidString,
                            "updated_at": Date().timeIntervalSince1970,
                        ]

                        methodChannel.invokeMethod("onMeshAnchorUpdated", arguments: updateData)
                    }
                }
            }

            func session(_ session: ARSession, didFailWithError error: Error) {
                sendError("AR Session failed: \(error.localizedDescription)", code: "SESSION_ERROR")
            }

            func sessionWasInterrupted(_ session: ARSession) {
                methodChannel.invokeMethod(
                    "onLiDARSessionInterrupted",
                    arguments: [
                        "reason": "session_interrupted",
                        "timestamp": Date().timeIntervalSince1970,
                    ])
            }

            func sessionInterruptionEnded(_ session: ARSession) {
                methodChannel.invokeMethod(
                    "onLiDARSessionResumed",
                    arguments: [
                        "reason": "interruption_ended",
                        "timestamp": Date().timeIntervalSince1970,
                    ])
            }

            private func formatMatrix(_ matrix: matrix_float4x4) -> [[Float]] {
                return [
                    [
                        matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z,
                        matrix.columns.0.w,
                    ],
                    [
                        matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z,
                        matrix.columns.1.w,
                    ],
                    [
                        matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z,
                        matrix.columns.2.w,
                    ],
                    [
                        matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z,
                        matrix.columns.3.w,
                    ],
                ]
            }
        }
    #else
        // Fallback implementation when ARKit is not available
        @available(iOS 14.0, *)
        class ARKitLiDARSensor: NSObject {
            #if canImport(Flutter)
                private let methodChannel: FlutterMethodChannel

                init(methodChannel: FlutterMethodChannel) {
                    self.methodChannel = methodChannel
                    super.init()
                }
            #else
                init(methodChannel: Any) {
                    super.init()
                }
            #endif

            func checkLiDARCapabilities() -> [String: Any] {
                return [
                    "hasLiDAR": false,
                    "supportsSceneReconstruction": false,
                    "supportsDepthData": false,
                    "deviceModel": "Simulator",
                    "error": "ARKit not available on this platform",
                ]
            }

            func startLiDARSession() -> Bool {
                #if canImport(Flutter)
                    methodChannel.invokeMethod(
                        "onLiDARError",
                        arguments: [
                            "error": "ARKit not available on this platform"
                        ])
                #endif
                return false
            }

            func stopLiDARSession() -> Bool {
                return true
            }

            func getCurrentPointCloud() -> [String: Any] {
                return [
                    "pointCloud": [],
                    "timestamp": Date().timeIntervalSince1970,
                    "error": "ARKit not available on this platform",
                ]
            }

            func measureDistance(from: [Double], to: [Double]) -> [String: Any] {
                return [
                    "distance": 0.0,
                    "confidence": 0.0,
                    "error": "ARKit not available on this platform",
                ]
            }
        }
    #endif
#endif  // iOS
