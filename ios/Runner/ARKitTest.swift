//
//  ARKitTest.swift
//  Runner
//
//  ARKit Framework Integration Test
//  Verifies that ARKit is properly linked and available
//

import Foundation

#if os(iOS)
    import ARKit

    @available(iOS 13.0, *)
    class ARKitTest {

        /// Test if ARKit is available on this device
        static func isARKitAvailable() -> Bool {
            #if canImport(ARKit)
                return ARWorldTrackingConfiguration.isSupported
            #else
                return false
            #endif
        }

        /// Test if LiDAR is available (iOS 14+)
        static func isLiDARAvailable() -> Bool {
            #if canImport(ARKit)
                if #available(iOS 14.0, *) {
                    return ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
                } else {
                    return false
                }
            #else
                return false
            #endif
        }

        /// Get device AR capabilities
        static func getARCapabilities() -> [String: Bool] {
            return [
                "worldTracking": ARWorldTrackingConfiguration.isSupported,
                "bodyTracking": ARBodyTrackingConfiguration.isSupported,
                "faceTracking": ARFaceTrackingConfiguration.isSupported,
                "imageTracking": ARImageTrackingConfiguration.isSupported,
                "objectScanning": ARObjectScanningConfiguration.isSupported,
                "sceneReconstruction": isLiDARAvailable(),
            ]
        }
    }
#endif
