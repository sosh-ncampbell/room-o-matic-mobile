package com.roomomatic.room_o_matic_mobile

import android.content.Context
import android.media.*
import android.os.Build
import kotlinx.coroutines.*
import java.util.*
import kotlin.math.*

/**
 * Android implementation of Chiroptera audio sonar using AudioTrack/AudioRecord
 * Bio-inspired echolocation for distance measurement
 */
class AndroidChiropteraService(private val context: Context) {

    companion object {
        private const val TAG = "AndroidChiropteraService"
        private const val DEFAULT_SAMPLE_RATE = 44100
        private const val DEFAULT_FREQUENCY_START = 18000.0f
        private const val DEFAULT_FREQUENCY_END = 22000.0f
        private const val DEFAULT_CHIRP_DURATION = 100 // milliseconds
    }

    // Audio components
    private var audioTrack: AudioTrack? = null
    private var audioRecord: AudioRecord? = null
    private var audioManager: AudioManager? = null

    // Configuration
    private var sampleRate = DEFAULT_SAMPLE_RATE
    private var frequencyStart = DEFAULT_FREQUENCY_START
    private var frequencyEnd = DEFAULT_FREQUENCY_END
    private var chirpDuration = DEFAULT_CHIRP_DURATION

    // Session management
    private var isInitialized = false
    private var isSessionActive = false
    private var sessionId: String? = null
    private var sessionStartTime: Long = 0
    private var pingCount = 0

    // Signal processing
    private var chirpSignal: FloatArray = floatArrayOf()
    private var recordingBuffer: FloatArray = floatArrayOf()

