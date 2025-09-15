package com.roomomatic.sensors

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.*
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import androidx.core.app.ActivityCompat
import kotlinx.coroutines.*
import org.jtransforms.fft.DoubleFFT_1D
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine
import kotlin.math.*

/**
 * Android Chiroptera Service for Room-O-Matic Mobile
 * Provides ultrasonic distance measurement using bio-inspired echolocation
 * Named after Chiroptera - the scientific order of bats, masters of echolocation
 */
class AndroidChiropteraService(private val context: Context) {

    companion object {
        private const val TAG = "ChiropteraService"
        private const val RECORD_AUDIO_PERMISSION = Manifest.permission.RECORD_AUDIO

        // Audio parameters
        private const val SAMPLE_RATE = 44100
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        private const val BUFFER_SIZE_MULTIPLIER = 4

        // Sonar parameters
        private const val CHIRP_FREQUENCY_START = 18000.0 // 18kHz
        private const val CHIRP_FREQUENCY_END = 22000.0   // 22kHz
        private const val CHIRP_DURATION_MS = 100L        // 100ms chirp
        private const val RECORDING_DURATION_MS = 2000L   // 2 second recording
        private const val SPEED_OF_SOUND = 343.0          // m/s at room temperature
    }

    // Audio components
    private var audioTrack: AudioTrack? = null
    private var audioRecord: AudioRecord? = null
    private var audioManager: AudioManager? = null

    // Processing
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null
    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Audio effects
    private var echoCanceler: AcousticEchoCanceler? = null
    private var noiseSuppressor: NoiseSuppressor? = null
    private var automaticGainControl: AutomaticGainControl? = null

    // State
    private var capabilities: MutableMap<String, Any> = mutableMapOf()
    private var isSessionActive = false
    private var bufferSize = 0

    // Signal processing
    private var chirpSignal: ShortArray? = null
    private var recordedBuffer: ShortArray? = null

    // Callbacks
    private var distanceCallback: ((String, Map<String, Any>) -> Unit)? = null
    private var errorCallback: ((String, Map<String, Any>) -> Unit)? = null

    init {
        setupCapabilities()
        initializeAudioManager()
    }

    /**
     * Initialize audio sonar service
     */
    suspend fun initialize(config: Map<String, Any>): Pair<Boolean, Map<String, Any>?> {
        return try {
            if (!hasPermissions()) {
                return false to mapOf("error" to "Audio record permission not granted")
            }

            startBackgroundThread()
            setupAudioComponents()
            generateChirpSignal()

            true to capabilities
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Chiroptera sensor: ${e.message}", e)
            false to mapOf("error" to e.message)
        }
    }

    /**
     * Start audio sonar session
     */
    suspend fun startSession(): Pair<Boolean, String?> {
        return try {
            if (isSessionActive) {
                return true to null
            }

            setupAudioEffects()

            audioRecord?.startRecording()
            isSessionActive = true

            true to null
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start Chiroptera session: ${e.message}", e)
            false to e.message
        }
    }

    /**
     * Stop audio sonar session
     */
    suspend fun stopSession(): Pair<Boolean, String?> {
        return try {
            audioRecord?.stop()
            releaseAudioEffects()
            isSessionActive = false

            true to null
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop Chiroptera session: ${e.message}", e)
            false to e.message
        }
    }

    /**
     * Perform sonar ping measurement
     */
    suspend fun performSonarPing(direction: Map<String, Double>): Pair<Boolean, Map<String, Any>?> {
        return suspendCoroutine { continuation ->
            if (!isSessionActive) {
                continuation.resume(false to mapOf("error" to "Chiroptera session not active"))
                return@suspendCoroutine
            }

            backgroundHandler?.post {
                try {
                    val result = executeSonarPing()
                    continuation.resume(true to result)
                } catch (e: Exception) {
                    continuation.resume(false to mapOf("error" to e.message))
                }
            }
        }
    }

