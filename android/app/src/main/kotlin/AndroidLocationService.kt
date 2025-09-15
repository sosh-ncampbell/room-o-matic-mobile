package com.roomomatic.room_o_matic_mobile

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import com.google.android.gms.tasks.Tasks
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.util.*
import kotlin.collections.HashMap

/**
 * Android location service for GPS and indoor positioning
 * Integrates with Flutter through platform channels
 * Uses Google Play Services for enhanced location accuracy
 */
class AndroidLocationService(
    private val context: Context,
    private val channel: MethodChannel
) : LocationListener {

    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
    private val geocoder = if (Geocoder.isPresent()) Geocoder(context, Locale.getDefault()) else null

    private var isMonitoring = false
    private var currentConfiguration: LocationConfiguration? = null
    private var locationCallback: LocationCallback? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // MARK: - Public Methods

    suspend fun getCurrentLocation(): LocationData? {
        return withContext(Dispatchers.IO) {
            try {
                if (!hasLocationPermission()) {
                    throw LocationException("Location permission not granted", LocationErrorCode.PERMISSION_DENIED)
                }

                if (!isLocationEnabled()) {
                    throw LocationException("Location services disabled", LocationErrorCode.SERVICE_DISABLED)
                }

                val location = Tasks.await(fusedLocationClient.lastLocation)
                    ?: requestSingleLocationUpdate()

                location?.let { createLocationData(it) }
            } catch (e: Exception) {
                null
            }
        }
    }

    fun startLocationUpdates(): Boolean {
        return try {
            if (!hasLocationPermission() || !isLocationEnabled()) {
                false
            } else {
                val locationRequest = createLocationRequest()
                val callback = createLocationCallback()

                fusedLocationClient.requestLocationUpdates(
                    locationRequest,
                    callback,
                    Looper.getMainLooper()
                )

                locationCallback = callback
                isMonitoring = true
                true
            }
        } catch (e: Exception) {
            false
        }
    }

    fun stopLocationUpdates() {
        locationCallback?.let { callback ->
            fusedLocationClient.removeLocationUpdates(callback)
        }
        locationCallback = null
        isMonitoring = false
    }

    fun getServiceStatus(): LocationServiceStatus {
        return when {
            !isLocationEnabled() -> LocationServiceStatus.DISABLED
            !hasLocationPermission() -> LocationServiceStatus.DENIED
            hasLocationPermission() -> LocationServiceStatus.ENABLED
            else -> LocationServiceStatus.UNKNOWN
        }
    }

    fun getCapabilities(): LocationCapabilities {
        val hasGPS = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val hasNetwork = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        val hasPassive = locationManager.isProviderEnabled(LocationManager.PASSIVE_PROVIDER)

        return LocationCapabilities(
            hasGPS = hasGPS,
            hasNetwork = hasNetwork,
            hasPassive = hasPassive,
            hasIndoorPositioning = hasWiFiPositioning(),
            hasCompass = context.packageManager.hasSystemFeature(PackageManager.FEATURE_SENSOR_COMPASS),
            hasAltimeter = context.packageManager.hasSystemFeature(PackageManager.FEATURE_SENSOR_BAROMETER),
            supportsFusedProvider = true,
            supportsBackgroundLocation = hasBackgroundLocationPermission(),
            maxAccuracy = LocationAccuracy.BEST,
            supportedIndoorMethods = getSupportedIndoorMethods()
        )
    }

    fun configure(configuration: LocationConfiguration) {
        this.currentConfiguration = configuration

        // Restart location updates with new configuration if currently monitoring
        if (isMonitoring) {
            stopLocationUpdates()
            startLocationUpdates()
        }
    }

    suspend fun resolveAddress(latitude: Double, longitude: Double): String? {
        return withContext(Dispatchers.IO) {
            try {
                geocoder?.let { geocoder ->
                    val addresses = geocoder.getFromLocation(latitude, longitude, 1)
                    addresses?.firstOrNull()?.let { formatAddress(it) }
                }
            } catch (e: Exception) {
                null
            }
        }
    }

    suspend fun getCoordinatesFromAddress(address: String): LocationData? {
        return withContext(Dispatchers.IO) {
            try {
                geocoder?.let { geocoder ->
                    val addresses = geocoder.getFromLocationName(address, 1)
                    addresses?.firstOrNull()?.let { addr ->
                        LocationData(
                            latitude = addr.latitude,
                            longitude = addr.longitude,
                            accuracy = 10.0, // Geocoded addresses have approximate accuracy
                            timestamp = Date(),
                            source = LocationSource.NETWORK
                        )
                    }
                }
            } catch (e: Exception) {
                null
            }
        }
    }

    fun calculateDistance(location1: LocationData, location2: LocationData): Double {
        val results = FloatArray(1)
        Location.distanceBetween(
            location1.latitude,
            location1.longitude,
            location2.latitude,
            location2.longitude,
            results
        )
        return results[0].toDouble()
    }

    // MARK: - Indoor Positioning

    suspend fun getIndoorLocation(): IndoorLocationData? {
        return withContext(Dispatchers.IO) {
            try {
                val baseLocation = getCurrentLocation() ?: return@withContext null

                // Attempt to get indoor positioning data
                val wifiInfo = getWiFiPositioningData()
                val bluetoothBeacons = getBluetoothBeacons()

                // Create indoor location data if we have positioning information
                if (wifiInfo.isNotEmpty() || bluetoothBeacons.isNotEmpty()) {
                    IndoorLocationData(
                        baseLocation = baseLocation,
                        method = determineIndoorMethod(wifiInfo, bluetoothBeacons),
                        additionalData = mapOf(
                            "wifi" to wifiInfo,
                            "beacons" to bluetoothBeacons
                        )
                    )
                } else {
                    null
                }
            } catch (e: Exception) {
                null
            }
        }
    }

    // MARK: - Permission Handling

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasBackgroundLocationPermission(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            hasLocationPermission()
        }
    }

    private fun isLocationEnabled(): Boolean {
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
               locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    // MARK: - Location Request Configuration

    private fun createLocationRequest(): LocationRequest {
        val config = currentConfiguration ?: LocationConfiguration.default()

        return LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, config.updateInterval.toMillis())
            .setMinUpdateDistanceMeters(1.0f)
            .setGranularity(Granularity.GRANULARITY_PERMISSION_LEVEL)
            .setWaitForAccurateLocation(true)
            .build()
    }

    private fun createLocationCallback(): LocationCallback {
        return object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                val location = locationResult.lastLocation ?: return
                val locationData = createLocationData(location)

                // Send to Flutter
                scope.launch {
                    channel.invokeMethod("onLocationUpdate", locationData.toMap())
                }
            }

            override fun onLocationAvailability(availability: LocationAvailability) {
                if (!availability.isLocationAvailable) {
                    scope.launch {
                        channel.invokeMethod("onLocationError", mapOf(
                            "code" to "LOCATION_UNAVAILABLE",
                            "message" to "Location temporarily unavailable"
                        ))
                    }
                }
            }
        }
    }

    // MARK: - Data Conversion

    private fun createLocationData(location: Location): LocationData {
        return LocationData(
            latitude = location.latitude,
            longitude = location.longitude,
            accuracy = location.accuracy.toDouble(),
            timestamp = Date(location.time),
            altitude = if (location.hasAltitude()) location.altitude else null,
            altitudeAccuracy = if (location.hasVerticalAccuracy()) location.verticalAccuracyMeters.toDouble() else null,
            heading = if (location.hasBearing()) location.bearing.toDouble() else null,
            speed = if (location.hasSpeed()) location.speed.toDouble() else null,
            speedAccuracy = if (location.hasSpeedAccuracy()) location.speedAccuracyMetersPerSecond.toDouble() else null,
            source = determineLocationSource(location.provider),
            metadata = mapOf(
                "provider" to (location.provider ?: "unknown"),
                "elapsedRealtimeNanos" to location.elapsedRealtimeNanos,
                "timestamp" to location.time
            )
        )
    }

    private fun determineLocationSource(provider: String?): LocationSource {
        return when (provider) {
            LocationManager.GPS_PROVIDER -> LocationSource.GPS
            LocationManager.NETWORK_PROVIDER -> LocationSource.NETWORK
            LocationManager.PASSIVE_PROVIDER -> LocationSource.PASSIVE
            "fused" -> LocationSource.FUSED
            else -> LocationSource.FUSED
        }
    }

    private fun formatAddress(address: Address): String {
        val components = mutableListOf<String>()

        (0..address.maxAddressLineIndex).forEach { i ->
            address.getAddressLine(i)?.let { components.add(it) }
        }

        return if (components.isNotEmpty()) {
            components.joinToString(", ")
        } else {
            // Fallback to individual components
            listOfNotNull(
                address.featureName,
                address.thoroughfare,
                address.locality,
                address.adminArea,
                address.postalCode,
                address.countryName
            ).joinToString(", ")
        }
    }

    // MARK: - Indoor Positioning Helpers

    private fun hasWiFiPositioning(): Boolean {
        return context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI)
    }

    private fun getSupportedIndoorMethods(): List<IndoorPositioningMethod> {
        val methods = mutableListOf<IndoorPositioningMethod>()

        if (context.packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI)) {
            methods.add(IndoorPositioningMethod.WIFI)
        }

        if (context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)) {
            methods.add(IndoorPositioningMethod.BLUETOOTH)
        }

        if (context.packageManager.hasSystemFeature(PackageManager.FEATURE_SENSOR_COMPASS)) {
            methods.add(IndoorPositioningMethod.MAGNETIC)
        }

        methods.add(IndoorPositioningMethod.FUSION)

        return methods
    }

    private suspend fun getWiFiPositioningData(): Map<String, Any> {
        return withContext(Dispatchers.IO) {
            try {
                // WiFi scanning would be implemented here
                // Note: Requires additional permissions and setup
                mapOf<String, Any>()
            } catch (e: Exception) {
                mapOf<String, Any>()
            }
        }
    }

    private suspend fun getBluetoothBeacons(): List<Map<String, Any>> {
        return withContext(Dispatchers.IO) {
            try {
                // Bluetooth beacon scanning would be implemented here
                // Note: Requires additional permissions and Bluetooth setup
                listOf<Map<String, Any>>()
            } catch (e: Exception) {
                listOf<Map<String, Any>>()
            }
        }
    }

    private fun determineIndoorMethod(
        wifiInfo: Map<String, Any>,
        bluetoothBeacons: List<Map<String, Any>>
    ): IndoorPositioningMethod {
        return when {
            bluetoothBeacons.isNotEmpty() -> IndoorPositioningMethod.BLUETOOTH
            wifiInfo.isNotEmpty() -> IndoorPositioningMethod.WIFI
            else -> IndoorPositioningMethod.FUSION
        }
    }

    // MARK: - Single Location Update

    private suspend fun requestSingleLocationUpdate(): Location? {
        return withContext(Dispatchers.IO) {
            try {
                val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 0)
                    .setMaxUpdates(1)
                    .build()

                Tasks.await(fusedLocationClient.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, null))
            } catch (e: Exception) {
                null
            }
        }
    }

    // MARK: - LocationListener Implementation (Fallback)

    override fun onLocationChanged(location: Location) {
        val locationData = createLocationData(location)
        scope.launch {
            channel.invokeMethod("onLocationUpdate", locationData.toMap())
        }
    }

    override fun onProviderEnabled(provider: String) {
        scope.launch {
            channel.invokeMethod("onProviderStatusChanged", mapOf(
                "provider" to provider,
                "enabled" to true
            ))
        }
    }

    override fun onProviderDisabled(provider: String) {
        scope.launch {
            channel.invokeMethod("onProviderStatusChanged", mapOf(
                "provider" to provider,
                "enabled" to false
            ))
        }
    }

    @Deprecated("Deprecated in API level 29")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
        // Legacy method - no implementation needed
    }

    // MARK: - Cleanup

    fun dispose() {
        stopLocationUpdates()
        scope.cancel()
    }
}

