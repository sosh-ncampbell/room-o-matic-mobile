package com.roomomatic.sensors

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.os.Looper
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.*
import com.google.android.gms.tasks.Task
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlin.math.*

/**
 * Android location service using FusedLocationProvider for high accuracy positioning
 */
class AndroidLocationService(
    private val context: Context,
    private val methodChannel: MethodChannel
) {
    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)
    private var locationCallback: LocationCallback? = null
    private var isLocationActive = false
    private var currentLocation: Location? = null

    private val locationRequest = LocationRequest.Builder(
        Priority.PRIORITY_HIGH_ACCURACY,
        1000L // Update interval: 1 second
    ).apply {
        setMinUpdateDistanceMeters(0.5f) // Minimum distance: 0.5 meters
        setGranularity(Granularity.GRANULARITY_PERMISSION_LEVEL)
        setWaitForAccurateLocation(true)
    }.build()

    /**
     * Check location service capabilities and permissions
     */
    fun checkLocationCapabilities(): Map<String, Any> {
        val capabilities = mutableMapOf<String, Any>()

        capabilities["locationServicesEnabled"] = isLocationEnabled()
        capabilities["hasPermission"] = hasLocationPermission()
        capabilities["supportsPreciseLocation"] = true
        capabilities["supportsBackgroundLocation"] = hasBackgroundLocationPermission()
        capabilities["supportsFusedLocation"] = true

        // Check available location providers
        val availableProviders = mutableListOf<String>()
        if (context.packageManager.hasSystemFeature(PackageManager.FEATURE_LOCATION_GPS)) {
            availableProviders.add("gps")
        }
        if (context.packageManager.hasSystemFeature(PackageManager.FEATURE_LOCATION_NETWORK)) {
            availableProviders.add("network")
        }
        capabilities["availableProviders"] = availableProviders

        return capabilities
    }

    /**
     * Request location permissions
     */
    fun requestLocationPermission(): Boolean {
        return hasLocationPermission()
    }

    /**
     * Start location tracking
     */
    fun startLocationTracking(): Boolean {
        if (!hasLocationPermission() || !isLocationEnabled()) {
            return false
        }

        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                super.onLocationResult(locationResult)
                locationResult.lastLocation?.let { location ->
                    currentLocation = location
                    sendLocationUpdate(location)
                }
            }

            override fun onLocationAvailability(locationAvailability: LocationAvailability) {
                super.onLocationAvailability(locationAvailability)
                val availabilityData = mapOf(
                    "isLocationAvailable" to locationAvailability.isLocationAvailable
                )
                methodChannel.invokeMethod("onLocationAvailabilityChanged", availabilityData)
            }
        }

        try {
            if (ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED ||
                ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                fusedLocationClient.requestLocationUpdates(
                    locationRequest,
                    locationCallback!!,
                    Looper.getMainLooper()
                )
                isLocationActive = true
                return true
            }
        } catch (e: Exception) {
            sendLocationError("Failed to start location tracking: ${e.message}")
        }

        return false
    }

    /**
     * Stop location tracking
     */
    fun stopLocationTracking() {
        locationCallback?.let { callback ->
            fusedLocationClient.removeLocationUpdates(callback)
        }
        locationCallback = null
        isLocationActive = false
    }

    /**
     * Get current location data
     */
    fun getCurrentLocation(): Map<String, Any>? {
        return currentLocation?.let { location ->
            createLocationData(location)
        }
    }

    /**
     * Get last known location (if available)
     */
    fun getLastKnownLocation(callback: (Map<String, Any>?) -> Unit) {
        if (!hasLocationPermission()) {
            callback(null)
            return
        }

        try {
            if (ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED ||
                ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED
            ) {
                fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                    callback(location?.let { createLocationData(it) })
                }.addOnFailureListener {
                    callback(null)
                }
            } else {
                callback(null)
            }
        } catch (e: Exception) {
            callback(null)
        }
    }

    /**
     * Measure distance between current location and target
     */
    fun measureDistance(targetLocation: Map<String, Double>): Map<String, Any>? {
        val currentLoc = currentLocation ?: return null
        val targetLat = targetLocation["latitude"] ?: return null
        val targetLon = targetLocation["longitude"] ?: return null

        val distance = calculateDistance(
            currentLoc.latitude, currentLoc.longitude,
            targetLat, targetLon
        )

        val bearing = calculateBearing(
            currentLoc.latitude, currentLoc.longitude,
            targetLat, targetLon
        )

        return mapOf(
            "distance" to distance,
            "bearing" to bearing,
            "accuracy" to currentLoc.accuracy.toDouble(),
            "method" to "FusedLocationProvider"
        )
    }

    // MARK: - Private Methods

    private fun hasLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
        ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun hasBackgroundLocationPermission(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_BACKGROUND_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun isLocationEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as android.location.LocationManager
        return locationManager.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER)
    }

    private fun createLocationData(location: Location): Map<String, Any> {
        return mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "altitude" to location.altitude,
            "accuracy" to location.accuracy.toDouble(),
            "verticalAccuracy" to if (location.hasVerticalAccuracy()) location.verticalAccuracyMeters.toDouble() else -1.0,
            "timestamp" to location.time,
            "speed" to if (location.hasSpeed()) location.speed.toDouble() else 0.0,
            "bearing" to if (location.hasBearing()) location.bearing.toDouble() else 0.0,
            "provider" to (location.provider ?: "unknown")
        )
    }

    private fun sendLocationUpdate(location: Location) {
        val locationData = createLocationData(location)
        methodChannel.invokeMethod("onLocationUpdate", locationData)
    }

    private fun sendLocationError(error: String) {
        val errorData = mapOf("error" to error)
        methodChannel.invokeMethod("onLocationError", errorData)
    }

    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val R = 6371000.0 // Earth's radius in meters
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    private fun calculateBearing(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val dLon = Math.toRadians(lon2 - lon1)
        val lat1Rad = Math.toRadians(lat1)
        val lat2Rad = Math.toRadians(lat2)

        val y = sin(dLon) * cos(lat2Rad)
        val x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon)

        val bearing = Math.toDegrees(atan2(y, x))
        return (bearing + 360) % 360
    }
}