    /**
     * Measure distance with parameters
     */
    suspend fun measureDistance(parameters: Map<String, Any>): Pair<Boolean, Map<String, Any>?> {
        val direction = parameters["direction"] as? Map<String, Double> ?: mapOf("x" to 0.0, "y" to 0.0, "z" to 1.0)
        val maxRange = parameters["maxRange"] as? Double ?: 10.0

        val (success, data) = performSonarPing(direction)

        return if (success && data != null) {
            val enrichedData = data.toMutableMap()
            enrichedData["maxRange"] = maxRange
            enrichedData["direction"] = direction
            true to enrichedData
        } else {
            false to data
        }
    }

    /**
     * Get audio sonar capabilities
     */
    fun getCapabilities(): Map<String, Any> {
        return capabilities.toMap()
    }

    /**
     * Set distance callback
     */
    fun setDistanceCallback(callback: (String, Map<String, Any>) -> Unit) {
        distanceCallback = callback
    }

    /**
     * Set error callback
     */
    fun setErrorCallback(callback: (String, Map<String, Any>) -> Unit) {
        errorCallback = callback
    }

    /**
     * Cleanup resources
     */
    fun cleanup() {
        serviceScope.cancel()
        stopBackgroundThread()
        releaseAudioComponents()
        releaseAudioEffects()
    }

    // MARK: - Private Methods

    private fun setupCapabilities() {
        val packageManager = context.packageManager
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        capabilities["hasAudioInput"] = packageManager.hasSystemFeature(PackageManager.FEATURE_MICROPHONE)
        capabilities["hasAudioOutput"] = packageManager.hasSystemFeature(PackageManager.FEATURE_AUDIO_OUTPUT)
        capabilities["supportsChiroptera"] = true
        capabilities["supportsUltrasonic"] = checkUltrasonicSupport()

        // Audio specifications
        capabilities["sampleRate"] = SAMPLE_RATE
        capabilities["channelConfig"] = "MONO"
        capabilities["audioFormat"] = "PCM_16BIT"

        // Frequency specifications
        capabilities["frequencyRange"] = mapOf(
            "min" to CHIRP_FREQUENCY_START,
            "max" to CHIRP_FREQUENCY_END
        )

        // Distance specifications
        capabilities["distanceRange"] = mapOf(
            "min" to 0.1,  // 10cm minimum
            "max" to 10.0   // 10m maximum
        )

        capabilities["accuracy"] = 0.05  // 5cm accuracy
        capabilities["chirpDuration"] = CHIRP_DURATION_MS

        // Hardware support
        capabilities["hasEchoCanceler"] = AcousticEchoCanceler.isAvailable()
        capabilities["hasNoiseSuppressor"] = NoiseSuppressor.isAvailable()
        capabilities["hasAutomaticGainControl"] = AutomaticGainControl.isAvailable()
    }