// MARK: - Supporting Classes

data class LocationData(
    val latitude: Double,
    val longitude: Double,
    val accuracy: Double,
    val timestamp: Date,
    val altitude: Double? = null,
    val altitudeAccuracy: Double? = null,
    val heading: Double? = null,
    val speed: Double? = null,
    val speedAccuracy: Double? = null,
    val address: String? = null,
    val isIndoor: Boolean = false,
    val source: LocationSource = LocationSource.GPS,
    val metadata: Map<String, Any>? = null
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "latitude" to latitude,
            "longitude" to longitude,
            "accuracy" to accuracy,
            "timestamp" to timestamp.time,
            "altitude" to altitude,
            "altitudeAccuracy" to altitudeAccuracy,
            "heading" to heading,
            "speed" to speed,
            "speedAccuracy" to speedAccuracy,
            "address" to address,
            "isIndoor" to isIndoor,
            "source" to source.name,
            "metadata" to metadata
        )
    }
}

data class IndoorLocationData(
    val baseLocation: LocationData,
    val buildingId: String? = null,
    val floorLevel: String? = null,
    val roomId: String? = null,
    val relativeX: Double? = null,
    val relativeY: Double? = null,
    val relativeZ: Double? = null,
    val beaconId: String? = null,
    val beaconDistance: Double? = null,
    val method: IndoorPositioningMethod = IndoorPositioningMethod.FUSION,
    val additionalData: Map<String, Any>? = null
)

