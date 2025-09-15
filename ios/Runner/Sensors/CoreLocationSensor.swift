#if os(iOS)
    import CoreLocation
    #if canImport(Flutter)
        import Flutter
    #endif
    import Foundation

    /// Core Location sensor for precise GPS and indoor positioning
    @available(iOS 11.0, *)
    public class CoreLocationSensor: NSObject {
        private let locationManager: CLLocationManager
        private let methodChannel: FlutterMethodChannel
        private var isLocationActive = false
        private var currentLocation: CLLocation?
        private var currentHeading: CLHeading?

        public init(methodChannel: FlutterMethodChannel) {
            self.methodChannel = methodChannel
            self.locationManager = CLLocationManager()
            super.init()
            setupLocationManager()
        }

        private func setupLocationManager() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 0.5  // Update every 0.5 meters

            // Indoor positioning settings
            if #available(iOS 13.4, *) {
                locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            }
        }

        // MARK: - Public Methods

        public func checkLocationCapabilities() -> [String: Any] {
            var capabilities: [String: Any] = [
                "locationServicesEnabled": CLLocationManager.locationServicesEnabled(),
                "authorizationStatus": authorizationStatusString(),
                "accuracyAuthorization": accuracyAuthorizationString(),
                "isHeadingAvailable": CLLocationManager.headingAvailable(),
                "supportsPreciseLocation": true,
                "supportsIndoorPositioning": false,
            ]

            // Check for indoor positioning support
            if #available(iOS 13.4, *) {
                capabilities["supportsIndoorPositioning"] = true
            }

            // Check for significant location monitoring
            capabilities["supportsSignificantLocationChanges"] =
                CLLocationManager.significantLocationChangeMonitoringAvailable()

            return capabilities
        }

        public func requestLocationPermission() -> Bool {
            guard CLLocationManager.locationServicesEnabled() else {
                return false
            }

            switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
                return true
            case .denied, .restricted:
                return false
            case .authorizedWhenInUse, .authorizedAlways:
                return true
            @unknown default:
                return false
            }
        }

        public func startLocationTracking() -> Bool {
            guard CLLocationManager.locationServicesEnabled() else {
                return false
            }

            #if os(iOS)
                guard
                    locationManager.authorizationStatus == .authorizedWhenInUse
                        || locationManager.authorizationStatus == .authorizedAlways
                else {
                    return false
                }
            #else
                guard locationManager.authorizationStatus == .authorizedAlways else {
                    return false
                }
            #endif

            isLocationActive = true
            locationManager.startUpdatingLocation()

            // Start heading updates if available (iOS only)
            #if os(iOS)
                if CLLocationManager.headingAvailable() {
                    locationManager.startUpdatingHeading()
                }
            #endif

            return true
        }

        public func stopLocationTracking() {
            isLocationActive = false
            locationManager.stopUpdatingLocation()

            #if os(iOS)
                locationManager.stopUpdatingHeading()
            #endif
        }

        public func getCurrentLocation() -> [String: Any]? {
            guard let location = currentLocation else { return nil }

            var locationData: [String: Any] = [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "altitude": location.altitude,
                "horizontalAccuracy": location.horizontalAccuracy,
                "verticalAccuracy": location.verticalAccuracy,
                "timestamp": location.timestamp.timeIntervalSince1970 * 1000,
                "speed": location.speed,
                "course": location.course,
                "floor": location.floor?.level ?? NSNotFound,
            ]

            // Add heading information if available
            if let heading = currentHeading {
                locationData["heading"] = [
                    "magneticHeading": heading.magneticHeading,
                    "trueHeading": heading.trueHeading,
                    "headingAccuracy": heading.headingAccuracy,
                    "timestamp": heading.timestamp.timeIntervalSince1970 * 1000,
                ]
            }

            return locationData
        }

        public func measureDistance(to targetLocation: [String: Double]) -> [String: Any]? {
            guard let currentLoc = currentLocation,
                let targetLat = targetLocation["latitude"],
                let targetLon = targetLocation["longitude"]
            else {
                return nil
            }

            let targetCLLocation = CLLocation(
                latitude: targetLat,
                longitude: targetLon
            )

            let distance = currentLoc.distance(from: targetCLLocation)
            let bearing = currentLoc.bearing(to: targetCLLocation)

            return [
                "distance": distance,
                "bearing": bearing,
                "accuracy": currentLoc.horizontalAccuracy,
                "method": "GPS",
            ]
        }

        // MARK: - Private Helpers

        private func authorizationStatusString() -> String {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                return "notDetermined"
            case .restricted:
                return "restricted"
            case .denied:
                return "denied"
            case .authorizedAlways:
                return "authorizedAlways"
            #if os(iOS)
                case .authorizedWhenInUse:
                    return "authorizedWhenInUse"
            #endif
            @unknown default:
                return "unknown"
            }
        }

        private func accuracyAuthorizationString() -> String {
            if #available(iOS 14.0, *) {
                switch locationManager.accuracyAuthorization {
                case .fullAccuracy:
                    return "fullAccuracy"
                case .reducedAccuracy:
                    return "reducedAccuracy"
                @unknown default:
                    return "unknown"
                }
            }
            return "fullAccuracy"  // Pre-iOS 14 always had full accuracy
        }
    }

    // MARK: - CLLocationManagerDelegate

    @available(iOS 11.0, *)
    extension CoreLocationSensor: CLLocationManagerDelegate {
        public func locationManager(
            _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
        ) {
            guard let location = locations.last, isLocationActive else { return }

            currentLocation = location

            let locationData: [String: Any] = [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "altitude": location.altitude,
                "horizontalAccuracy": location.horizontalAccuracy,
                "verticalAccuracy": location.verticalAccuracy,
                "timestamp": location.timestamp.timeIntervalSince1970 * 1000,
                "speed": location.speed >= 0 ? location.speed : 0,
                "course": location.course >= 0 ? location.course : 0,
                "floor": location.floor?.level ?? NSNotFound,
            ]

            methodChannel.invokeMethod("onLocationUpdate", arguments: locationData)
        }

        public func locationManager(
            _ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading
        ) {
            guard isLocationActive else { return }

            currentHeading = newHeading

            let headingData: [String: Any] = [
                "magneticHeading": newHeading.magneticHeading,
                "trueHeading": newHeading.trueHeading,
                "headingAccuracy": newHeading.headingAccuracy,
                "timestamp": newHeading.timestamp.timeIntervalSince1970 * 1000,
                "x": newHeading.x,
                "y": newHeading.y,
                "z": newHeading.z,
            ]

            methodChannel.invokeMethod("onHeadingUpdate", arguments: headingData)
        }

        public func locationManager(
            _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
        ) {
            let authData: [String: Any] = [
                "authorizationStatus": authorizationStatusString(),
                "accuracyAuthorization": accuracyAuthorizationString(),
                "locationServicesEnabled": CLLocationManager.locationServicesEnabled(),
            ]

            methodChannel.invokeMethod("onLocationAuthorizationChanged", arguments: authData)
        }

        public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            let errorData: [String: Any] = [
                "error": error.localizedDescription,
                "code": (error as NSError).code,
            ]

            methodChannel.invokeMethod("onLocationError", arguments: errorData)
        }
    }

    // MARK: - CLLocation Extensions

    extension CLLocation {
        func bearing(to location: CLLocation) -> Double {
            let lat1 = self.coordinate.latitude.degreesToRadians
            let lon1 = self.coordinate.longitude.degreesToRadians
            let lat2 = location.coordinate.latitude.degreesToRadians
            let lon2 = location.coordinate.longitude.degreesToRadians

            let dLon = lon2 - lon1

            let y = sin(dLon) * cos(lat2)
            let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

            let radiansBearing = atan2(y, x)
            return radiansBearing.radiansToDegrees.normalizedBearing
        }
    }

    extension Double {
        var degreesToRadians: Double { self * .pi / 180.0 }
        var radiansToDegrees: Double { self * 180.0 / .pi }
        var normalizedBearing: Double {
            return self < 0 ? self + 360 : self
        }
    }
#endif  // iOS
