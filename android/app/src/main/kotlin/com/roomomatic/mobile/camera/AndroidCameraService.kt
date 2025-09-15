// 📸 Room-O-Matic Mobile: Android CameraX Service
// High-performance camera integration using CameraX for room scanning

package com.roomomatic.mobile.camera

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.ImageFormat
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.os.Build
import android.util.Log
import android.util.Size
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import java.nio.ByteBuffer
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs

class AndroidCameraService(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner
) {
    companion object {
        private const val TAG = "AndroidCameraService"
        private const val RATIO_4_3_VALUE = 4.0 / 3.0
        private const val RATIO_16_9_VALUE = 16.0 / 9.0
    }

    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var imageCapture: ImageCapture? = null
    private var imageAnalyzer: ImageAnalysis? = null
    private var preview: Preview? = null

    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Camera frame stream
    private val _frameStream = MutableSharedFlow<CameraFrameData>(
        replay = 0,
        extraBufferCapacity = 10
    )
    val frameStream: Flow<CameraFrameData> = _frameStream.asSharedFlow()

    // Current configuration
    private var currentConfiguration: CameraConfigurationData? = null
    private var isInitialized = false
    private var isPreviewStarted = false

    // Camera session management
    private var currentScanSession: CameraScanSessionData? = null

    suspend fun initialize(configuration: CameraConfigurationData): Boolean {
        return withContext(Dispatchers.Main) {
            try {
                Log.d(TAG, "Initializing camera with configuration: $configuration")

                // Check permissions
                if (!hasCameraPermission()) {
                    Log.e(TAG, "Camera permission not granted")
                    return@withContext false
                }

                // Get camera provider
                cameraProvider = ProcessCameraProvider.getInstance(context).get()

                // Validate and store configuration
                if (!isConfigurationSupported(configuration)) {
                    Log.e(TAG, "Camera configuration not supported")
                    return@withContext false
                }

                currentConfiguration = configuration
                setupCamera(configuration)

                isInitialized = true
                Log.d(TAG, "Camera initialized successfully")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Camera initialization failed", e)
                false
            }
        }
    }

    suspend fun isCameraAvailable(): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
                val cameraIds = cameraManager.cameraIdList
                cameraIds.isNotEmpty()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to check camera availability", e)
                false
            }
        }
    }

    suspend fun getAvailableCameras(): List<CameraInfoData> {
        return withContext(Dispatchers.IO) {
            try {
                val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
                val cameras = mutableListOf<CameraInfoData>()

                for (cameraId in cameraManager.cameraIdList) {
                    val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                    val cameraInfo = createCameraInfo(cameraId, characteristics)
                    cameras.add(cameraInfo)
                }

                cameras
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get available cameras", e)
                emptyList()
            }
        }
    }

    private fun createCameraInfo(cameraId: String, characteristics: CameraCharacteristics): CameraInfoData {
        val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
        val lensDirection = when (lensFacing) {
            CameraCharacteristics.LENS_FACING_FRONT -> "front"
            CameraCharacteristics.LENS_FACING_BACK -> "back"
            CameraCharacteristics.LENS_FACING_EXTERNAL -> "external"
            else -> "back"
        }

        val configMap = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
        val outputSizes = configMap?.getOutputSizes(ImageFormat.YUV_420_888) ?: emptyArray()
        val supportedResolutions = outputSizes.map { size ->
            when {
                size.width >= 3840 -> "ultra"
                size.width >= 1920 -> "high"
                size.width >= 1280 -> "medium"
                else -> "low"
            }
        }.distinct()

        // Check depth capabilities
        val availableCapabilities = characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES)
        val supportsDepthData = availableCapabilities?.contains(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT) == true

        // Get zoom range
        val maxZoom = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1.0f
        } else {
            characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1.0f
        }

        return CameraInfoData(
            id = cameraId,
            lensDirection = lensDirection,
            name = "Camera $cameraId",
            supportedResolutions = supportedResolutions,
            supportsDepthData = supportsDepthData,
            supportsFaceDetection = true, // Most modern Android cameras support this
            supportsObjectDetection = true,
            minZoom = 1.0,
            maxZoom = maxZoom.toDouble()
        )
    }

    suspend fun startPreview(): Boolean {
        return withContext(Dispatchers.Main) {
            try {
                if (!isInitialized) {
                    Log.e(TAG, "Camera not initialized")
                    return@withContext false
                }

                val configuration = currentConfiguration ?: return@withContext false
                bindPreview(configuration)

                isPreviewStarted = true
                Log.d(TAG, "Camera preview started")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start preview", e)
                false
            }
        }
    }

    suspend fun stopPreview(): Boolean {
        return withContext(Dispatchers.Main) {
            try {
                cameraProvider?.unbindAll()
                isPreviewStarted = false
                Log.d(TAG, "Camera preview stopped")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop preview", e)
                false
            }
        }
    }

    suspend fun startScanSession(configuration: CameraConfigurationData): CameraScanSessionData {
        return withContext(Dispatchers.Main) {
            try {
                val sessionId = UUID.randomUUID().toString()
                val session = CameraScanSessionData(
                    sessionId = sessionId,
                    startTime = System.currentTimeMillis(),
                    configuration = configuration,
                    status = "scanning"
                )

                currentScanSession = session

                // Setup frame analysis
                setupFrameAnalysis(configuration)

                Log.d(TAG, "Camera scan session started: $sessionId")
                session
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start scan session", e)
                throw e
            }
        }
    }

    suspend fun stopScanSession(): Boolean {
        return withContext(Dispatchers.Main) {
            try {
                currentScanSession?.let { session ->
                    currentScanSession = session.copy(
                        endTime = System.currentTimeMillis(),
                        status = "completed"
                    )
                }

                Log.d(TAG, "Camera scan session stopped")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop scan session", e)
                false
            }
        }
    }

    suspend fun captureFrame(): CameraFrameData? {
        return withContext(Dispatchers.IO) {
            try {
                // For now, return a mock frame - in real implementation,
                // this would capture from the current camera stream
                val frameId = UUID.randomUUID().toString()
                CameraFrameData(
                    frameId = frameId,
                    timestamp = System.currentTimeMillis(),
                    format = "yuv420",
                    width = 1920,
                    height = 1080,
                    data = ByteArray(1920 * 1080 * 3 / 2) // YUV420 size
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to capture frame", e)
                null
            }
        }
    }

    private fun setupCamera(configuration: CameraConfigurationData) {
        try {
            // Create use cases
            preview = createPreview(configuration)
            imageCapture = createImageCapture(configuration)
            imageAnalyzer = createImageAnalysis(configuration)

            Log.d(TAG, "Camera use cases created")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup camera", e)
            throw e
        }
    }

    private fun bindPreview(configuration: CameraConfigurationData) {
        try {
            val cameraProvider = this.cameraProvider ?: throw IllegalStateException("Camera provider not initialized")

            // Unbind any existing use cases
            cameraProvider.unbindAll()

            // Select camera
            val cameraSelector = CameraSelector.Builder()
                .requireLensFacing(getCameraLensFacing(configuration.lensDirection))
                .build()

            // Bind use cases
            camera = cameraProvider.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                preview,
                imageCapture,
                imageAnalyzer
            )

            Log.d(TAG, "Camera bound to lifecycle")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to bind camera", e)
            throw e
        }
    }

    private fun createPreview(configuration: CameraConfigurationData): Preview {
        val targetResolution = getTargetResolution(configuration.resolution)

        return Preview.Builder()
            .setTargetResolution(targetResolution)
            .build()
    }

    private fun createImageCapture(configuration: CameraConfigurationData): ImageCapture {
        val targetResolution = getTargetResolution(configuration.resolution)

        return ImageCapture.Builder()
            .setTargetResolution(targetResolution)
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .build()
    }

    private fun createImageAnalysis(configuration: CameraConfigurationData): ImageAnalysis {
        val targetResolution = getTargetResolution(configuration.resolution)

        return ImageAnalysis.Builder()
            .setTargetResolution(targetResolution)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
    }

    private fun setupFrameAnalysis(configuration: CameraConfigurationData) {
        imageAnalyzer?.setAnalyzer(cameraExecutor) { imageProxy ->
            try {
                val frameData = processImageProxy(imageProxy)
                frameData?.let { frame ->
                    coroutineScope.launch {
                        _frameStream.emit(frame)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Frame analysis failed", e)
            } finally {
                imageProxy.close()
            }
        }
    }

    private fun processImageProxy(imageProxy: ImageProxy): CameraFrameData? {
        return try {
            val frameId = UUID.randomUUID().toString()
            val planes = imageProxy.planes
            val yBuffer = planes[0].buffer
            val uBuffer = planes[1].buffer
            val vBuffer = planes[2].buffer

            val ySize = yBuffer.remaining()
            val uSize = uBuffer.remaining()
            val vSize = vBuffer.remaining()

            val data = ByteArray(ySize + uSize + vSize)
            yBuffer.get(data, 0, ySize)
            vBuffer.get(data, ySize, vSize)
            uBuffer.get(data, ySize + vSize, uSize)

            CameraFrameData(
                frameId = frameId,
                timestamp = System.currentTimeMillis(),
                format = "yuv420",
                width = imageProxy.width,
                height = imageProxy.height,
                data = data
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to process image proxy", e)
            null
        }
    }

    private fun getTargetResolution(resolution: String): Size {
        return when (resolution) {
            "ultra" -> Size(3840, 2160)
            "high" -> Size(1920, 1080)
            "medium" -> Size(1280, 720)
            "low" -> Size(640, 480)
            else -> Size(1920, 1080)
        }
    }

    private fun getCameraLensFacing(lensDirection: String): Int {
        return when (lensDirection) {
            "front" -> CameraSelector.LENS_FACING_FRONT
            "back" -> CameraSelector.LENS_FACING_BACK
            else -> CameraSelector.LENS_FACING_BACK
        }
    }

    private fun isConfigurationSupported(configuration: CameraConfigurationData): Boolean {
        // Basic validation - in real implementation, this would check against
        // camera capabilities more thoroughly
        return true
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    fun dispose() {
        try {
            cameraProvider?.unbindAll()
            cameraExecutor.shutdown()
            coroutineScope.cancel()
            isInitialized = false
            isPreviewStarted = false
            Log.d(TAG, "Camera service disposed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to dispose camera service", e)
        }
    }

    // Camera capabilities
    suspend fun getCameraCapabilities(): CameraCapabilitiesData {
        return withContext(Dispatchers.IO) {
            try {
                val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
                val backCameraId = getBackCameraId(cameraManager)

                if (backCameraId != null) {
                    val characteristics = cameraManager.getCameraCharacteristics(backCameraId)
                    createCameraCapabilities(characteristics)
                } else {
                    // Fallback capabilities
                    CameraCapabilitiesData(
                        supportedResolutions = listOf("low", "medium", "high"),
                        supportedFormats = listOf("yuv420"),
                        supportedFlashModes = listOf("off", "on", "auto"),
                        supportedExposureModes = listOf("auto"),
                        supportedFocusModes = listOf("auto", "continuous"),
                        supportsImageStabilization = false,
                        supportsAutoFocus = true,
                        supportsDepthData = false,
                        supportsFaceDetection = true,
                        supportsObjectDetection = true,
                        minZoom = 1.0,
                        maxZoom = 4.0,
                        supportedFrameRates = listOf(30)
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to get camera capabilities", e)
                CameraCapabilitiesData(
                    supportedResolutions = listOf("medium"),
                    supportedFormats = listOf("yuv420"),
                    supportedFlashModes = listOf("off"),
                    supportedExposureModes = listOf("auto"),
                    supportedFocusModes = listOf("auto"),
                    supportsImageStabilization = false,
                    supportsAutoFocus = true,
                    supportsDepthData = false,
                    supportsFaceDetection = false,
                    supportsObjectDetection = false,
                    minZoom = 1.0,
                    maxZoom = 1.0,
                    supportedFrameRates = listOf(30)
                )
            }
        }
    }

    private fun getBackCameraId(cameraManager: CameraManager): String? {
        return try {
            cameraManager.cameraIdList.find { cameraId ->
                val characteristics = cameraManager.getCameraCharacteristics(cameraId)
                characteristics.get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to find back camera", e)
            null
        }
    }

    private fun createCameraCapabilities(characteristics: CameraCharacteristics): CameraCapabilitiesData {
        val configMap = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
        val outputSizes = configMap?.getOutputSizes(ImageFormat.YUV_420_888) ?: emptyArray()

        val supportedResolutions = mutableListOf<String>()
        outputSizes.forEach { size ->
            when {
                size.width >= 3840 && !supportedResolutions.contains("ultra") -> supportedResolutions.add("ultra")
                size.width >= 1920 && !supportedResolutions.contains("high") -> supportedResolutions.add("high")
                size.width >= 1280 && !supportedResolutions.contains("medium") -> supportedResolutions.add("medium")
                size.width >= 640 && !supportedResolutions.contains("low") -> supportedResolutions.add("low")
            }
        }

        val availableCapabilities = characteristics.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES) ?: intArrayOf()
        val supportsDepthData = availableCapabilities.contains(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_DEPTH_OUTPUT)

        val maxZoom = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1.0f
        } else {
            characteristics.get(CameraCharacteristics.SCALER_AVAILABLE_MAX_DIGITAL_ZOOM) ?: 1.0f
        }

        return CameraCapabilitiesData(
            supportedResolutions = supportedResolutions.ifEmpty { listOf("medium") },
            supportedFormats = listOf("yuv420", "nv21", "rgba8888"),
            supportedFlashModes = listOf("off", "on", "auto", "torch"),
            supportedExposureModes = listOf("auto", "manual"),
            supportedFocusModes = listOf("auto", "continuous", "macro"),
            supportsImageStabilization = true,
            supportsAutoFocus = true,
            supportsDepthData = supportsDepthData,
            supportsFaceDetection = true,
            supportsObjectDetection = true,
            minZoom = 1.0,
            maxZoom = maxZoom.toDouble(),
            supportedFrameRates = listOf(15, 24, 30, 60)
        )
    }
}

// Data classes for camera operations
data class CameraConfigurationData(
    val lensDirection: String,
    val resolution: String,
    val frameRate: Int,
    val enableImageStabilization: Boolean,
    val enableAutoFocus: Boolean,
    val flashMode: String,
    val exposureMode: String,
    val focusMode: String,
    val enableDepthData: Boolean,
    val format: String
)

data class CameraFrameData(
    val frameId: String,
    val timestamp: Long,
    val format: String,
    val width: Int,
    val height: Int,
    val data: ByteArray
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as CameraFrameData

        if (frameId != other.frameId) return false
        if (timestamp != other.timestamp) return false
        if (format != other.format) return false
        if (width != other.width) return false
        if (height != other.height) return false
        if (!data.contentEquals(other.data)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = frameId.hashCode()
        result = 31 * result + timestamp.hashCode()
        result = 31 * result + format.hashCode()
        result = 31 * result + width
        result = 31 * result + height
        result = 31 * result + data.contentHashCode()
        return result
    }
}

data class CameraScanSessionData(
    val sessionId: String,
    val startTime: Long,
    val endTime: Long? = null,
    val configuration: CameraConfigurationData,
    val status: String
)

data class CameraInfoData(
    val id: String,
    val lensDirection: String,
    val name: String,
    val supportedResolutions: List<String>,
    val supportsDepthData: Boolean,
    val supportsFaceDetection: Boolean,
    val supportsObjectDetection: Boolean,
    val minZoom: Double,
    val maxZoom: Double
)

data class CameraCapabilitiesData(
    val supportedResolutions: List<String>,
    val supportedFormats: List<String>,
    val supportedFlashModes: List<String>,
    val supportedExposureModes: List<String>,
    val supportedFocusModes: List<String>,
    val supportsImageStabilization: Boolean,
    val supportsAutoFocus: Boolean,
    val supportsDepthData: Boolean,
    val supportsFaceDetection: Boolean,
    val supportsObjectDetection: Boolean,
    val minZoom: Double,
    val maxZoom: Double,
    val supportedFrameRates: List<Int>
)