data class LocationConfiguration(
    val enableGPS: Boolean = true,
    val enableIndoorPositioning: Boolean = true,
    val desiredAccuracy: LocationAccuracy = LocationAccuracy.HIGH,
    val updateInterval: Duration = Duration.ofSeconds(30),
    val minimumAccuracy: Double = 10.0,
    val maxAge: Duration = Duration.ofMinutes(5),
    val enableBackgroundLocation: Boolean = true,
    val enableAddressResolution: Boolean = true
) {
    companion object {
        fun default() = LocationConfiguration()
    }
}

data class LocationCapabilities(
    val hasGPS: Boolean,
    val hasNetwork: Boolean,
    val hasPassive: Boolean,
    val hasIndoorPositioning: Boolean,
    val hasCompass: Boolean,
    val hasAltimeter: Boolean,
    val supportsFusedProvider: Boolean,
    val supportsBackgroundLocation: Boolean,
    val maxAccuracy: LocationAccuracy,
    val supportedIndoorMethods: List<IndoorPositioningMethod>
)

// MARK: - Enums

enum class LocationSource {
    GPS,
    NETWORK,
    PASSIVE,
    FUSED,
    WIFI,
    BLUETOOTH,
    BEACON,
    MANUAL
}

enum class LocationAccuracy {
    LOWEST,
    LOW,
    MEDIUM,
    HIGH,
    BEST,
    BEST_FOR_NAVIGATION;

    fun toMeters(): Double {
        return when (this) {
            LOWEST -> 3000.0
            LOW -> 1000.0
            MEDIUM -> 100.0
            HIGH -> 10.0
            BEST -> 3.0
            BEST_FOR_NAVIGATION -> 1.0
        }
    }
}

enum class IndoorPositioningMethod {
    WIFI,
    BLUETOOTH,
    BEACON,
    ULTRASONIC,
    MAGNETIC,
    VISUAL,
    FUSION
}

enum class LocationServiceStatus {
    ENABLED,
    DISABLED,
    RESTRICTED,
    DENIED,
    UNKNOWN
}

enum class LocationErrorCode {
    SERVICE_DISABLED,
    PERMISSION_DENIED,
    LOCATION_UNAVAILABLE,
    TIMEOUT,
    NETWORK_ERROR,
    ACCURACY_INSUFFICIENT,
    INDOOR_POSITIONING_UNAVAILABLE,
    CALIBRATION_REQUIRED,
    UNKNOWN
}

class LocationException(
    message: String,
    val code: LocationErrorCode,
    cause: Throwable? = null
) : Exception(message, cause)

// MARK: - Extensions

private fun Duration.toMillis(): Long = toMillis()