    private fun checkUltrasonicSupport(): Boolean {
        // Check if device supports high frequency audio
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return try {
            val sampleRates = audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)
            val maxSampleRate = sampleRates?.toIntOrNull() ?: SAMPLE_RATE
            maxSampleRate >= SAMPLE_RATE
        } catch (e: Exception) {
            false
        }
    }

    private fun hasPermissions(): Boolean {
        return ActivityCompat.checkSelfPermission(context, RECORD_AUDIO_PERMISSION) == PackageManager.PERMISSION_GRANTED
    }

    private fun initializeAudioManager() {
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    private fun setupAudioComponents() {
        // Calculate buffer sizes
        val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
        bufferSize = minBufferSize * BUFFER_SIZE_MULTIPLIER

        // Setup AudioRecord for recording
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            SAMPLE_RATE,
            CHANNEL_CONFIG,
            AUDIO_FORMAT,
            bufferSize
        )

        // Setup AudioTrack for playback
        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AUDIO_FORMAT)
                    .setSampleRate(SAMPLE_RATE)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setBufferSizeInBytes(bufferSize)
            .build()
    }

    private fun generateChirpSignal() {
        val chirpSamples = (CHIRP_DURATION_MS * SAMPLE_RATE / 1000).toInt()
        chirpSignal = ShortArray(chirpSamples)

        for (i in 0 until chirpSamples) {
            val time = i.toDouble() / SAMPLE_RATE
            val progress = time / (CHIRP_DURATION_MS / 1000.0)

            // Linear chirp from start frequency to end frequency
            val instantFrequency = CHIRP_FREQUENCY_START + (CHIRP_FREQUENCY_END - CHIRP_FREQUENCY_START) * progress
            val phase = 2.0 * PI * instantFrequency * time

            // Apply Hann window to reduce artifacts
            val window = 0.5 - 0.5 * cos(2.0 * PI * progress)
            val amplitude = 0.1 * window // Keep volume low

            chirpSignal!![i] = (amplitude * sin(phase) * Short.MAX_VALUE).toInt().toShort()
        }
    }

    private fun setupAudioEffects() {
        val audioSessionId = audioRecord?.audioSessionId ?: return

        try {
            if (AcousticEchoCanceler.isAvailable()) {
                echoCanceler = AcousticEchoCanceler.create(audioSessionId)
                echoCanceler?.enabled = true
            }

            if (NoiseSuppressor.isAvailable()) {
                noiseSuppressor = NoiseSuppressor.create(audioSessionId)
                noiseSuppressor?.enabled = true
            }

            if (AutomaticGainControl.isAvailable()) {
                automaticGainControl = AutomaticGainControl.create(audioSessionId)
                automaticGainControl?.enabled = true
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to setup audio effects: ${e.message}")
        }
    }

    private fun executeSonarPing(): Map<String, Any> {
        val chirp = chirpSignal ?: throw IllegalStateException("Chirp signal not generated")

        // Clear previous recording
        recordedBuffer = null

        // Play chirp signal
        audioTrack?.let { track ->
            track.play()
            track.write(chirp, 0, chirp.size)
            track.stop()
        }

        // Record audio for analysis
        val recordingSamples = (RECORDING_DURATION_MS * SAMPLE_RATE / 1000).toInt()
        val recordBuffer = ShortArray(recordingSamples)

        var totalRead = 0
        val startTime = System.currentTimeMillis()

        while (totalRead < recordingSamples && (System.currentTimeMillis() - startTime) < RECORDING_DURATION_MS) {
            val read = audioRecord?.read(recordBuffer, totalRead, recordingSamples - totalRead) ?: 0
            if (read > 0) {
                totalRead += read
            }
        }

        recordedBuffer = recordBuffer.copyOf(totalRead)

        // Process the recorded audio
        return processRecordedAudio(recordedBuffer!!, chirp)
    }

    private fun processRecordedAudio(signal: ShortArray, reference: ShortArray): Map<String, Any> {
        // Convert to double arrays for processing
        val signalDouble = signal.map { it.toDouble() }.toDoubleArray()
        val referenceDouble = reference.map { it.toDouble() }.toDoubleArray()

        // Perform cross-correlation using FFT
        val correlationResult = performCrossCorrelation(signalDouble, referenceDouble)

        // Find peak correlation
        val maxIndex = correlationResult.indices.maxByOrNull { correlationResult[it] } ?: 0
        val maxCorrelation = correlationResult[maxIndex]

        // Calculate time delay
        val delayInSamples = maxIndex - (reference.size - 1)
        val delayInSeconds = delayInSamples.toDouble() / SAMPLE_RATE

        // Calculate distance (divide by 2 for round trip)
        val distance = (delayInSeconds * SPEED_OF_SOUND) / 2.0

        // Validate distance
        val minDistance = 0.1  // 10cm
        val maxDistance = 10.0 // 10m

        if (distance < minDistance || distance > maxDistance) {
            throw IllegalStateException("Distance out of range: $distance (valid: $minDistance-$maxDistance)")
        }

        // Calculate confidence
        val maxPossibleCorrelation = reference.size.toDouble()
        val confidence = min(1.0, maxCorrelation / maxPossibleCorrelation)

        return mapOf(
            "distance" to distance,
            "confidence" to confidence,
            "delaySeconds" to delayInSeconds,
            "correlationPeak" to maxCorrelation,
            "timestamp" to System.currentTimeMillis(),
            "method" to "chiroptera_echolocation",
            "frequency" to "${CHIRP_FREQUENCY_START}-${CHIRP_FREQUENCY_END}Hz",
            "chirpDuration" to CHIRP_DURATION_MS,
            "metadata" to mapOf(
                "sampleRate" to SAMPLE_RATE,
                "signalLength" to signal.size,
                "referenceLength" to reference.size,
                "maxIndex" to maxIndex
            )
        )
    }

    private fun performCrossCorrelation(signal: DoubleArray, reference: DoubleArray): DoubleArray {
        val resultSize = signal.size + reference.size - 1
        val paddedSize = nextPowerOf2(resultSize)

        // Pad arrays to power of 2 for FFT
        val paddedSignal = signal.copyOf(paddedSize)
        val paddedReference = reference.copyOf(paddedSize)

        // Create FFT transformer
        val fft = DoubleFFT_1D(paddedSize.toLong())

        // Convert to complex arrays (real, imaginary)
        val signalComplex = DoubleArray(paddedSize * 2)
        val referenceComplex = DoubleArray(paddedSize * 2)

        for (i in paddedSignal.indices) {
            signalComplex[i * 2] = paddedSignal[i]     // Real part
            signalComplex[i * 2 + 1] = 0.0             // Imaginary part
        }

        for (i in paddedReference.indices) {
            referenceComplex[i * 2] = paddedReference[i]  // Real part
            referenceComplex[i * 2 + 1] = 0.0             // Imaginary part
        }

        // Forward FFT
        fft.complexForward(signalComplex)
        fft.complexForward(referenceComplex)

        // Cross-correlation in frequency domain (multiply signal by conjugate of reference)
        val resultComplex = DoubleArray(paddedSize * 2)
        for (i in 0 until paddedSize) {
            val realIndex = i * 2
            val imagIndex = i * 2 + 1

            val signalReal = signalComplex[realIndex]
            val signalImag = signalComplex[imagIndex]
            val refReal = referenceComplex[realIndex]
            val refImag = -referenceComplex[imagIndex]  // Conjugate

            resultComplex[realIndex] = signalReal * refReal - signalImag * refImag
            resultComplex[imagIndex] = signalReal * refImag + signalImag * refReal
        }

        // Inverse FFT
        fft.complexInverse(resultComplex, true)

        // Extract real part and return only the valid correlation length
        val correlation = DoubleArray(resultSize)
        for (i in correlation.indices) {
            correlation[i] = resultComplex[i * 2]
        }

        return correlation
    }

    private fun nextPowerOf2(n: Int): Int {
        var power = 1
        while (power < n) {
            power *= 2
        }
        return power
    }

    private fun startBackgroundThread() {
        backgroundThread = HandlerThread("AudioSonarBackground").apply {
            start()
            backgroundHandler = Handler(looper)
        }
    }

    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
            backgroundThread = null
            backgroundHandler = null
        } catch (e: InterruptedException) {
            Log.e(TAG, "Failed to stop background thread", e)
        }
    }

    private fun releaseAudioComponents() {
        audioRecord?.let { record ->
            if (record.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                record.stop()
            }
            record.release()
        }
        audioRecord = null

        audioTrack?.let { track ->
            if (track.playState == AudioTrack.PLAYSTATE_PLAYING) {
                track.stop()
            }
            track.release()
        }
        audioTrack = null
    }

    private fun releaseAudioEffects() {
        echoCanceler?.release()
        echoCanceler = null

        noiseSuppressor?.release()
        noiseSuppressor = null

        automaticGainControl?.release()
        automaticGainControl = null
    }
}
