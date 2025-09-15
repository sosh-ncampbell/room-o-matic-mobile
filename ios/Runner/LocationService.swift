import CoreLocation
import CoreMotion
import Foundation

/// iOS Core Location service for GPS and indoor positioning
/// Integrates with Flutter through platform channels
@objc(LocationService)
class LocationService: NSObject {
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private var channel: FlutterMethodChannel?
    private var locationStreamSink: FlutterEventSink?
    private var isMonitoring = false
    private var currentConfiguration: LocationConfiguration?

    // MARK: - Initialization

    override init() {
        super.init()
        setupLocationManager()
        setupMotionManager()
    }

    func setup(with channel: FlutterMethodChannel) {
        self.channel = channel
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1.0

        // Enable background location if needed
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            locationManager.allowsBackgroundLocationUpdates = false  // Will be enabled when needed
        }
    }

    private func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
        }
    }

    // MARK: - Public Methods

    @objc func getCurrentLocation(completion: @escaping (LocationData?, Error?) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(nil, LocationError.serviceDisabled)
            return
        }

        guard
            locationManager.authorizationStatus == .authorizedWhenInUse
                || locationManager.authorizationStatus == .authorizedAlways
        else {
            completion(nil, LocationError.permissionDenied)
            return
        }

        // Request one-time location
        locationManager.requestLocation()

        // Store completion for callback
        self.oneTimeLocationCompletion = completion
    }

    @objc func startLocationUpdates() -> Bool {
        guard CLLocationManager.locationServicesEnabled() else {
            return false
        }

        guard
            locationManager.authorizationStatus == .authorizedWhenInUse
                || locationManager.authorizationStatus == .authorizedAlways
        else {
            return false
        }

        locationManager.startUpdatingLocation()

        // Start indoor positioning if available
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            startBeaconMonitoring()
        }

        isMonitoring = true
        return true
    }

    @objc func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        stopBeaconMonitoring()
        isMonitoring = false
    }

    @objc func requestPermissions(completion: @escaping (LocationPermissionStatus) -> Void) {
        self.permissionCompletion = completion

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            completion(.denied)
        case .restricted:
            completion(.restricted)
        case .authorizedWhenInUse:
            completion(.granted)
        case .authorizedAlways:
            completion(.granted)
        @unknown default:
            completion(.unknown)
        }
    }

    @objc func getServiceStatus() -> LocationServiceStatus {
        if !CLLocationManager.locationServicesEnabled() {
            return .disabled
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            return .unknown
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .authorizedWhenInUse, .authorizedAlways:
            return .enabled
        @unknown default:
            return .unknown
        }
    }

    @objc func getCapabilities() -> LocationCapabilities {
        return LocationCapabilities(
            hasGPS: CLLocationManager.locationServicesEnabled(),
            hasNetwork: true,  // Always available on iOS
            hasPassive: true,
            hasIndoorPositioning: CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self),
            hasCompass: CLLocationManager.headingAvailable(),
            hasAltimeter: CMAltimeter.isRelativeAltitudeAvailable(),
            supportsFusedProvider: true,  // Core Location is fused by default
            supportsBackgroundLocation: Bundle.main.object(
                forInfoDictionaryKey: "UIBackgroundModes") != nil,
            maxAccuracy: .bestForNavigation,
            supportedIndoorMethods: getSupportedIndoorMethods()
        )
    }

    @objc func configure(with configuration: LocationConfiguration) {
        self.currentConfiguration = configuration

        // Apply accuracy settings
        locationManager.desiredAccuracy = configuration.desiredAccuracy.coreLocationAccuracy

        // Apply distance filter based on update interval
        let distanceFilter = max(1.0, configuration.updateInterval.timeInterval / 10.0)
        locationManager.distanceFilter = distanceFilter

        // Configure background location
        if configuration.enableBackgroundLocation {
            if locationManager.authorizationStatus == .authorizedAlways {
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.pausesLocationUpdatesAutomatically = false
            }
        } else {
            locationManager.allowsBackgroundLocationUpdates = false
            locationManager.pausesLocationUpdatesAutomatically = true
        }
    }

    @objc func resolveAddress(
        latitude: Double, longitude: Double, completion: @escaping (String?, Error?) -> Void
    ) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let placemark = placemarks?.first else {
                completion(nil, LocationError.addressResolutionFailed)
                return
            }

            let address = self.formatAddress(from: placemark)
            completion(address, nil)
        }
    }

    @objc func getCoordinatesFromAddress(
        _ address: String, completion: @escaping (LocationData?, Error?) -> Void
    ) {
        let geocoder = CLGeocoder()

        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let placemark = placemarks?.first,
                let location = placemark.location
            else {
                completion(nil, LocationError.addressResolutionFailed)
                return
            }

            let locationData = self.createLocationData(from: location)
            completion(locationData, nil)
        }
    }

    @objc func calculateDistance(from location1: LocationData, to location2: LocationData) -> Double
    {
        let clLocation1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
        let clLocation2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)

        return clLocation1.distance(from: clLocation2)
    }

    // MARK: - Indoor Positioning

    private func startBeaconMonitoring() {
        // This would be configured based on known beacons in the environment
        // For now, we'll use a generic iBeacon UUID
        let uuid = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0") ?? UUID()
        let beaconRegion = CLBeaconRegion(uuid: uuid, identifier: "RoomOMaticBeacon")

        beaconRegion.notifyOnEntry = true
        beaconRegion.notifyOnExit = true

        locationManager.startMonitoring(for: beaconRegion)
        locationManager.startRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: uuid))
    }

    private func stopBeaconMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        locationManager.stopRangingBeacons(satisfying: CLBeaconIdentityConstraint(uuid: UUID()))
    }

    // MARK: - Helper Methods

    private func createLocationData(from location: CLLocation) -> LocationData {
        return LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            timestamp: location.timestamp,
            altitude: location.altitude != -1 ? location.altitude : nil,
            altitudeAccuracy: location.verticalAccuracy != -1 ? location.verticalAccuracy : nil,
            heading: location.course != -1 ? location.course : nil,
            speed: location.speed != -1 ? location.speed : nil,
            speedAccuracy: nil,  // Not available in Core Location
            address: nil,  // Will be resolved separately
            isIndoor: false,
            source: .gps,
            metadata: [
                "floor": location.floor?.level ?? NSNull(),
                "timestamp": location.timestamp.timeIntervalSince1970,
            ]
        )
    }

    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []

        if let streetNumber = placemark.subThoroughfare {
            components.append(streetNumber)
        }

        if let streetName = placemark.thoroughfare {
            components.append(streetName)
        }

        if let locality = placemark.locality {
            components.append(locality)
        }

        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }

        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }

        if let country = placemark.country {
            components.append(country)
        }

        return components.joined(separator: ", ")
    }

    private func getSupportedIndoorMethods() -> [IndoorPositioningMethod] {
        var methods: [IndoorPositioningMethod] = []

        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
            methods.append(.beacon)
        }

        if motionManager.isDeviceMotionAvailable {
            methods.append(.fusion)
        }

        // Wi-Fi positioning is always available but not directly accessible
        methods.append(.wifi)

        return methods
    }

    // MARK: - Completion Handlers

    private var oneTimeLocationCompletion: ((LocationData?, Error?) -> Void)?
    private var permissionCompletion: ((LocationPermissionStatus) -> Void)?
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let locationData = createLocationData(from: location)

        // Handle one-time location request
        if let completion = oneTimeLocationCompletion {
            completion(locationData, nil)
            oneTimeLocationCompletion = nil
        }

        // Send to Flutter stream
        if let sink = locationStreamSink {
            sink(locationData.toDictionary())
        }

        // Send to Flutter channel
        channel?.invokeMethod("onLocationUpdate", arguments: locationData.toDictionary())
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationError: LocationError

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .permissionDenied
            case .locationUnknown:
                locationError = .locationUnavailable
            case .network:
                locationError = .networkError
            default:
                locationError = .unknown
            }
        } else {
            locationError = .unknown
        }

        // Handle one-time location request
        if let completion = oneTimeLocationCompletion {
            completion(nil, locationError)
            oneTimeLocationCompletion = nil
        }

        // Send error to Flutter
        channel?.invokeMethod(
            "onLocationError",
            arguments: [
                "code": locationError.code,
                "message": locationError.localizedDescription,
            ])
    }

    func locationManager(
        _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
    ) {
        let permissionStatus: LocationPermissionStatus

        switch status {
        case .notDetermined:
            return  // Don't call completion yet
        case .denied:
            permissionStatus = .denied
        case .restricted:
            permissionStatus = .restricted
        case .authorizedWhenInUse:
            permissionStatus = .granted
        case .authorizedAlways:
            permissionStatus = .granted
        @unknown default:
            permissionStatus = .unknown
        }

        // Handle permission request
        if let completion = permissionCompletion {
            completion(permissionStatus)
            permissionCompletion = nil
        }

        // Notify Flutter
        channel?.invokeMethod("onPermissionStatusChanged", arguments: permissionStatus.rawValue)
    }

    func locationManager(
        _ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion
    ) {
        let beaconData = beacons.map { beacon in
            return [
                "uuid": beacon.uuid.uuidString,
                "major": beacon.major.intValue,
                "minor": beacon.minor.intValue,
                "proximity": beacon.proximity.rawValue,
                "accuracy": beacon.accuracy,
                "rssi": beacon.rssi,
            ]
        }

        channel?.invokeMethod("onBeaconsDetected", arguments: beaconData)
    }
}

