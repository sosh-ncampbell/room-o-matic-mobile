package com.roomomatic.mobile

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.util.*

/**
 * Flutter method channel handler for location services
 * Bridges Flutter location repository with Android location service
 */
class LocationMethodChannelHandler : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val CHANNEL_NAME = "com.roomomatic.location"
        private const val STREAM_CHANNEL_NAME = "com.roomomatic.location/stream"
        private const val INDOOR_STREAM_CHANNEL_NAME = "com.roomomatic.location/indoor_stream"
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var locationStreamChannel: EventChannel
    private lateinit var indoorLocationStreamChannel: EventChannel
    private lateinit var locationService: AndroidLocationService

    private var locationEventSink: EventChannel.EventSink? = null
    private var indoorLocationEventSink: EventChannel.EventSink? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // MARK: - FlutterPlugin

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        locationService = AndroidLocationService(context)

        // Setup method channel
        methodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            CHANNEL_NAME
        )
        methodChannel.setMethodCallHandler(this)

        // Setup location stream channel
        locationStreamChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            STREAM_CHANNEL_NAME
        )
        locationStreamChannel.setStreamHandler(this)

        // Setup indoor location stream channel
        indoorLocationStreamChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            INDOOR_STREAM_CHANNEL_NAME
        )
        indoorLocationStreamChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        locationStreamChannel.setStreamHandler(null)
        indoorLocationStreamChannel.setStreamHandler(null)
        coroutineScope.cancel()
    }

    // MARK: - MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getCurrentLocation" -> getCurrentLocation(result)
            "getIndoorLocation" -> getIndoorLocation(result)
            "getServiceStatus" -> getServiceStatus(result)
            "requestPermissions" -> requestPermissions(result)
            "getCapabilities" -> getCapabilities(result)
            "configure" -> configure(call.arguments, result)
            "getConfiguration" -> getConfiguration(result)
            "resolveAddress" -> resolveAddress(call.arguments, result)
            "getCoordinatesFromAddress" -> getCoordinatesFromAddress(call.arguments, result)
            "startBackgroundTracking" -> startBackgroundTracking(result)
            "stopBackgroundTracking" -> stopBackgroundTracking(result)
            "getLocationHistory" -> getLocationHistory(call.arguments, result)
            "clearCache" -> clearCache(result)
            "getNearbyBeacons" -> getNearbyBeacons(result)
            "calibrateIndoorPositioning" -> calibrateIndoorPositioning(call.arguments, result)
            else -> result.notImplemented()
        }
    }

    // MARK: - EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        // For simplicity, we'll use the first stream as location stream
        if (locationEventSink == null) {
            locationEventSink = events
            startLocationStream()
        } else {
            indoorLocationEventSink = events
            startIndoorLocationStream()
        }
    }

    override fun onCancel(arguments: Any?) {
        locationEventSink = null
        indoorLocationEventSink = null
        locationService.stopLocationUpdates()
    }

    // MARK: - Method Implementations

    private fun getCurrentLocation(result: Result) {
        coroutineScope.launch {
            try {
                val locationData = locationService.getCurrentLocation()
                if (locationData != null) {
                    result.success(locationDataToMap(locationData))
                } else {
                    result.success(null)
                }
            } catch (e: LocationException) {
                handleLocationError(e, result)
            } catch (e: Exception) {
                result.error("UNKNOWN_ERROR", e.message, null)
            }
        }
    }

    private fun getIndoorLocation(result: Result) {
        coroutineScope.launch {
            try {
                val indoorLocationData = locationService.getIndoorLocation()
                if (indoorLocationData != null) {
                    result.success(indoorLocationDataToMap(indoorLocationData))
                } else {
                    result.success(null)
                }
            } catch (e: LocationException) {
                if (e.code == LocationErrorCode.INDOOR_POSITIONING_UNAVAILABLE) {
                    result.success(null) // Indoor positioning not available
                } else {
                    handleLocationError(e, result)
                }
            } catch (e: Exception) {
                result.error("UNKNOWN_ERROR", e.message, null)
            }
        }
    }

    private fun getServiceStatus(result: Result) {
        val status = locationService.getServiceStatus()
        result.success(status.name.lowercase())
    }

    private fun requestPermissions(result: Result) {
        coroutineScope.launch {
            try {
                val permissionStatus = locationService.requestPermissions()
                result.success(permissionStatus.name.lowercase())
            } catch (e: LocationException) {
                handleLocationError(e, result)
            } catch (e: Exception) {
                result.error("PERMISSION_ERROR", e.message, null)
            }
        }
    }

    private fun getCapabilities(result: Result) {
        val capabilities = locationService.getCapabilities()
        result.success(capabilitiesToMap(capabilities))
    }

    private fun configure(arguments: Any?, result: Result) {
        try {
            val args = arguments as? Map<String, Any>
            val configuration = mapToLocationConfiguration(args ?: emptyMap())

            coroutineScope.launch {
                try {
                    locationService.configure(configuration)
                    result.success(null)
                } catch (e: LocationException) {
                    handleLocationError(e, result)
                } catch (e: Exception) {
                    result.error("CONFIGURATION_ERROR", e.message, null)
                }
            }
        } catch (e: Exception) {
            result.error("INVALID_ARGUMENTS", "Invalid configuration arguments", null)
        }
    }

    private fun getConfiguration(result: Result) {
        val configuration = locationService.getConfiguration()
        result.success(locationConfigurationToMap(configuration))
    }

    private fun resolveAddress(arguments: Any?, result: Result) {
        try {
            val args = arguments as? Map<String, Any>
            val latitude = args?.get("latitude") as? Double
            val longitude = args?.get("longitude") as? Double

            if (latitude == null || longitude == null) {
                result.error("INVALID_ARGUMENTS", "Invalid latitude/longitude arguments", null)
                return
            }

            coroutineScope.launch {
                try {
                    val address = locationService.resolveAddress(latitude, longitude)
                    result.success(address)
                } catch (e: Exception) {
                    result.success(null) // Address resolution failed
                }
            }
        } catch (e: Exception) {
            result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
        }
    }

    private fun getCoordinatesFromAddress(arguments: Any?, result: Result) {
        try {
            val args = arguments as? Map<String, Any>
            val address = args?.get("address") as? String

            if (address == null) {
                result.error("INVALID_ARGUMENTS", "Invalid address argument", null)
                return
            }

            coroutineScope.launch {
                try {
                    val locationData = locationService.getCoordinatesFromAddress(address)
                    if (locationData != null) {
                        result.success(locationDataToMap(locationData))
                    } else {
                        result.success(null)
                    }
                } catch (e: Exception) {
                    result.success(null) // Geocoding failed
                }
            }
        } catch (e: Exception) {
            result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
        }
    }

    private fun startBackgroundTracking(result: Result) {
        coroutineScope.launch {
            try {
                locationService.startBackgroundTracking()
                result.success(null)
            } catch (e: LocationException) {
                handleLocationError(e, result)
            } catch (e: Exception) {
                result.error("BACKGROUND_TRACKING_ERROR", e.message, null)
            }
        }
    }

    private fun stopBackgroundTracking(result: Result) {
        locationService.stopBackgroundTracking()
        result.success(null)
    }

    private fun getLocationHistory(arguments: Any?, result: Result) {
        coroutineScope.launch {
            try {
                val args = arguments as? Map<String, Any> ?: emptyMap()

                val startTime = (args["startTime"] as? Long)?.let { Date(it) }
                val endTime = (args["endTime"] as? Long)?.let { Date(it) }
                val limit = args["limit"] as? Int

                val locations = locationService.getLocationHistory(startTime, endTime, limit)
                val locationMaps = locations.map { locationDataToMap(it) }
                result.success(locationMaps)
            } catch (e: Exception) {
                result.success(emptyList<Any>()) // Return empty list on failure
            }
        }
    }

    private fun clearCache(result: Result) {
        locationService.clearCache()
        result.success(null)
    }

    private fun getNearbyBeacons(result: Result) {
        coroutineScope.launch {
            try {
                val beacons = locationService.getNearbyBeacons()
                val beaconMaps = beacons.map { beaconDataToMap(it) }
                result.success(beaconMaps)
            } catch (e: Exception) {
                result.success(emptyList<Any>()) // Return empty list on failure
            }
        }
    }

    private fun calibrateIndoorPositioning(arguments: Any?, result: Result) {
        try {
            val args = arguments as? Map<String, Any>
            val calibrationData = mapToCalibrationData(args ?: emptyMap())

            if (calibrationData == null) {
                result.error("INVALID_ARGUMENTS", "Invalid calibration arguments", null)
                return
            }

            coroutineScope.launch {
                try {
                    locationService.calibrateIndoorPositioning(calibrationData)
                    result.success(null)
                } catch (e: LocationException) {
                    handleLocationError(e, result)
                } catch (e: Exception) {
                    result.error("CALIBRATION_ERROR", e.message, null)
                }
            }
        } catch (e: Exception) {
            result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
        }
    }

    // MARK: - Stream Management

    private fun startLocationStream() {
        coroutineScope.launch {
            try {
                locationService.startLocationUpdates { locationData ->
                    coroutineScope.launch {
                        locationEventSink?.success(locationDataToMap(locationData))
                    }
                }
            } catch (e: LocationException) {
                locationEventSink?.error(e.code.name, e.message, null)
            } catch (e: Exception) {
                locationEventSink?.error("STREAM_ERROR", e.message, null)
            }
        }
    }

    private fun startIndoorLocationStream() {
        coroutineScope.launch {
            try {
                locationService.startIndoorLocationUpdates { indoorLocationData ->
                    coroutineScope.launch {
                        indoorLocationEventSink?.success(indoorLocationDataToMap(indoorLocationData))
                    }
                }
            } catch (e: LocationException) {
                indoorLocationEventSink?.error(e.code.name, e.message, null)
            } catch (e: Exception) {
                indoorLocationEventSink?.error("INDOOR_STREAM_ERROR", e.message, null)
            }
        }
    }

    // MARK: - Data Conversion Methods

    private fun locationDataToMap(locationData: LocationData): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "latitude" to locationData.latitude,
            "longitude" to locationData.longitude,
            "accuracy" to locationData.accuracy,
            "timestamp" to locationData.timestamp.time,
            "isIndoor" to locationData.isIndoor,
            "source" to locationData.source.name.lowercase()
        )

        locationData.altitude?.let { map["altitude"] = it }
        locationData.altitudeAccuracy?.let { map["altitudeAccuracy"] = it }
        locationData.heading?.let { map["heading"] = it }
        locationData.speed?.let { map["speed"] = it }
        locationData.speedAccuracy?.let { map["speedAccuracy"] = it }
        locationData.address?.let { map["address"] = it }
        locationData.metadata?.let { map["metadata"] = it }

        return map
    }

    private fun indoorLocationDataToMap(indoorLocationData: IndoorLocationData): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>(
            "baseLocation" to locationDataToMap(indoorLocationData.baseLocation),
            "method" to indoorLocationData.method.name.lowercase()
        )

        indoorLocationData.buildingId?.let { map["buildingId"] = it }
        indoorLocationData.floorLevel?.let { map["floorLevel"] = it }
        indoorLocationData.roomId?.let { map["roomId"] = it }
        indoorLocationData.relativeX?.let { map["relativeX"] = it }
        indoorLocationData.relativeY?.let { map["relativeY"] = it }
        indoorLocationData.relativeZ?.let { map["relativeZ"] = it }
        indoorLocationData.beaconId?.let { map["beaconId"] = it }
        indoorLocationData.beaconDistance?.let { map["beaconDistance"] = it }
        indoorLocationData.additionalData?.let { map["additionalData"] = it }

        return map
    }

    private fun capabilitiesToMap(capabilities: LocationCapabilities): Map<String, Any> {
        return mapOf(
            "hasGPS" to capabilities.hasGPS,
            "hasNetwork" to capabilities.hasNetwork,
            "hasPassive" to capabilities.hasPassive,
            "hasIndoorPositioning" to capabilities.hasIndoorPositioning,
            "hasCompass" to capabilities.hasCompass,
            "hasAltimeter" to capabilities.hasAltimeter,
            "supportsFusedProvider" to capabilities.supportsFusedProvider,
            "supportsBackgroundLocation" to capabilities.supportsBackgroundLocation,
            "maxAccuracy" to capabilities.maxAccuracy.name.lowercase(),
            "supportedIndoorMethods" to capabilities.supportedIndoorMethods.map { it.name.lowercase() }
        )
    }

    private fun locationConfigurationToMap(configuration: LocationConfiguration): Map<String, Any> {
        return mapOf(
            "enableGPS" to configuration.enableGPS,
            "enableIndoorPositioning" to configuration.enableIndoorPositioning,
            "desiredAccuracy" to configuration.desiredAccuracy.name.lowercase(),
            "updateInterval" to configuration.updateInterval.toLong(),
            "minimumAccuracy" to configuration.minimumAccuracy,
            "maxAge" to configuration.maxAge.toLong(),
            "enableBackgroundLocation" to configuration.enableBackgroundLocation,
            "enableAddressResolution" to configuration.enableAddressResolution
        )
    }

    private fun beaconDataToMap(beaconData: BeaconData): Map<String, Any> {
        return mapOf(
            "id" to beaconData.id,
            "uuid" to beaconData.uuid,
            "major" to beaconData.major,
            "minor" to beaconData.minor,
            "distance" to beaconData.distance,
            "rssi" to beaconData.rssi,
            "detectedAt" to beaconData.detectedAt.time,
            "metadata" to beaconData.metadata
        )
    }

    // MARK: - Parsing Methods

    private fun mapToLocationConfiguration(map: Map<String, Any>): LocationConfiguration {
        val enableGPS = map["enableGPS"] as? Boolean ?: true
        val enableIndoorPositioning = map["enableIndoorPositioning"] as? Boolean ?: true
        val enableBackgroundLocation = map["enableBackgroundLocation"] as? Boolean ?: true
        val enableAddressResolution = map["enableAddressResolution"] as? Boolean ?: true
        val minimumAccuracy = (map["minimumAccuracy"] as? Number)?.toDouble() ?: 10.0

        val desiredAccuracy = (map["desiredAccuracy"] as? String)?.let { accuracyString ->
            LocationAccuracy.values().find { it.name.lowercase() == accuracyString.lowercase() }
        } ?: LocationAccuracy.HIGH

        val updateInterval = (map["updateInterval"] as? Number)?.toLong() ?: 30000L
        val maxAge = (map["maxAge"] as? Number)?.toLong() ?: 300000L

        return LocationConfiguration(
            enableGPS = enableGPS,
            enableIndoorPositioning = enableIndoorPositioning,
            desiredAccuracy = desiredAccuracy,
            updateInterval = updateInterval,
            minimumAccuracy = minimumAccuracy,
            maxAge = maxAge,
            enableBackgroundLocation = enableBackgroundLocation,
            enableAddressResolution = enableAddressResolution
        )
    }

    private fun mapToCalibrationData(map: Map<String, Any>): CalibrationData? {
        val knownLocationMap = map["knownLocation"] as? Map<String, Any> ?: return null
        val lat = (knownLocationMap["latitude"] as? Number)?.toDouble() ?: return null
        val lon = (knownLocationMap["longitude"] as? Number)?.toDouble() ?: return null
        val accuracy = (knownLocationMap["accuracy"] as? Number)?.toDouble() ?: return null
        val timestampMs = (knownLocationMap["timestamp"] as? Number)?.toLong() ?: return null

        val timestamp = Date(timestampMs)
        val knownLocation = LocationData(
            latitude = lat,
            longitude = lon,
            accuracy = accuracy,
            timestamp = timestamp,
            altitude = null,
            altitudeAccuracy = null,
            heading = null,
            speed = null,
            speedAccuracy = null,
            address = null,
            isIndoor = false,
            source = LocationSource.MANUAL,
            metadata = null
        )

        val beacons = mutableListOf<BeaconData>()
        (map["beacons"] as? List<Map<String, Any>>)?.forEach { beaconMap ->
            val id = beaconMap["id"] as? String ?: return@forEach
            val uuid = beaconMap["uuid"] as? String ?: return@forEach
            val major = (beaconMap["major"] as? Number)?.toInt() ?: return@forEach
            val minor = (beaconMap["minor"] as? Number)?.toInt() ?: return@forEach
            val distance = (beaconMap["distance"] as? Number)?.toDouble() ?: return@forEach
            val rssi = (beaconMap["rssi"] as? Number)?.toDouble() ?: return@forEach
            val detectedAtMs = (beaconMap["detectedAt"] as? Number)?.toLong() ?: return@forEach
            val metadata = beaconMap["metadata"] as? Map<String, Any> ?: emptyMap()

            val detectedAt = Date(detectedAtMs)
            beacons.add(
                BeaconData(
                    id = id,
                    uuid = uuid,
                    major = major,
                    minor = minor,
                    distance = distance,
                    rssi = rssi,
                    detectedAt = detectedAt,
                    metadata = metadata
                )
            )
        }

        val wifiSignals = map["wifiSignals"] as? Map<String, Any> ?: emptyMap()
        val environmentalData = map["environmentalData"] as? Map<String, Any> ?: emptyMap()
        val calibratedAtMs = (map["calibratedAt"] as? Number)?.toLong() ?: System.currentTimeMillis()
        val calibratedAt = Date(calibratedAtMs)

        return CalibrationData(
            knownLocation = knownLocation,
            beacons = beacons,
            wifiSignals = wifiSignals,
            environmentalData = environmentalData,
            calibratedAt = calibratedAt
        )
    }

    // MARK: - Error Handling

    private fun handleLocationError(error: LocationException, result: Result) {
        result.error(error.code.name, error.message, null)
    }
}
