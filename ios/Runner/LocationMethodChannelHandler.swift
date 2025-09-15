import CoreLocation
import CoreMotion
import Flutter
import UIKit

/// Flutter method channel handler for location services
/// Bridges Flutter location repository with iOS LocationService
class LocationMethodChannelHandler: NSObject, FlutterPlugin, FlutterStreamHandler {

    private static let channelName = "com.roomomatic.location"
    private static let streamChannelName = "com.roomomatic.location/stream"
    private static let indoorStreamChannelName = "com.roomomatic.location/indoor_stream"

    private var locationService: LocationService
    private var locationEventSink: FlutterEventSink?
    private var indoorLocationEventSink: FlutterEventSink?

    override init() {
        self.locationService = LocationService()
        super.init()
    }

    // MARK: - FlutterPlugin

    static func register(with registrar: FlutterPluginRegistrar) {
        let handler = LocationMethodChannelHandler()

        // Main method channel
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(handler, channel: channel)

        // Location stream channel
        let streamChannel = FlutterEventChannel(
            name: streamChannelName,
            binaryMessenger: registrar.messenger()
        )
        streamChannel.setStreamHandler(handler)

        // Indoor location stream channel
        let indoorStreamChannel = FlutterEventChannel(
            name: indoorStreamChannelName,
            binaryMessenger: registrar.messenger()
        )
        streamChannel.setStreamHandler(handler)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCurrentLocation":
            getCurrentLocation(result: result)

        case "getIndoorLocation":
            getIndoorLocation(result: result)

        case "getServiceStatus":
            getServiceStatus(result: result)

        case "requestPermissions":
            requestPermissions(result: result)

        case "getCapabilities":
            getCapabilities(result: result)

        case "configure":
            configure(arguments: call.arguments, result: result)

        case "getConfiguration":
            getConfiguration(result: result)

        case "resolveAddress":
            resolveAddress(arguments: call.arguments, result: result)

        case "getCoordinatesFromAddress":
            getCoordinatesFromAddress(arguments: call.arguments, result: result)

        case "startBackgroundTracking":
            startBackgroundTracking(result: result)

        case "stopBackgroundTracking":
            stopBackgroundTracking(result: result)

        case "getLocationHistory":
            getLocationHistory(arguments: call.arguments, result: result)

        case "clearCache":
            clearCache(result: result)

        case "getNearbyBeacons":
            getNearbyBeacons(result: result)

        case "calibrateIndoorPositioning":
            calibrateIndoorPositioning(arguments: call.arguments, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        // Determine which stream this is for
        if Thread.current.isMainThread {
            self.locationEventSink = events
            startLocationStream()
        } else {
            self.indoorLocationEventSink = events
            startIndoorLocationStream()
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.locationEventSink = nil
        self.indoorLocationEventSink = nil
        locationService.stopLocationUpdates()
        return nil
    }

    // MARK: - Method Implementations

    private func getCurrentLocation(result: @escaping FlutterResult) {
        locationService.getCurrentLocation { [weak self] locationResult in
            switch locationResult {
            case .success(let locationData):
                let locationDict = self?.locationDataToDict(locationData)
                result(locationDict)
            case .failure(let error):
                self?.handleLocationError(error, result: result)
            }
        }
    }

    private func getIndoorLocation(result: @escaping FlutterResult) {
        locationService.getIndoorLocation { [weak self] indoorResult in
            switch indoorResult {
            case .success(let indoorLocationData):
                let indoorDict = self?.indoorLocationDataToDict(indoorLocationData)
                result(indoorDict)
            case .failure(let error):
                if error.code == .indoorPositioningUnavailable {
                    result(nil)  // Indoor positioning not available
                } else {
                    self?.handleLocationError(error, result: result)
                }
            }
        }
    }

    private func getServiceStatus(result: @escaping FlutterResult) {
        let status = locationService.getServiceStatus()
        result(status.rawValue)
    }

    private func requestPermissions(result: @escaping FlutterResult) {
        locationService.requestPermissions { permissionStatus in
            result(permissionStatus.rawValue)
        }
    }

    private func getCapabilities(result: @escaping FlutterResult) {
        let capabilities = locationService.getCapabilities()
        result(capabilitiesToDict(capabilities))
    }

    private func configure(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
            let configuration = dictToLocationConfiguration(args)
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid configuration arguments",
                    details: nil
                ))
            return
        }