// MARK: - Supporting Types

enum LocationError: LocalizedError {
    case serviceDisabled
    case permissionDenied
    case locationUnavailable
    case timeout
    case networkError
    case addressResolutionFailed
    case unknown

    var code: String {
        switch self {
        case .serviceDisabled: return "SERVICE_DISABLED"
        case .permissionDenied: return "PERMISSION_DENIED"
        case .locationUnavailable: return "LOCATION_UNAVAILABLE"
        case .timeout: return "TIMEOUT"
        case .networkError: return "NETWORK_ERROR"
        case .addressResolutionFailed: return "ADDRESS_RESOLUTION_FAILED"
        case .unknown: return "UNKNOWN"
        }
    }

    var errorDescription: String? {
        switch self {
        case .serviceDisabled:
            return "Location services are disabled"
        case .permissionDenied:
            return "Location permission denied"
        case .locationUnavailable:
            return "Location unavailable"
        case .timeout:
            return "Location request timed out"
        case .networkError:
            return "Network error"
        case .addressResolutionFailed:
            return "Address resolution failed"
        case .unknown:
            return "Unknown location error"
        }
    }
}

enum LocationServiceStatus: String, CaseIterable {
    case enabled = "enabled"
    case disabled = "disabled"
    case restricted = "restricted"
    case denied = "denied"
    case unknown = "unknown"
}