    // Coroutine scope for background processing
    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    init {
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    /**
     * Initialize Chiroptera with device capabilities detection
     */
    suspend fun initializeChiroptera(config: Map<String, Any>): Map<String, Any> = withContext(Dispatchers.Default) {
        if (isInitialized) {
            return@withContext createCapabilitiesResponse()
        }

        // Extract configuration
        config["frequencyStart"]?.let { frequencyStart = (it as Number).toFloat() }
        config["frequencyEnd"]?.let { frequencyEnd = (it as Number).toFloat() }
        config["chirpDuration"]?.let { chirpDuration = (it as Number).toInt() }
        config["sampleRate"]?.let { sampleRate = (it as Number).toInt() }

        // Setup audio components
        setupAudioComponents()

        // Generate chirp signal
        generateChirpSignal()

        isInitialized = true
        createCapabilitiesResponse()
    }

    /**
     * Start a new Chiroptera measurement session
     */
    suspend fun startSession(config: Map<String, Any>): Map<String, Any> = withContext(Dispatchers.Default) {
        if (!isInitialized) {
            return@withContext mapOf("error" to "Chiroptera not initialized")
        }

        sessionId = UUID.randomUUID().toString()
        sessionStartTime = System.currentTimeMillis()
        pingCount = 0
        isSessionActive = true

        // Start audio recording
        try {
            audioRecord?.startRecording()
            audioTrack?.play()
        } catch (e: Exception) {
            return@withContext mapOf("error" to "Failed to start audio components: ${e.message}")
        }

        mapOf(
            "sessionId" to (sessionId ?: ""),
            "startTime" to sessionStartTime,
            "state" to "ready",
            "capabilities" to createCapabilitiesResponse()
        )
    }

    /**
     * Stop the current session
     */
    suspend fun stopSession(sessionId: String): Map<String, Any> = withContext(Dispatchers.Default) {
        if (this@AndroidChiropteraService.sessionId != sessionId) {
            return@withContext mapOf("error" to "Invalid session ID")
        }

        // Stop audio components
        audioRecord?.stop()
        audioTrack?.stop()

        isSessionActive = false
        val endTime = System.currentTimeMillis()
        val duration = endTime - sessionStartTime

        val result = mapOf(
            "sessionId" to sessionId,
            "endTime" to endTime,
            "duration" to duration,
            "totalPings" to pingCount,
            "state" to "completed"
        )

        this@AndroidChiropteraService.sessionId = null
        sessionStartTime = 0
        pingCount = 0

        result
    }

    /**
     * Perform a single ping measurement
     */
    suspend fun performPing(direction: Map<String, Double>, maxRange: Double): Map<String, Any> = withContext(Dispatchers.Default) {
        if (!isSessionActive) {
            return@withContext mapOf("error" to "No active session")
        }

        val startTime = System.currentTimeMillis()
        pingCount++

        // Play chirp signal
        val chirpStartTime = playChirpSignal()

        // Record echo for analysis
        val recordingDuration = minOf(maxRange * 2 / 343.0, 0.5) // Max 500ms
        val echoData = recordEcho(recordingDuration)

        // Analyze echo for distance calculation
        val analysisResult = analyzeEcho(echoData, chirpStartTime)

        val processingTime = System.currentTimeMillis() - startTime

        mapOf(
            "id" to UUID.randomUUID().toString(),
            "timestamp" to startTime,
            "direction" to direction,
            "distance" to (analysisResult["distance"] ?: 0.0),
            "confidence" to (analysisResult["confidence"] ?: 0.0),
            "timeOfFlight" to (analysisResult["timeOfFlight"] ?: 0.0),
            "signalQuality" to (analysisResult["signalQuality"] ?: emptyMap<String, Any>()),
            "processingTime" to processingTime.toDouble()
        )
    }

    /**
     * Get device capabilities for Chiroptera
     */
    fun getCapabilities(): Map<String, Any> {
        return createCapabilitiesResponse()
    }

    /**
     * Validate configuration against device capabilities
     */
    fun validateConfiguration(config: Map<String, Any>): Boolean {
        val freqStart = (config["frequencyStart"] as? Number)?.toDouble() ?: return false
        val freqEnd = (config["frequencyEnd"] as? Number)?.toDouble() ?: return false
        val sampleRate = (config["sampleRate"] as? Number)?.toInt() ?: return false

        // Check frequency range against Nyquist frequency
        val nyquistFreq = sampleRate / 2
        return freqEnd <= nyquistFreq && freqStart >= 100 && freqEnd <= 24000
    }

    /**
     * Check if Chiroptera is currently available
     */
    fun isAvailable(): Boolean {
        return audioManager?.getDevices(AudioManager.GET_DEVICES_INPUTS)?.isNotEmpty() == true &&
               audioManager?.getDevices(AudioManager.GET_DEVICES_OUTPUTS)?.isNotEmpty() == true &&
               isInitialized
    }

    // MARK: - Private Methods

    private fun setupAudioComponents() {
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_FLOAT

        // Calculate buffer sizes
        val minBufferSizeRecord = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
        val minBufferSizeTrack = AudioTrack.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_OUT_MONO, audioFormat)

        // Setup AudioRecord for input
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioRecord = AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.MIC)
                .setAudioFormat(AudioFormat.Builder()
                    .setEncoding(audioFormat)
                    .setSampleRate(sampleRate)
                    .setChannelMask(channelConfig)
                    .build())
                .setBufferSizeInBytes(minBufferSizeRecord * 2)
                .build()
        } else {
            @Suppress("DEPRECATION")
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                audioFormat,
                minBufferSizeRecord * 2
            )
        }

        // Setup AudioTrack for output
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            audioTrack = AudioTrack.Builder()
                .setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build())
                .setAudioFormat(AudioFormat.Builder()
                    .setEncoding(audioFormat)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build())
                .setBufferSizeInBytes(minBufferSizeTrack * 2)
                .build()
        } else {
            @Suppress("DEPRECATION")
            audioTrack = AudioTrack(
                AudioManager.STREAM_MUSIC,
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                audioFormat,
                minBufferSizeTrack * 2,
                AudioTrack.MODE_STREAM
            )
        }
    }

    private fun generateChirpSignal() {
        val sampleCount = (sampleRate * chirpDuration / 1000.0).toInt()
        chirpSignal = FloatArray(sampleCount)

        for (i in 0 until sampleCount) {
            val t = i.toDouble() / sampleRate
            val frequency = frequencyStart + (frequencyEnd - frequencyStart) * t / (chirpDuration / 1000.0)

            // Generate linear frequency sweep with Hann window
            val amplitude = 0.1 * sin(PI * t / (chirpDuration / 1000.0)) // Hann window
            chirpSignal[i] = (amplitude * sin(2.0 * PI * frequency * t)).toFloat()
        }
    }

    private suspend fun playChirpSignal(): Long = withContext(Dispatchers.Default) {
        val startTime = System.currentTimeMillis()

        audioTrack?.let { track ->
            track.write(chirpSignal, 0, chirpSignal.size, AudioTrack.WRITE_BLOCKING)
        }

        startTime
    }

    private suspend fun recordEcho(duration: Double): FloatArray = withContext(Dispatchers.Default) {
        val sampleCount = (sampleRate * duration).toInt()
        val buffer = FloatArray(sampleCount)

        audioRecord?.let { record ->
            var totalRead = 0
            while (totalRead < sampleCount) {
                val bytesRead = record.read(buffer, totalRead, sampleCount - totalRead, AudioRecord.READ_BLOCKING)
                if (bytesRead > 0) {
                    totalRead += bytesRead
                } else {
                    break
                }
            }
        }

        buffer
    }

    private suspend fun analyzeEcho(echoData: FloatArray, chirpStartTime: Long): Map<String, Any> = withContext(Dispatchers.Default) {
        if (echoData.isEmpty() || chirpSignal.isEmpty()) {
            return@withContext createDefaultAnalysisResult()
        }

        // Perform cross-correlation analysis
        val correlation = performCrossCorrelation(chirpSignal, echoData)

        // Find peak correlation
        val (peakIndex, peakValue) = findPeakCorrelation(correlation)

        // Calculate time of flight
        val timeOfFlight = peakIndex.toDouble() / sampleRate * 1_000_000 // Convert to microseconds

        // Calculate distance (speed of sound = 343 m/s)
        val distance = (timeOfFlight / 1_000_000) * 343.0 / 2.0 // Divide by 2 for round trip

        // Calculate signal quality metrics
        val signalQuality = calculateSignalQuality(correlation, peakValue, echoData)

        mapOf(
            "distance" to distance,
            "confidence" to minOf(peakValue * 2.0, 1.0), // Confidence based on peak correlation
            "timeOfFlight" to timeOfFlight,
            "signalQuality" to signalQuality
        )
    }

    private fun performCrossCorrelation(signal1: FloatArray, signal2: FloatArray): FloatArray {
        val n = maxOf(signal1.size, signal2.size)
        val result = FloatArray(n)

        // Simple correlation implementation
        for (i in 0 until minOf(signal1.size, signal2.size)) {
            var sum = 0.0f
            for (j in 0 until minOf(signal1.size - i, signal2.size)) {
                sum += signal1[j] * signal2[j + i]
            }
            result[i] = sum
        }

        return result
    }

    private fun findPeakCorrelation(correlation: FloatArray): Pair<Int, Float> {
        if (correlation.isEmpty()) return Pair(0, 0.0f)

        var maxIndex = 0
        var maxValue = correlation[0]

        for ((index, value) in correlation.withIndex()) {
            if (value > maxValue) {
                maxValue = value
                maxIndex = index
            }
        }

        return Pair(maxIndex, maxValue)
    }

    private fun calculateSignalQuality(correlation: FloatArray, peakValue: Float, echoData: FloatArray): Map<String, Any> {
        // Calculate signal-to-noise ratio
        val signalPower = echoData.map { it * it }.average().toFloat()
        val snr = 20.0f * log10(signalPower + 0.001f) // Add small value to avoid log(0)

        // Calculate echo clarity (sharpness of correlation peak)
        val meanCorrelation = correlation.map { abs(it) }.average().toFloat()
        val clarity = peakValue / (meanCorrelation + 0.001f)

        return mapOf(
            "peakCorrelation" to peakValue,
            "signalToNoiseRatio" to snr,
            "echoClarity" to minOf(clarity, 1.0f),
            "noiseLevel" to -snr,
            "frequencyResponse" to 0.8f // Placeholder - would analyze frequency domain
        )
    }

    private fun createDefaultAnalysisResult(): Map<String, Any> {
        return mapOf(
            "distance" to 0.0,
            "confidence" to 0.0,
            "timeOfFlight" to 0.0,
            "signalQuality" to mapOf(
                "peakCorrelation" to 0.0f,
                "signalToNoiseRatio" to -60.0f,
                "echoClarity" to 0.0f,
                "noiseLevel" to 60.0f,
                "frequencyResponse" to 0.0f
            )
        )
    }

    private fun createCapabilitiesResponse(): Map<String, Any> {
        val audioManager = this.audioManager ?: return emptyMap()

        return mapOf(
            "supportsUltrasonic" to true,
            "hasHardwareEchoCancellation" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M),
            "hasHardwareNoiseSuppression" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M),
            "supportsStereoAudio" to true,
            "hasHighQualityAudio" to true,
            "maxSampleRate" to 48000,
            "minSampleRate" to 8000,
            "supportedFormats" to listOf("PCM", "Float32"),
            "audioLatency" to 50.0, // Estimated latency in milliseconds
            "limitations" to emptyList<String>()
        )
    }

    /**
     * Cleanup resources
     */
    fun cleanup() {
        serviceScope.cancel()

        audioRecord?.apply {
            if (state == AudioRecord.STATE_INITIALIZED) {
                stop()
                release()
            }
        }

        audioTrack?.apply {
            if (state == AudioTrack.STATE_INITIALIZED) {
                stop()
                release()
            }
        }

        audioRecord = null
        audioTrack = null

        isInitialized = false
        isSessionActive = false
    }
}
