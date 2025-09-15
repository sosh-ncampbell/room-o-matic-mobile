package com.roomomatic.sensors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.*

/**
 * Android sensor fusion service for combining multiple sensor inputs
 * Integrates ToF, IMU, magnetometer, and other available sensors
 */
class AndroidSensorFusionService(
    private val context: Context,
    private val methodChannel: MethodChannel,
    private val tofManager: ToFSensorManager
) : SensorEventListener {

    companion object {
        private const val TAG = "AndroidSensorFusion"
        private const val FUSION_UPDATE_RATE = 60 // Hz
        private const val KALMAN_PROCESS_NOISE = 0.01f
        private const val KALMAN_MEASUREMENT_NOISE = 0.1f
    }

    private val sensorManager: SensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val fusionScope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    // Sensor instances
    private var accelerometer: Sensor? = null
    private var gyroscope: Sensor? = null
    private var magnetometer: Sensor? = null
    private var gravitySensor: Sensor? = null
    private var rotationVector: Sensor? = null

    // Sensor data storage
    private var accelerometerData = FloatArray(3)
    private var gyroscopeData = FloatArray(3)
    private var magnetometerData = FloatArray(3)
    private var gravityData = FloatArray(3)
    private var rotationData = FloatArray(4)

    // Fusion sessions
    private val fusionSessions = ConcurrentHashMap<String, SensorFusionSession>()
    private var isInitialized = false

    // Kalman filter for position estimation
    private val kalmanFilter = KalmanFilter3D()

    init {
        initializeSensorFusion()
    }

    /**
     * Initialize sensor fusion service
     */
    private fun initializeSensorFusion() {
        try {
            // Get available sensors
            accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            gyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
            magnetometer = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
            gravitySensor = sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY)
            rotationVector = sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

            isInitialized = true
            Log.i(TAG, "Sensor fusion service initialized with ${getAvailableSensors().size} sensors")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize sensor fusion: ${e.message}")
        }
    }

    /**
     * Get available sensors and their capabilities
     */
    fun getCapabilities(): Map<String, Any> {
        val availableSensors = getAvailableSensors()
        val tofCapabilities = tofManager.getCapabilities()

        return mapOf<String, Any>(
            "hasAccelerometer" to (accelerometer != null),
            "hasGyroscope" to (gyroscope != null),
            "hasMagnetometer" to (magnetometer != null),
            "hasGravitySensor" to (gravitySensor != null),
            "hasRotationVector" to (rotationVector != null),
            "hasToF" to (tofCapabilities["hasToF"] ?: false),
            "supportsSensorFusion" to true,
            "maxUpdateRate" to FUSION_UPDATE_RATE,
            "availableSensors" to availableSensors,
            "fusionAlgorithms" to listOf("kalman", "complementary", "madgwick"),
            "deviceModel" to getDeviceModel()
        )
    }

    /**
     * Start sensor fusion session
     */
    fun startSensorFusion(sessionId: String, sensors: List<String>, config: Map<String, Any>): Map<String, Any> {
        if (!isInitialized) {
            return mapOf(
                "success" to false,
                "error" to "Sensor fusion not initialized"
            )
        }

        try {
            val algorithm = config["fusionAlgorithm"] as? String ?: "kalman"
            val updateRate = (config["updateRate"] as? Number)?.toInt() ?: FUSION_UPDATE_RATE
            val confidence = (config["confidence"] as? Number)?.toFloat() ?: 0.8f

            val session = SensorFusionSession(
                sessionId = sessionId,
                activeSensors = sensors.toSet(),
                algorithm = algorithm,
                updateRate = updateRate,
                targetConfidence = confidence,
                startTime = System.currentTimeMillis()
            )

            fusionSessions[sessionId] = session

            // Register sensor listeners
            registerSensorListeners(session)

            // Start ToF if included
            if (sensors.contains("tof")) {
                tofManager.startToFSession(sessionId, config)
            }

            // Start fusion processing
            startFusionProcessing(session)

            Log.i(TAG, "Sensor fusion session started: $sessionId with sensors: $sensors")

            return mapOf(
                "success" to true,
                "sessionId" to sessionId,
                "activeSensors" to sensors,
                "algorithm" to algorithm,
                "updateRate" to updateRate
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start sensor fusion: ${e.message}")
            return mapOf(
                "success" to false,
                "error" to e.message.toString()
            )
        }
    }

    /**
     * Stop sensor fusion session
     */
    fun stopSensorFusion(sessionId: String): Map<String, Any> {
        return try {
            val session = fusionSessions.remove(sessionId)
            if (session != null) {
                // Stop ToF if it was active
                if (session.activeSensors.contains("tof")) {
                    tofManager.stopToFSession(sessionId)
                }

                // Unregister sensors if this was the last session
                if (fusionSessions.isEmpty()) {
                    unregisterSensorListeners()
                }

                Log.i(TAG, "Sensor fusion session stopped: $sessionId")
                mapOf(
                    "success" to true,
                    "sessionId" to sessionId,
                    "duration" to (System.currentTimeMillis() - session.startTime)
                )
            } else {
                mapOf(
                    "success" to false,
                    "error" to "Session not found: $sessionId"
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop sensor fusion: ${e.message}")
            mapOf(
                "success" to false,
                "error" to e.message.toString()
            )
        }
    }

    /**
     * Get current fusion data
     */
    fun getFusionData(sessionId: String): Map<String, Any>? {
        val session = fusionSessions[sessionId] ?: return null

        return try {
            val fusedPosition = kalmanFilter.getCurrentPosition()
            val fusedVelocity = kalmanFilter.getCurrentVelocity()
            val orientation = calculateOrientation()
            val confidence = calculateFusionConfidence(session)

            val data = mutableMapOf<String, Any>(
                "sessionId" to sessionId,
                "timestamp" to System.currentTimeMillis(),
                "fusedPosition" to mapOf(
                    "x" to fusedPosition[0],
                    "y" to fusedPosition[1],
                    "z" to fusedPosition[2]
                ),
                "fusedVelocity" to mapOf(
                    "x" to fusedVelocity[0],
                    "y" to fusedVelocity[1],
                    "z" to fusedVelocity[2]
                ),
                "orientation" to mapOf(
                    "pitch" to orientation[0],
                    "roll" to orientation[1],
                    "yaw" to orientation[2]
                ),
                "confidence" to confidence,
                "activeSensors" to session.activeSensors.toList(),
                "algorithm" to session.algorithm
            )

            // Add IMU data if available
            if (session.activeSensors.contains("imu") || session.activeSensors.contains("accelerometer")) {
                data["imuData"] = mapOf(
                    "acceleration" to mapOf(
                        "x" to accelerometerData[0],
                        "y" to accelerometerData[1],
                        "z" to accelerometerData[2]
                    ),
                    "gyroscope" to mapOf(
                        "x" to gyroscopeData[0],
                        "y" to gyroscopeData[1],
                        "z" to gyroscopeData[2]
                    ),
                    "magnetometer" to mapOf(
                        "x" to magnetometerData[0],
                        "y" to magnetometerData[1],
                        "z" to magnetometerData[2]
                    )
                )
            }

            // Add ToF data if available
            if (session.activeSensors.contains("tof")) {
                val tofData = tofManager.getCurrentToFData(sessionId)
                if (tofData != null) {
                    data["tofData"] = tofData
                }
            }

            data
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get fusion data: ${e.message}")
            null
        }
    }

    /**
     * Register sensor listeners for fusion session
     */
    private fun registerSensorListeners(session: SensorFusionSession) {
        val samplingRate = when (session.updateRate) {
            in 1..10 -> SensorManager.SENSOR_DELAY_NORMAL
            in 11..30 -> SensorManager.SENSOR_DELAY_UI
            in 31..60 -> SensorManager.SENSOR_DELAY_GAME
            else -> SensorManager.SENSOR_DELAY_FASTEST
        }

        if (session.activeSensors.contains("accelerometer") && accelerometer != null) {
            sensorManager.registerListener(this, accelerometer, samplingRate)
        }

        if (session.activeSensors.contains("gyroscope") && gyroscope != null) {
            sensorManager.registerListener(this, gyroscope, samplingRate)
        }

        if (session.activeSensors.contains("magnetometer") && magnetometer != null) {
            sensorManager.registerListener(this, magnetometer, samplingRate)
        }

        if (session.activeSensors.contains("gravity") && gravitySensor != null) {
            sensorManager.registerListener(this, gravitySensor, samplingRate)
        }

        if (session.activeSensors.contains("rotation") && rotationVector != null) {
            sensorManager.registerListener(this, rotationVector, samplingRate)
        }
    }

    /**
     * Unregister all sensor listeners
     */
    private fun unregisterSensorListeners() {
        sensorManager.unregisterListener(this)
    }

    /**
     * Start fusion processing coroutine
     */
    private fun startFusionProcessing(session: SensorFusionSession) {
        fusionScope.launch {
            val interval = 1000L / session.updateRate

            while (fusionSessions.containsKey(session.sessionId)) {
                try {
                    processSensorFusion(session)
                    delay(interval)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in fusion processing: ${e.message}")
                }
            }
        }
    }

    /**
     * Process sensor fusion algorithms
     */
    private fun processSensorFusion(session: SensorFusionSession) {
        when (session.algorithm) {
            "kalman" -> processKalmanFusion(session)
            "complementary" -> processComplementaryFusion(session)
            "madgwick" -> processMadgwickFusion(session)
            else -> processKalmanFusion(session)
        }
    }

    /**
     * Process Kalman filter fusion
     */
    private fun processKalmanFusion(session: SensorFusionSession) {
        // Update Kalman filter with accelerometer data
        if (session.activeSensors.contains("accelerometer")) {
            kalmanFilter.predict(accelerometerData)
        }

        // Update with ToF measurements if available
        if (session.activeSensors.contains("tof")) {
            val tofData = tofManager.getCurrentToFData(session.sessionId)
            tofData?.let { data ->
                val distance = (data["distance"] as? Number)?.toFloat() ?: 0f
                kalmanFilter.update(floatArrayOf(distance, 0f, 0f))
            }
        }
    }

    /**
     * Process complementary filter fusion
     */
    private fun processComplementaryFusion(session: SensorFusionSession) {
        // Simple complementary filter implementation
        // Combines accelerometer and gyroscope data
        val alpha = 0.98f

        if (session.activeSensors.contains("accelerometer") && session.activeSensors.contains("gyroscope")) {
            // Implementation would go here
            Log.d(TAG, "Processing complementary fusion for ${session.sessionId}")
        }
    }

    /**
     * Process Madgwick filter fusion
     */
    private fun processMadgwickFusion(session: SensorFusionSession) {
        // Madgwick AHRS algorithm implementation
        // Combines accelerometer, gyroscope, and magnetometer
        Log.d(TAG, "Processing Madgwick fusion for ${session.sessionId}")
    }

    /**
     * Calculate device orientation from sensors
     */
    private fun calculateOrientation(): FloatArray {
        return if (rotationData.isNotEmpty()) {
            val rotationMatrix = FloatArray(9)
            val orientation = FloatArray(3)

            SensorManager.getRotationMatrixFromVector(rotationMatrix, rotationData)
            SensorManager.getOrientation(rotationMatrix, orientation)

            // Convert radians to degrees
            floatArrayOf(
                Math.toDegrees(orientation[1].toDouble()).toFloat(), // pitch
                Math.toDegrees(orientation[2].toDouble()).toFloat(), // roll
                Math.toDegrees(orientation[0].toDouble()).toFloat()  // yaw
            )
        } else {
            floatArrayOf(0f, 0f, 0f)
        }
    }

    /**
     * Calculate fusion confidence based on sensor availability and quality
     */
    private fun calculateFusionConfidence(session: SensorFusionSession): Float {
        var confidence = 0.5f

        // Base confidence on number of active sensors
        confidence += session.activeSensors.size * 0.1f

        // Higher confidence for specific sensor combinations
        if (session.activeSensors.contains("tof")) confidence += 0.2f
        if (session.activeSensors.contains("accelerometer") && session.activeSensors.contains("gyroscope")) {
            confidence += 0.1f
        }

        return confidence.coerceIn(0f, 1f)
    }

    /**
     * Get list of available sensors
     */
    private fun getAvailableSensors(): List<String> {
        val sensors = mutableListOf<String>()

        if (accelerometer != null) sensors.add("accelerometer")
        if (gyroscope != null) sensors.add("gyroscope")
        if (magnetometer != null) sensors.add("magnetometer")
        if (gravitySensor != null) sensors.add("gravity")
        if (rotationVector != null) sensors.add("rotation")
        if (tofManager.getCapabilities()["hasToF"] == true) sensors.add("tof")

        return sensors
    }

    /**
     * Get device model information
     */
    private fun getDeviceModel(): String {
        return "${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}"
    }

    // SensorEventListener implementation
    override fun onSensorChanged(event: SensorEvent?) {
        event?.let { sensorEvent ->
            when (sensorEvent.sensor.type) {
                Sensor.TYPE_ACCELEROMETER -> {
                    accelerometerData = sensorEvent.values.clone()
                }
                Sensor.TYPE_GYROSCOPE -> {
                    gyroscopeData = sensorEvent.values.clone()
                }
                Sensor.TYPE_MAGNETIC_FIELD -> {
                    magnetometerData = sensorEvent.values.clone()
                }
                Sensor.TYPE_GRAVITY -> {
                    gravityData = sensorEvent.values.clone()
                }
                Sensor.TYPE_ROTATION_VECTOR -> {
                    rotationData = sensorEvent.values.clone()
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        Log.d(TAG, "Sensor accuracy changed: ${sensor?.name} -> $accuracy")
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        fusionSessions.clear()
        unregisterSensorListeners()
        fusionScope.cancel()
        Log.i(TAG, "Android sensor fusion service cleaned up")
    }
}

/**
 * Data class for sensor fusion session
 */
data class SensorFusionSession(
    val sessionId: String,
    val activeSensors: Set<String>,
    val algorithm: String,
    val updateRate: Int,
    val targetConfidence: Float,
    val startTime: Long
)

/**
 * Simple 3D Kalman filter for position estimation
 */
class KalmanFilter3D {
    private val state = FloatArray(6) // [x, y, z, vx, vy, vz]
    private val covariance = Array(6) { FloatArray(6) }

    init {
        // Initialize identity covariance matrix
        for (i in 0..5) {
            covariance[i][i] = 1.0f
        }
    }

    fun predict(acceleration: FloatArray) {
        val dt = 0.01f // 10ms time step

        // Update position with velocity
        state[0] += state[3] * dt
        state[1] += state[4] * dt
        state[2] += state[5] * dt

        // Update velocity with acceleration
        state[3] += acceleration[0] * dt
        state[4] += acceleration[1] * dt
        state[5] += acceleration[2] * dt
    }

    fun update(measurement: FloatArray) {
        // Simple update - in real implementation would use full Kalman equations
        val gain = 0.1f

        state[0] = state[0] * (1 - gain) + measurement[0] * gain
        if (measurement.size > 1) state[1] = state[1] * (1 - gain) + measurement[1] * gain
        if (measurement.size > 2) state[2] = state[2] * (1 - gain) + measurement[2] * gain
    }

    fun getCurrentPosition(): FloatArray = floatArrayOf(state[0], state[1], state[2])
    fun getCurrentVelocity(): FloatArray = floatArrayOf(state[3], state[4], state[5])
}