        locationService.configure(configuration) { configResult in
            switch configResult {
            case .success:
                result(nil)
            case .failure(let error):
                result(
                    FlutterError(
                        code: error.code.rawValue,
                        message: error.localizedDescription,
                        details: nil
                    ))
            }
        }
    }

    private func getConfiguration(result: @escaping FlutterResult) {
        let configuration = locationService.getConfiguration()
        result(locationConfigurationToDict(configuration))
    }

    private func resolveAddress(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
            let latitude = args["latitude"] as? Double,
            let longitude = args["longitude"] as? Double
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid latitude/longitude arguments",
                    details: nil
                ))
            return
        }

        locationService.resolveAddress(latitude: latitude, longitude: longitude) { address in
            result(address)
        }
    }

    private func getCoordinatesFromAddress(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
            let address = args["address"] as? String
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid address argument",
                    details: nil
                ))
            return
        }

        locationService.getCoordinatesFromAddress(address) { [weak self] coordinateResult in
            switch coordinateResult {
            case .success(let locationData):
                let locationDict = self?.locationDataToDict(locationData)
                result(locationDict)
            case .failure:
                result(nil)  // Geocoding failed
            }
        }
    }

    private func startBackgroundTracking(result: @escaping FlutterResult) {
        locationService.startBackgroundTracking { backgroundResult in
            switch backgroundResult {
            case .success:
                result(nil)
            case .failure(let error):
                result(
                    FlutterError(
                        code: error.code.rawValue,
                        message: error.localizedDescription,
                        details: nil
                    ))
            }
        }
    }

    private func stopBackgroundTracking(result: @escaping FlutterResult) {
        locationService.stopBackgroundTracking()
        result(nil)
    }

    private func getLocationHistory(arguments: Any?, result: @escaping FlutterResult) {
        let args = arguments as? [String: Any] ?? [:]

        var startTime: Date?
        var endTime: Date?
        var limit: Int?

        if let startTimeMs = args["startTime"] as? Int64 {
            startTime = Date(timeIntervalSince1970: TimeInterval(startTimeMs) / 1000.0)
        }

        if let endTimeMs = args["endTime"] as? Int64 {
            endTime = Date(timeIntervalSince1970: TimeInterval(endTimeMs) / 1000.0)
        }

        if let limitValue = args["limit"] as? Int {
            limit = limitValue
        }

        locationService.getLocationHistory(
            startTime: startTime,
            endTime: endTime,
            limit: limit
        ) { [weak self] historyResult in
            switch historyResult {
            case .success(let locations):
                let locationDicts = locations.compactMap { self?.locationDataToDict($0) }
                result(locationDicts)
            case .failure:
                result([])  // Return empty array on failure
            }
        }
    }

    private func clearCache(result: @escaping FlutterResult) {
        locationService.clearCache()
        result(nil)
    }

    private func getNearbyBeacons(result: @escaping FlutterResult) {
        locationService.getNearbyBeacons { [weak self] beaconsResult in
            switch beaconsResult {
            case .success(let beacons):
                let beaconDicts = beacons.map { self?.beaconDataToDict($0) ?? [:] }
                result(beaconDicts)
            case .failure:
                result([])  // Return empty array on failure
            }
        }
    }

    private func calibrateIndoorPositioning(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
            let calibrationData = dictToCalibrationData(args)
        else {
            result(
                FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid calibration arguments",
                    details: nil
                ))
            return
        }

        locationService.calibrateIndoorPositioning(calibrationData) { calibrationResult in
            switch calibrationResult {
            case .success:
                result(nil)
            case .failure(let error):
                result(
                    FlutterError(
                        code: error.code.rawValue,
                        message: error.localizedDescription,
                        details: nil
                    ))
            }
        }
    }

    // MARK: - Stream Management

    private func startLocationStream() {
        locationService.startLocationUpdates { [weak self] locationResult in
            guard let self = self else { return }

            switch locationResult {
            case .success(let locationData):
                let locationDict = self.locationDataToDict(locationData)
                self.locationEventSink?(locationDict)
            case .failure(let error):
                self.locationEventSink?(
                    FlutterError(
                        code: error.code.rawValue,
                        message: error.localizedDescription,
                        details: nil
                    ))
            }
        }
    }

    private func startIndoorLocationStream() {
        locationService.startIndoorLocationUpdates { [weak self] indoorResult in
            guard let self = self else { return }

            switch indoorResult {
            case .success(let indoorLocationData):
                let indoorDict = self.indoorLocationDataToDict(indoorLocationData)
                self.indoorLocationEventSink?(indoorDict)
            case .failure(let error):
                self.indoorLocationEventSink?(
                    FlutterError(
                        code: error.code.rawValue,
                        message: error.localizedDescription,
                        details: nil
                    ))
            }
        }
    }

    // MARK: - Data Conversion Methods

    private func locationDataToDict(_ locationData: LocationData) -> [String: Any] {
        var dict: [String: Any] = [
            "latitude": locationData.latitude,
            "longitude": locationData.longitude,
            "accuracy": locationData.accuracy,
            "timestamp": Int64(locationData.timestamp.timeIntervalSince1970 * 1000),
            "isIndoor": locationData.isIndoor,
            "source": locationData.source.rawValue,
        ]

        if let altitude = locationData.altitude {
            dict["altitude"] = altitude
        }

        if let altitudeAccuracy = locationData.altitudeAccuracy {
            dict["altitudeAccuracy"] = altitudeAccuracy
        }

        if let heading = locationData.heading {
            dict["heading"] = heading
        }

        if let speed = locationData.speed {
            dict["speed"] = speed
        }

        if let speedAccuracy = locationData.speedAccuracy {
            dict["speedAccuracy"] = speedAccuracy
        }

        if let address = locationData.address {
            dict["address"] = address
        }

        if let metadata = locationData.metadata {
            dict["metadata"] = metadata
        }

        return dict
    }

    private func indoorLocationDataToDict(_ indoorLocationData: IndoorLocationData) -> [String: Any]
    {
        var dict: [String: Any] = [
            "baseLocation": locationDataToDict(indoorLocationData.baseLocation),
            "method": indoorLocationData.method.rawValue,
        ]

        if let buildingId = indoorLocationData.buildingId {
            dict["buildingId"] = buildingId
        }

        if let floorLevel = indoorLocationData.floorLevel {
            dict["floorLevel"] = floorLevel
        }

        if let roomId = indoorLocationData.roomId {
            dict["roomId"] = roomId
        }

        if let relativeX = indoorLocationData.relativeX {
            dict["relativeX"] = relativeX
        }

        if let relativeY = indoorLocationData.relativeY {
            dict["relativeY"] = relativeY
        }

        if let relativeZ = indoorLocationData.relativeZ {
            dict["relativeZ"] = relativeZ
        }

        if let beaconId = indoorLocationData.beaconId {
            dict["beaconId"] = beaconId
        }

        if let beaconDistance = indoorLocationData.beaconDistance {
            dict["beaconDistance"] = beaconDistance
        }

        if let additionalData = indoorLocationData.additionalData {
            dict["additionalData"] = additionalData
        }

        return dict
    }

    private func capabilitiesToDict(_ capabilities: LocationCapabilities) -> [String: Any] {
        return [
            "hasGPS": capabilities.hasGPS,
            "hasNetwork": capabilities.hasNetwork,
            "hasPassive": capabilities.hasPassive,
            "hasIndoorPositioning": capabilities.hasIndoorPositioning,
            "hasCompass": capabilities.hasCompass,
            "hasAltimeter": capabilities.hasAltimeter,
            "supportsFusedProvider": capabilities.supportsFusedProvider,
            "supportsBackgroundLocation": capabilities.supportsBackgroundLocation,
            "maxAccuracy": capabilities.maxAccuracy.rawValue,
            "supportedIndoorMethods": capabilities.supportedIndoorMethods.map { $0.rawValue },
        ]
    }

    private func locationConfigurationToDict(_ configuration: LocationConfiguration) -> [String:
        Any]
    {
        return [
            "enableGPS": configuration.enableGPS,
            "enableIndoorPositioning": configuration.enableIndoorPositioning,
            "desiredAccuracy": configuration.desiredAccuracy.rawValue,
            "updateInterval": Int(configuration.updateInterval * 1000),  // Convert to milliseconds
            "minimumAccuracy": configuration.minimumAccuracy,
            "maxAge": Int(configuration.maxAge * 1000),  // Convert to milliseconds
            "enableBackgroundLocation": configuration.enableBackgroundLocation,
            "enableAddressResolution": configuration.enableAddressResolution,
        ]
    }

    private func beaconDataToDict(_ beaconData: BeaconData) -> [String: Any] {
        return [
            "id": beaconData.id,
            "uuid": beaconData.uuid,
            "major": beaconData.major,
            "minor": beaconData.minor,
            "distance": beaconData.distance,
            "rssi": beaconData.rssi,
            "detectedAt": Int64(beaconData.detectedAt.timeIntervalSince1970 * 1000),
            "metadata": beaconData.metadata,
        ]
    }

    // MARK: - Parsing Methods

    private func dictToLocationConfiguration(_ dict: [String: Any]) -> LocationConfiguration? {
        let enableGPS = dict["enableGPS"] as? Bool ?? true
        let enableIndoorPositioning = dict["enableIndoorPositioning"] as? Bool ?? true
        let enableBackgroundLocation = dict["enableBackgroundLocation"] as? Bool ?? true
        let enableAddressResolution = dict["enableAddressResolution"] as? Bool ?? true
        let minimumAccuracy = dict["minimumAccuracy"] as? Double ?? 10.0

        var desiredAccuracy = LocationAccuracy.high
        if let accuracyString = dict["desiredAccuracy"] as? String {
            desiredAccuracy = LocationAccuracy(rawValue: accuracyString) ?? .high
        }

        var updateInterval: TimeInterval = 30.0
        if let intervalMs = dict["updateInterval"] as? Int {
            updateInterval = TimeInterval(intervalMs) / 1000.0
        }

        var maxAge: TimeInterval = 300.0
        if let maxAgeMs = dict["maxAge"] as? Int {
            maxAge = TimeInterval(maxAgeMs) / 1000.0
        }

        return LocationConfiguration(
            enableGPS: enableGPS,
            enableIndoorPositioning: enableIndoorPositioning,
            desiredAccuracy: desiredAccuracy,
            updateInterval: updateInterval,
            minimumAccuracy: minimumAccuracy,
            maxAge: maxAge,
            enableBackgroundLocation: enableBackgroundLocation,
            enableAddressResolution: enableAddressResolution
        )
    }

    private func dictToCalibrationData(_ dict: [String: Any]) -> CalibrationData? {
        guard let knownLocationDict = dict["knownLocation"] as? [String: Any],
            let lat = knownLocationDict["latitude"] as? Double,
            let lon = knownLocationDict["longitude"] as? Double,
            let accuracy = knownLocationDict["accuracy"] as? Double,
            let timestampMs = knownLocationDict["timestamp"] as? Int64
        else {
            return nil
        }

        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0)
        let knownLocation = LocationData(
            latitude: lat,
            longitude: lon,
            accuracy: accuracy,
            timestamp: timestamp,
            altitude: nil,
            altitudeAccuracy: nil,
            heading: nil,
            speed: nil,
            speedAccuracy: nil,
            address: nil,
            isIndoor: false,
            source: .manual,
            metadata: nil
        )

        var beacons: [BeaconData] = []
        if let beaconsArray = dict["beacons"] as? [[String: Any]] {
            beacons = beaconsArray.compactMap { beaconDict in
                guard let id = beaconDict["id"] as? String,
                    let uuid = beaconDict["uuid"] as? String,
                    let major = beaconDict["major"] as? Int,
                    let minor = beaconDict["minor"] as? Int,
                    let distance = beaconDict["distance"] as? Double,
                    let rssi = beaconDict["rssi"] as? Double,
                    let detectedAtMs = beaconDict["detectedAt"] as? Int64
                else {
                    return nil
                }

                let detectedAt = Date(timeIntervalSince1970: TimeInterval(detectedAtMs) / 1000.0)
                let metadata = beaconDict["metadata"] as? [String: Any] ?? [:]

                return BeaconData(
                    id: id,
                    uuid: uuid,
                    major: major,
                    minor: minor,
                    distance: distance,
                    rssi: rssi,
                    detectedAt: detectedAt,
                    metadata: metadata
                )
            }
        }

        let wifiSignals = dict["wifiSignals"] as? [String: Any] ?? [:]
        let environmentalData = dict["environmentalData"] as? [String: Any] ?? [:]

        var calibratedAt = Date()
        if let calibratedAtMs = dict["calibratedAt"] as? Int64 {
            calibratedAt = Date(timeIntervalSince1970: TimeInterval(calibratedAtMs) / 1000.0)
        }

        return CalibrationData(
            knownLocation: knownLocation,
            beacons: beacons,
            wifiSignals: wifiSignals,
            environmentalData: environmentalData,
            calibratedAt: calibratedAt
        )
    }

    // MARK: - Error Handling

    private func handleLocationError(_ error: LocationError, result: @escaping FlutterResult) {
        result(
            FlutterError(
                code: error.code.rawValue,
                message: error.localizedDescription,
                details: nil
            ))
    }
}
