package com.roomomatic.room_o_matic_mobile

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.camera2.CameraManager
import android.location.LocationManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import com.roomomatic.sensors.ToFSensorManager
import com.roomomatic.sensors.AndroidSensorFusionService
import com.roomomatic.sensors.AndroidLocationService
import com.roomomatic.sensors.AndroidEnhancedCameraService
import com.roomomatic.sensors.AndroidChiropteraService
import java.util.*
import kotlin.collections.HashMap

class SensorChannelManager(private val context: Context, private val flutterEngine: FlutterEngine) :
    MethodChannel.MethodCallHandler, SensorEventListener {

    private var methodChannel: MethodChannel
    private var sensorManager: SensorManager
    private var cameraManager: CameraManager
    private var locationManager: LocationManager

                // Advanced sensor services
    private var toFSensorManager: ToFSensorManager? = null
    private var androidSensorFusionService: AndroidSensorFusionService? = null
    private var androidLocationService: AndroidLocationService? = null
    private var androidEnhancedCameraService: AndroidEnhancedCameraService? = null
    private var androidChiropteraService: AndroidChiropteraService? = null

    private var isScanning = false
    private var activeSensors = mutableListOf<Sensor>()

    // Sensor types
    private var accelerometer: Sensor? = null
    private var gyroscope: Sensor? = null
    private var magnetometer: Sensor? = null
    private var toFSensor: Sensor? = null

    companion object {
        const val CHANNEL_NAME = "com.roomomatic.sensors/lidar"
        const val PERMISSION_REQUEST_CODE = 100

        // Required permissions
        val REQUIRED_PERMISSIONS = arrayOf(
            Manifest.permission.CAMERA,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.RECORD_AUDIO
        )
    }

    init {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)

        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

        initializeSensors()
        initializeAdvancedServices()
    }

    private fun initializeSensors() {
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        gyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
        magnetometer = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

        // Check for ToF sensor (available on some Android devices)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            toFSensor = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
        }
    }

    private fun initializeAdvancedServices() {
        tofSensorManager = ToFSensorManager(context, methodChannel)
        sensorFusionService = AndroidSensorFusionService(context, methodChannel, tofSensorManager)
        androidLocationService = AndroidLocationService(context)
        androidEnhancedCameraService = AndroidEnhancedCameraService(context)
        androidChiropteraService = AndroidChiropteraService(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startLiDARScan" -> startLiDARScan(result)
            "stopLiDARScan" -> stopLiDARScan(result)
            "isLiDARAvailable" -> checkLiDARAvailability(result)
            "startMotionSensors" -> startMotionSensors(result)
            "stopMotionSensors" -> stopMotionSensors(result)
            "getCameraFrame" -> getCameraFrame(result)
            "requestCameraPermission" -> requestCameraPermission(result)
            "requestLocationPermission" -> requestLocationPermission(result)
            "requestMotionPermission" -> requestMotionPermission(result)
            // Location methods
            "startLocationTracking" -> startLocationTracking(result)
            "stopLocationTracking" -> stopLocationTracking(result)
            "getCurrentLocation" -> getCurrentLocation(result)
            "getLocationCapabilities" -> getLocationCapabilities(result)

            // Enhanced Camera methods
            "initializeEnhancedCamera" -> initializeEnhancedCamera(call, result)
            "startCameraSession" -> startCameraSession(result)
            "stopCameraSession" -> stopCameraSession(result)
            "captureEnhancedPhoto" -> captureEnhancedPhoto(call, result)
            "getEnhancedCameraCapabilities" -> getEnhancedCameraCapabilities(result)
            "measureCameraDistance" -> measureCameraDistance(call, result)
            "measureLocationDistance" -> measureLocationDistance(call, result)

            // Chiroptera (Audio Sonar) methods
            "initializeChiroptera" -> initializeChiroptera(call, result)
            "startChiropteraSession" -> startChiropteraSession(result)
            "stopChiropteraSession" -> stopChiropteraSession(result)
            "performChiropteraPing" -> performChiropteraPing(call, result)
            "measureChiropteraDistance" -> measureChiropteraDistance(call, result)
            "getChiropteraCapabilities" -> getChiropteraCapabilities(result)

            // Advanced sensor methods
            "getAdvancedCapabilities" -> getAdvancedCapabilities(result)
            "startAdvancedToF" -> startAdvancedToF(call, result)
            "stopSensorSession" -> stopSensorSession(call, result)
            "getCurrentToFData" -> getCurrentToFData(call, result)
            "startSensorFusion" -> startSensorFusion(call, result)
            "getFusionData" -> getFusionData(call, result)
            "measureAdvancedDistance" -> measureAdvancedDistance(call, result)
            else -> result.notImplemented()
        }
    }

    private fun checkLiDARAvailability(result: Result) {
        // Android doesn't typically have LiDAR, but some high-end devices have ToF sensors
        val hasToF = toFSensor != null
        val hasDepthCamera = checkDepthCameraAvailability()
        result.success(hasToF || hasDepthCamera)
    }

    private fun checkDepthCameraAvailability(): Boolean {
        return try {
            val cameraIds = cameraManager.cameraIdList
            cameraIds.any { cameraId ->
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    val capabilities = characteristics.get(android.hardware.camera2.CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
                    capabilities?.contains(android.hardware.camera2.CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT) ?: false
                } else {
                    false
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun startLiDARScan(result: Result) {
        if (isScanning) {
            result.error("SCAN_IN_PROGRESS", "Sensor scan is already in progress", null)
            return
        }

        if (!checkPermissions()) {
            result.error("PERMISSIONS_REQUIRED", "Camera and location permissions are required", null)
            return
        }

        // Start ToF sensor if available
        toFSensor?.let { sensor ->
            sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_FASTEST)
            activeSensors.add(sensor)
        }

        isScanning = true
        result.success(true)
    }

    private fun stopLiDARScan(result: Result) {
        stopAllSensors()
        isScanning = false
        result.success(true)
    }

    private fun startMotionSensors(result: Result) {
        val sensorsStarted = mutableListOf<String>()

        accelerometer?.let { sensor ->
            if (sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_FASTEST)) {
                activeSensors.add(sensor)
                sensorsStarted.add("accelerometer")
            }
        }

        gyroscope?.let { sensor ->
            if (sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_FASTEST)) {
                activeSensors.add(sensor)
                sensorsStarted.add("gyroscope")
            }
        }

        magnetometer?.let { sensor ->
            if (sensorManager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_FASTEST)) {
                activeSensors.add(sensor)
                sensorsStarted.add("magnetometer")
            }
        }

        result.success(sensorsStarted.isNotEmpty())
    }

    private fun stopMotionSensors(result: Result) {
        sensorManager.unregisterListener(this)
        activeSensors.clear()
        result.success(true)
    }

    private fun getCameraFrame(result: Result) {
        // This would require implementing camera capture functionality
        // For now, return basic camera info
        val cameraData = hashMapOf(
            "timestamp" to System.currentTimeMillis(),
            "hasCamera" to (cameraManager.cameraIdList.isNotEmpty())
        )
        result.success(cameraData)
    }

    private fun stopAllSensors() {
        sensorManager.unregisterListener(this)
        activeSensors.clear()
    }

    private fun checkPermissions(): Boolean {
        return REQUIRED_PERMISSIONS.all { permission ->
            ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestCameraPermission(result: Result) {
        val hasPermission = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        result.success(hasPermission)
    }

    private fun requestLocationPermission(result: Result) {
        val hasPermission = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        result.success(hasPermission)
    }

    private fun requestMotionPermission(result: Result) {
        // Motion sensors don't require permissions on Android
        result.success(true)
    }

    // SensorEventListener implementation
    override fun onSensorChanged(event: SensorEvent) {
        val sensorType = when (event.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> "accelerometer"
            Sensor.TYPE_GYROSCOPE -> "gyroscope"
            Sensor.TYPE_MAGNETIC_FIELD -> "magnetometer"
            Sensor.TYPE_PROXIMITY -> "tof"
            else -> "unknown"
        }

        val sensorData = hashMapOf(
            "type" to sensorType,
            "timestamp" to (event.timestamp / 1000000.0), // Convert nanoseconds to milliseconds
            "x" to event.values[0].toDouble(),
            "y" to if (event.values.size > 1) event.values[1].toDouble() else 0.0,
            "z" to if (event.values.size > 2) event.values[2].toDouble() else 0.0
        )

        methodChannel.invokeMethod("onMotionData", sensorData)
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        // Handle accuracy changes if needed
    }

    // Advanced sensor method implementations
    private fun getAdvancedCapabilities(result: Result) {
        val tofCapabilities = tofSensorManager.getCapabilities()
        val fusionCapabilities = sensorFusionService.getCapabilities()

        val capabilities = mutableMapOf<String, Any>()
        capabilities.putAll(tofCapabilities)
        capabilities.putAll(fusionCapabilities)
        capabilities["supportsSceneReconstruction"] = false // Android typically doesn't support this
        capabilities["supportsDepthData"] = tofCapabilities["hasToF"] ?: false
        capabilities["supportsMeshGeneration"] = false

        result.success(capabilities)
    }

    private fun startAdvancedToF(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
        val sessionId = arguments["sessionId"] as? String ?: ""
        val config = arguments["config"] as? Map<String, Any> ?: emptyMap()

        val resultData = tofSensorManager.startToFSession(sessionId, config)
        result.success(resultData)
    }

    private fun stopSensorSession(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
        val sessionId = arguments["sessionId"] as? String ?: ""

        val tofResult = tofSensorManager.stopToFSession(sessionId)
        val fusionResult = sensorFusionService.stopSensorFusion(sessionId)

        // Return success if either service successfully stopped the session
        val success = tofResult["success"] == true || fusionResult["success"] == true
        result.success(mapOf("success" to success, "sessionId" to sessionId))
    }

    private fun getCurrentToFData(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
        val sessionId = arguments["sessionId"] as? String ?: ""

        val tofData = tofSensorManager.getCurrentToFData(sessionId)
        result.success(tofData)
    }

    private fun startSensorFusion(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
        val sessionId = arguments["sessionId"] as? String ?: ""
        val sensors = arguments["sensors"] as? List<String> ?: emptyList()
        val config = arguments["config"] as? Map<String, Any> ?: emptyMap()

        val resultData = sensorFusionService.startSensorFusion(sessionId, sensors, config)
        result.success(resultData)
    }

    private fun getFusionData(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
        val sessionId = arguments["sessionId"] as? String ?: ""

        val fusionData = sensorFusionService.getFusionData(sessionId)
        result.success(fusionData)
    }

    private fun measureAdvancedDistance(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<String, Any> ?: emptyMap()

        val resultData = tofSensorManager.measureDistance(arguments)
        result.success(resultData)
    }

    // MARK: - Location Methods

    private fun startLocationTracking(result: Result) {
        androidLocationService?.let { locationService ->
            val success = locationService.startLocationTracking()
            result.success(success)
        } ?: result.error("LOCATION_SERVICE_ERROR", "Location service not available", null)
    }

    private fun stopLocationTracking(result: Result) {
        androidLocationService?.let { locationService ->
            locationService.stopLocationTracking()
            result.success(true)
        } ?: result.error("LOCATION_SERVICE_ERROR", "Location service not available", null)
    }

    private fun getCurrentLocation(result: Result) {
        androidLocationService?.let { locationService ->
            val locationData = locationService.getCurrentLocation()
            if (locationData != null) {
                result.success(locationData)
            } else {
                result.error("NO_LOCATION_DATA", "No location data available", null)
            }
        } ?: result.error("LOCATION_SERVICE_ERROR", "Location service not available", null)
    }

    private fun getLocationCapabilities(result: Result) {
        androidLocationService?.let { locationService ->
            val capabilities = locationService.checkLocationCapabilities()
            result.success(capabilities)
        } ?: result.error("LOCATION_SERVICE_ERROR", "Location service not available", null)
    }

    private fun measureLocationDistance(call: MethodCall, result: Result) {
        val arguments = call.arguments as? Map<String, Any>
        val targetLocation = arguments?.get("targetLocation") as? Map<String, Double>

        if (targetLocation == null) {
            result.error("INVALID_ARGUMENTS", "Invalid arguments for location distance measurement", null)
            return
        }

        androidLocationService?.let { locationService ->
            val distanceData = locationService.measureDistance(targetLocation)
            if (distanceData != null) {
                result.success(distanceData)
            } else {
                result.error("LOCATION_MEASUREMENT_FAILED", "Failed to measure location distance", null)
            }
        } ?: result.error("LOCATION_SERVICE_ERROR", "Location service not available", null)
    }

    fun dispose() {
        stopAllSensors()
        tofSensorManager.cleanup()
        sensorFusionService.cleanup()
        androidLocationService?.stopLocationTracking()
        androidEnhancedCameraService?.cleanup()
        androidChiropteraService?.cleanup()
        methodChannel.setMethodCallHandler(null)
    }

    // MARK: - Enhanced Camera Methods

    private fun initializeEnhancedCamera(call: MethodCall, result: Result) {
        val config = call.arguments as? Map<String, Any> ?: emptyMap()

        androidEnhancedCameraService?.let { cameraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, capabilities) = cameraService.initialize(config)
                    if (success) {
                        result.success(capabilities)
                    } else {
                        result.error("INIT_FAILED", "Failed to initialize enhanced camera", capabilities)
                    }
                }
            }.onFailure { error ->
                result.error("INIT_ERROR", "Camera initialization error: ${error.message}", null)
            }
        } ?: result.error("CAMERA_UNAVAILABLE", "Enhanced camera service not available", null)
    }

    private fun startCameraSession(result: Result) {
        androidEnhancedCameraService?.let { cameraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, error) = cameraService.startSession()
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("SESSION_FAILED", error ?: "Unknown error", null)
                    }
                }
            }.onFailure { error ->
                result.error("SESSION_ERROR", "Camera session error: ${error.message}", null)
            }
        } ?: result.error("CAMERA_UNAVAILABLE", "Enhanced camera service not available", null)
    }

    private fun stopCameraSession(result: Result) {
        androidEnhancedCameraService?.let { cameraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, error) = cameraService.stopSession()
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("SESSION_FAILED", error ?: "Unknown error", null)
                    }
                }
            }.onFailure { error ->
                result.error("SESSION_ERROR", "Camera session error: ${error.message}", null)
            }
        } ?: result.error("CAMERA_UNAVAILABLE", "Enhanced camera service not available", null)
    }

    private fun captureEnhancedPhoto(call: MethodCall, result: Result) {
        val settings = call.arguments as? Map<String, Any> ?: emptyMap()

        androidEnhancedCameraService?.let { cameraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, photoData) = cameraService.capturePhoto(settings)
                    if (success) {
                        result.success(photoData)
                    } else {
                        result.error("CAPTURE_FAILED", "Failed to capture photo", photoData)
                    }
                }
            }.onFailure { error ->
                result.error("CAPTURE_ERROR", "Photo capture error: ${error.message}", null)
            }
        } ?: result.error("CAMERA_UNAVAILABLE", "Enhanced camera service not available", null)
    }

    private fun getEnhancedCameraCapabilities(result: Result) {
        androidEnhancedCameraService?.let { cameraService ->
            val capabilities = cameraService.getCapabilities()
            result.success(capabilities)
        } ?: result.error("CAMERA_UNAVAILABLE", "Enhanced camera service not available", null)
    }

    private fun measureCameraDistance(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any> ?: emptyMap()
        val fromPoint = args["fromPoint"] as? Map<String, Double> ?: emptyMap()
        val toPoint = args["toPoint"] as? Map<String, Double> ?: emptyMap()

        if (fromPoint.isEmpty() || toPoint.isEmpty()) {
            result.error("INVALID_ARGS", "Invalid arguments for camera distance measurement", null)
            return
        }

        androidEnhancedCameraService?.let { cameraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, distanceData) = cameraService.measureDepthDistance(fromPoint, toPoint)
                    if (success) {
                        result.success(distanceData)
                    } else {
                        result.error("MEASUREMENT_FAILED", "Failed to measure camera distance", distanceData)
                    }
                }
            }.onFailure { error ->
                result.error("MEASUREMENT_ERROR", "Distance measurement error: ${error.message}", null)
            }
        } ?: result.error("CAMERA_UNAVAILABLE", "Enhanced camera service not available", null)
    }

    // MARK: - Chiroptera (Audio Sonar) Methods

    private fun initializeChiroptera(call: MethodCall, result: Result) {
        val config = call.arguments as? Map<String, Any> ?: emptyMap()

        androidChiropteraService?.let { chiropteraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, capabilities) = chiropteraService.initialize(config)
                    if (success) {
                        result.success(capabilities)
                    } else {
                        result.error("CHIROPTERA_INIT_FAILED", "Failed to initialize Chiroptera sensor", capabilities)
                    }
                }
            }.onFailure { error ->
                result.error("CHIROPTERA_INIT_ERROR", "Chiroptera initialization error: ${error.message}", null)
            }
        } ?: result.error("CHIROPTERA_UNAVAILABLE", "Chiroptera service not available", null)
    }

    private fun startChiropteraSession(result: Result) {
        androidChiropteraService?.let { chiropteraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, error) = chiropteraService.startSession()
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("CHIROPTERA_SESSION_FAILED", error ?: "Unknown error", null)
                    }
                }
            }.onFailure { error ->
                result.error("CHIROPTERA_SESSION_ERROR", "Chiroptera session error: ${error.message}", null)
            }
        } ?: result.error("CHIROPTERA_UNAVAILABLE", "Chiroptera service not available", null)
    }

    private fun stopChiropteraSession(result: Result) {
        androidChiropteraService?.let { chiropteraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, error) = chiropteraService.stopSession()
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("CHIROPTERA_SESSION_FAILED", error ?: "Unknown error", null)
                    }
                }
            }.onFailure { error ->
                result.error("CHIROPTERA_SESSION_ERROR", "Chiroptera session error: ${error.message}", null)
            }
        } ?: result.error("CHIROPTERA_UNAVAILABLE", "Chiroptera service not available", null)
    }

    private fun performChiropteraPing(call: MethodCall, result: Result) {
        val direction = call.arguments as? Map<String, Double> ?: mapOf("x" to 0.0, "y" to 0.0, "z" to 1.0)

        androidChiropteraService?.let { chiropteraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, data) = chiropteraService.performSonarPing(direction)
                    if (success) {
                        result.success(data)
                    } else {
                        result.error("CHIROPTERA_PING_FAILED", "Failed to perform Chiroptera ping", data)
                    }
                }
            }.onFailure { error ->
                result.error("CHIROPTERA_PING_ERROR", "Chiroptera ping error: ${error.message}", null)
            }
        } ?: result.error("CHIROPTERA_UNAVAILABLE", "Chiroptera service not available", null)
    }

    private fun measureChiropteraDistance(call: MethodCall, result: Result) {
        val parameters = call.arguments as? Map<String, Any> ?: emptyMap()

        androidChiropteraService?.let { chiropteraService ->
            kotlin.runCatching {
                kotlinx.coroutines.runBlocking {
                    val (success, data) = chiropteraService.measureDistance(parameters)
                    if (success) {
                        result.success(data)
                    } else {
                        result.error("CHIROPTERA_MEASUREMENT_FAILED", "Failed to measure Chiroptera distance", data)
                    }
                }
            }.onFailure { error ->
                result.error("CHIROPTERA_MEASUREMENT_ERROR", "Chiroptera measurement error: ${error.message}", null)
            }
        } ?: result.error("CHIROPTERA_UNAVAILABLE", "Chiroptera service not available", null)
    }

    private fun getChiropteraCapabilities(result: Result) {
        androidChiropteraService?.let { chiropteraService ->
            val capabilities = chiropteraService.getCapabilities()
            result.success(capabilities)
        } ?: result.error("CHIROPTERA_UNAVAILABLE", "Chiroptera service not available", null)
    }
}
