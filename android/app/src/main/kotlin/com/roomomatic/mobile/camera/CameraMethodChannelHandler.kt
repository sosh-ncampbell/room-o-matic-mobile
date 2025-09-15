// 📸 Room-O-Matic Mobile: Android Camera Method Channel Handler
// Platform channel bridge for camera operations

package com.roomomatic.mobile.camera

import android.content.Context
import android.util.Log
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class CameraMethodChannelHandler(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "CameraMethodChannelHandler"
        const val CHANNEL_NAME = "com.roomomatic.camera"
    }

    private var cameraService: AndroidCameraService? = null
    private val handlerScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "Method called: ${call.method}")

        when (call.method) {
            "initialize" -> initialize(call, result)
            "isCameraAvailable" -> isCameraAvailable(result)
            "getAvailableCameras" -> getAvailableCameras(result)
            "startPreview" -> startPreview(result)
            "stopPreview" -> stopPreview(result)
            "startScanSession" -> startScanSession(call, result)
            "stopScanSession" -> stopScanSession(result)
            "captureFrame" -> captureFrame(result)
            "getCameraCapabilities" -> getCameraCapabilities(result)
            "updateConfiguration" -> updateConfiguration(call, result)
            "getCurrentConfiguration" -> getCurrentConfiguration(result)
            "isConfigurationSupported" -> isConfigurationSupported(call, result)
            "setFocusPoint" -> setFocusPoint(call, result)
            "setExposurePoint" -> setExposurePoint(call, result)
            "setZoomLevel" -> setZoomLevel(call, result)
            "getZoomLevel" -> getZoomLevel(result)
            "toggleFlash" -> toggleFlash(result)
            "setFlashMode" -> setFlashMode(call, result)
            "isFlashAvailable" -> isFlashAvailable(result)
            "getCameraPermissionStatus" -> getCameraPermissionStatus(result)
            "requestCameraPermission" -> requestCameraPermission(result)
            "dispose" -> dispose(result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val configMap = call.argument<Map<String, Any>>("configuration")
                if (configMap == null) {
                    result.error("INVALID_ARGUMENT", "Configuration is required", null)
                    return@launch
                }

                val configuration = parseCameraConfiguration(configMap)

                // Create camera service if not exists
                if (cameraService == null) {
                    cameraService = AndroidCameraService(context, lifecycleOwner)
                }

                val success = cameraService!!.initialize(configuration)
                if (success) {
                    result.success(true)
                } else {
                    result.error("INITIALIZATION_FAILED", "Failed to initialize camera", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Initialize failed", e)
                result.error("INITIALIZATION_ERROR", e.message, null)
            }
        }
    }

    private fun isCameraAvailable(result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val service = getCameraService()
                val isAvailable = service.isCameraAvailable()
                result.success(isAvailable)
            } catch (e: Exception) {
                Log.e(TAG, "isCameraAvailable failed", e)
                result.error("CAMERA_CHECK_ERROR", e.message, null)
            }
        }
    }

    private fun getAvailableCameras(result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val service = getCameraService()
                val cameras = service.getAvailableCameras()
                val cameraList = cameras.map { camera ->
                    mapOf(
                        "id" to camera.id,
                        "lensDirection" to camera.lensDirection,
                        "name" to camera.name,
                        "supportedResolutions" to camera.supportedResolutions,
                        "supportsDepthData" to camera.supportsDepthData,
                        "supportsFaceDetection" to camera.supportsFaceDetection,
                        "supportsObjectDetection" to camera.supportsObjectDetection,
                        "minZoom" to camera.minZoom,
                        "maxZoom" to camera.maxZoom
                    )
                }
                result.success(cameraList)
            } catch (e: Exception) {
                Log.e(TAG, "getAvailableCameras failed", e)
                result.error("CAMERA_LIST_ERROR", e.message, null)
            }
        }
    }

    private fun startPreview(result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val service = cameraService
                if (service == null) {
                    result.error("NOT_INITIALIZED", "Camera not initialized", null)
                    return@launch
                }

                val success = service.startPreview()
                result.success(success)
            } catch (e: Exception) {
                Log.e(TAG, "startPreview failed", e)
                result.error("PREVIEW_START_ERROR", e.message, null)
            }
        }
    }

    private fun stopPreview(result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val service = cameraService
                if (service == null) {
                    result.error("NOT_INITIALIZED", "Camera not initialized", null)
                    return@launch
                }

                val success = service.stopPreview()
                result.success(success)
            } catch (e: Exception) {
                Log.e(TAG, "stopPreview failed", e)
                result.error("PREVIEW_STOP_ERROR", e.message, null)
            }
        }
    }

    private fun startScanSession(call: MethodCall, result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val service = cameraService
                if (service == null) {
                    result.error("NOT_INITIALIZED", "Camera not initialized", null)
                    return@launch
                }

                val configMap = call.argument<Map<String, Any>>("configuration")
                if (configMap == null) {
                    result.error("INVALID_ARGUMENT", "Configuration is required", null)
                    return@launch
                }

                val configuration = parseCameraConfiguration(configMap)
                val session = service.startScanSession(configuration)

                val sessionMap = mapOf(
                    "sessionId" to session.sessionId,
                    "startTime" to session.startTime,
                    "endTime" to session.endTime,
                    "configuration" to serializeCameraConfiguration(session.configuration),
                    "status" to session.status
                )

                result.success(sessionMap)
            } catch (e: Exception) {
                Log.e(TAG, "startScanSession failed", e)
                result.error("SCAN_SESSION_START_ERROR", e.message, null)
            }
        }
    }

    private fun stopScanSession(result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val service = cameraService
                if (service == null) {
                    result.error("NOT_INITIALIZED", "Camera not initialized", null)
                    return@launch
                }

                val success = service.stopScanSession()
                result.success(success)
            } catch (e: Exception) {
                Log.e(TAG, "stopScanSession failed", e)
                result.error("SCAN_SESSION_STOP_ERROR", e.message, null)
            }
        }
    }

    private fun captureFrame(result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val service = cameraService
                if (service == null) {
                    result.error("NOT_INITIALIZED", "Camera not initialized", null)
                    return@launch
                }

                val frame = service.captureFrame()
                if (frame != null) {
                    val frameMap = mapOf(
                        "frameId" to frame.frameId,
                        "timestamp" to frame.timestamp,
                        "format" to frame.format,
                        "width" to frame.width,
                        "height" to frame.height,
                        "data" to frame.data
                    )
                    result.success(frameMap)
                } else {
                    result.error("CAPTURE_FAILED", "Failed to capture frame", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "captureFrame failed", e)
                result.error("FRAME_CAPTURE_ERROR", e.message, null)
            }
        }
    }

    private fun getCameraCapabilities(result: MethodChannel.Result) {
        handlerScope.launch {
            try {
                val service = getCameraService()
                val capabilities = service.getCameraCapabilities()

                val capabilitiesMap = mapOf(
                    "supportedResolutions" to capabilities.supportedResolutions,
                    "supportedFormats" to capabilities.supportedFormats,
                    "supportedFlashModes" to capabilities.supportedFlashModes,
                    "supportedExposureModes" to capabilities.supportedExposureModes,
                    "supportedFocusModes" to capabilities.supportedFocusModes,
                    "supportsImageStabilization" to capabilities.supportsImageStabilization,
                    "supportsAutoFocus" to capabilities.supportsAutoFocus,
                    "supportsDepthData" to capabilities.supportsDepthData,
                    "supportsFaceDetection" to capabilities.supportsFaceDetection,
                    "supportsObjectDetection" to capabilities.supportsObjectDetection,
                    "minZoom" to capabilities.minZoom,
                    "maxZoom" to capabilities.maxZoom,
                    "supportedFrameRates" to capabilities.supportedFrameRates
                )

                result.success(capabilitiesMap)
            } catch (e: Exception) {
                Log.e(TAG, "getCameraCapabilities failed", e)
                result.error("CAPABILITIES_ERROR", e.message, null)
            }
        }
    }

    private fun updateConfiguration(call: MethodCall, result: MethodChannel.Result) {
        // For now, return success - in real implementation, this would update the camera configuration
        result.success(true)
    }

    private fun getCurrentConfiguration(result: MethodChannel.Result) {
        // For now, return null - in real implementation, this would return the current configuration
        result.success(null)
    }

    private fun isConfigurationSupported(call: MethodCall, result: MethodChannel.Result) {
        // For now, return true - in real implementation, this would check if configuration is supported
        result.success(true)
    }

    private fun setFocusPoint(call: MethodCall, result: MethodChannel.Result) {
        // Camera focus control implementation would go here
        result.success(true)
    }

    private fun setExposurePoint(call: MethodCall, result: MethodChannel.Result) {
        // Camera exposure control implementation would go here
        result.success(true)
    }

    private fun setZoomLevel(call: MethodCall, result: MethodChannel.Result) {
        // Camera zoom control implementation would go here
        result.success(true)
    }

    private fun getZoomLevel(result: MethodChannel.Result) {
        // Return current zoom level - for now return 1.0 (no zoom)
        result.success(1.0)
    }

    private fun toggleFlash(result: MethodChannel.Result) {
        // Flash toggle implementation would go here
        result.success(true)
    }

    private fun setFlashMode(call: MethodCall, result: MethodChannel.Result) {
        // Flash mode setting implementation would go here
        result.success(true)
    }

    private fun isFlashAvailable(result: MethodChannel.Result) {
        // Flash availability check implementation would go here
        result.success(true)
    }

    private fun getCameraPermissionStatus(result: MethodChannel.Result) {
        // Return permission status - for now return "granted"
        result.success("granted")
    }

    private fun requestCameraPermission(result: MethodChannel.Result) {
        // Permission request implementation would go here
        result.success("granted")
    }

    private fun dispose(result: MethodChannel.Result) {
        try {
            cameraService?.dispose()
            cameraService = null
            handlerScope.cancel()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "dispose failed", e)
            result.error("DISPOSE_ERROR", e.message, null)
        }
    }

    private fun getCameraService(): AndroidCameraService {
        return cameraService ?: AndroidCameraService(context, lifecycleOwner).also {
            cameraService = it
        }
    }

    private fun parseCameraConfiguration(configMap: Map<String, Any>): CameraConfigurationData {
        return CameraConfigurationData(
            lensDirection = configMap["lensDirection"] as? String ?: "back",
            resolution = configMap["resolution"] as? String ?: "high",
            frameRate = configMap["frameRate"] as? Int ?: 30,
            enableImageStabilization = configMap["enableImageStabilization"] as? Boolean ?: true,
            enableAutoFocus = configMap["enableAutoFocus"] as? Boolean ?: true,
            flashMode = configMap["flashMode"] as? String ?: "off",
            exposureMode = configMap["exposureMode"] as? String ?: "auto",
            focusMode = configMap["focusMode"] as? String ?: "auto",
            enableDepthData = configMap["enableDepthData"] as? Boolean ?: false,
            format = configMap["format"] as? String ?: "yuv420"
        )
    }

    private fun serializeCameraConfiguration(config: CameraConfigurationData): Map<String, Any> {
        return mapOf(
            "lensDirection" to config.lensDirection,
            "resolution" to config.resolution,
            "frameRate" to config.frameRate,
            "enableImageStabilization" to config.enableImageStabilization,
            "enableAutoFocus" to config.enableAutoFocus,
            "flashMode" to config.flashMode,
            "exposureMode" to config.exposureMode,
            "focusMode" to config.focusMode,
            "enableDepthData" to config.enableDepthData,
            "format" to config.format
        )
    }
}