enum LocationPermissionStatus: String, CaseIterable {
    case granted = "granted"
    case denied = "denied"
    case deniedForever = "deniedForever"
    case restricted = "restricted"
    case unknown = "unknown"
}

// MARK: - Extensions

extension LocationAccuracy {
    var coreLocationAccuracy: CLLocationAccuracy {
        switch self {
        case .lowest:
            return kCLLocationAccuracyThreeKilometers
        case .low:
            return kCLLocationAccuracyKilometer
        case .medium:
            return kCLLocationAccuracyHundredMeters
        case .high:
            return kCLLocationAccuracyNearestTenMeters
        case .best:
            return kCLLocationAccuracyBest
        case .bestForNavigation:
            return kCLLocationAccuracyBestForNavigation
        }
    }
}

extension LocationData {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "accuracy": accuracy,
            "timestamp": timestamp.timeIntervalSince1970,
            "isIndoor": isIndoor,
            "source": source.rawValue,
        ]

        if let altitude = altitude {
            dict["altitude"] = altitude
        }

        if let altitudeAccuracy = altitudeAccuracy {
            dict["altitudeAccuracy"] = altitudeAccuracy
        }

        if let heading = heading {
            dict["heading"] = heading
        }

        if let speed = speed {
            dict["speed"] = speed
        }

        if let speedAccuracy = speedAccuracy {
            dict["speedAccuracy"] = speedAccuracy
        }

        if let address = address {
            dict["address"] = address
        }

        if let metadata = metadata {
            dict["metadata"] = metadata
        }

        return dict
    }
}
