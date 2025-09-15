package com.roomomatic.room_o_matic_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private var sensorChannelManager: SensorChannelManager? = null
    private var chiropteraService: AndroidChiropteraService? = null

    private val CHIROPTERA_CHANNEL = "chiroptera_sensor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize the sensor channel manager
        sensorChannelManager = SensorChannelManager(this, flutterEngine)

        // Initialize Chiroptera service
        chiropteraService = AndroidChiropteraService(this)
        setupChiropteraChannel(flutterEngine)
    }

    private fun setupChiropteraChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHIROPTERA_CHANNEL).setMethodCallHandler { call, result ->
            val service = chiropteraService
            if (service == null) {
                result.error("UNAVAILABLE", "Chiroptera service not available", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "initializeChiroptera" -> {
                    val config = call.arguments as? Map<String, Any> ?: emptyMap()
                    GlobalScope.launch {
                        try {
                            val capabilities = service.initializeChiroptera(config)
                            withContext(Dispatchers.Main) {
                                result.success(capabilities)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("INITIALIZATION_ERROR", e.message, null)
                            }
                        }
                    }
                }

                "startSession" -> {
                    val config = call.arguments as? Map<String, Any> ?: emptyMap()
                    GlobalScope.launch {
                        try {
                            val sessionData = service.startSession(config)
                            withContext(Dispatchers.Main) {
                                result.success(sessionData)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("SESSION_START_ERROR", e.message, null)
                            }
                        }
                    }
                }

                "stopSession" -> {
                    val sessionId = call.argument<String>("sessionId")
                    if (sessionId != null) {
                        GlobalScope.launch {
                            try {
                                val sessionResult = service.stopSession(sessionId)
                                withContext(Dispatchers.Main) {
                                    result.success(sessionResult)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("SESSION_STOP_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Session ID required", null)
                    }
                }

                "performPing" -> {
                    val direction = call.argument<Map<String, Double>>("direction")
                    val maxRange = call.argument<Double>("maxRange")

                    if (direction != null && maxRange != null) {
                        GlobalScope.launch {
                            try {
                                val pingResult = service.performPing(direction, maxRange)
                                withContext(Dispatchers.Main) {
                                    result.success(pingResult)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("PING_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Direction and maxRange required", null)
                    }
                }

                "getCapabilities" -> {
                    try {
                        val capabilities = service.getCapabilities()
                        result.success(capabilities)
                    } catch (e: Exception) {
                        result.error("CAPABILITIES_ERROR", e.message, null)
                    }
                }

                "validateConfiguration" -> {
                    val config = call.arguments as? Map<String, Any>
                    if (config != null) {
                        try {
                            val isValid = service.validateConfiguration(config)
                            result.success(isValid)
                        } catch (e: Exception) {
                            result.error("VALIDATION_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Configuration required", null)
                    }
                }

                "isAvailable" -> {
                    try {
                        val isAvailable = service.isAvailable()
                        result.success(isAvailable)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "calibrateAudioSystem" -> {
                    // Placeholder for calibration
                    result.success(null)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        sensorChannelManager?.dispose()
        chiropteraService?.cleanup()
    }
}
