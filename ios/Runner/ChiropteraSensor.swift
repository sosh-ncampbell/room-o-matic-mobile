//
//  ChiropteraSensor.swift
//  room_o_matic_mobile
//
//  Created by Room-O-Matic on 2025-09-14.
//  Bio-inspired Echolocation Audio Sensor for iOS
//

import AVFoundation
import Accelerate
import Foundation

/// iOS implementation of Chiroptera audio sonar using AVAudioEngine
@objc class ChiropteraSensor: NSObject {

    // MARK: - Properties
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var outputNode: AVAudioOutputNode?
    private var audioSession: AVAudioSession?

    private var sampleRate: Double = 44100.0
    private var isInitialized = false
    private var isSessionActive = false

    // Chiroptera Configuration
    private var frequencyStart: Float = 18000.0  // 18kHz
    private var frequencyEnd: Float = 22000.0  // 22kHz
    private var chirpDuration: TimeInterval = 0.1  // 100ms

    // Signal Processing
    private var fftSetup: FFTSetup?
    private var chirpSignal: [Float] = []
    private var recordedBuffer: [Float] = []

    // Session Management
    private var sessionId: String?
    private var sessionStartTime: Date?
    private var pingCount: Int = 0

    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }

    deinit {
        cleanup()
    }

    // MARK: - Public Methods

    /// Initialize Chiroptera with device capabilities detection
    @objc func initializeChiroptera(config: [String: Any]) -> [String: Any] {
        guard !isInitialized else {
            return createCapabilitiesResponse()
        }

        // Extract configuration
        if let freqStart = config["frequencyStart"] as? Double {
            frequencyStart = Float(freqStart)
        }
        if let freqEnd = config["frequencyEnd"] as? Double {
            frequencyEnd = Float(freqEnd)
        }
        if let duration = config["chirpDuration"] as? Double {
            chirpDuration = duration / 1000.0  // Convert ms to seconds
        }

        // Setup audio engine
        setupAudioEngine()

        // Generate chirp signal
        generateChirpSignal()

        // Setup FFT for signal processing
        setupFFT()

        isInitialized = true

        return createCapabilitiesResponse()
    }

    /// Start a new Chiroptera measurement session
    @objc func startSession(config: [String: Any]) -> [String: Any] {
        guard isInitialized else {
            return ["error": "Chiroptera not initialized"]
        }

        sessionId = UUID().uuidString
        sessionStartTime = Date()
        pingCount = 0
        isSessionActive = true

        // Start audio engine
        do {
            try audioEngine?.start()
        } catch {
            return ["error": "Failed to start audio engine: \\(error)"]
        }

        return [
            "sessionId": sessionId ?? "",
            "startTime": Int64(sessionStartTime?.timeIntervalSince1970 ?? 0),
            "state": "ready",
            "capabilities": createCapabilitiesResponse(),
        ]
    }

    /// Stop the current session
    @objc func stopSession(sessionId: String) -> [String: Any] {
        guard self.sessionId == sessionId else {
            return ["error": "Invalid session ID"]
        }

        audioEngine?.stop()
        isSessionActive = false

        let endTime = Date()
        let duration = endTime.timeIntervalSince(sessionStartTime ?? endTime)

        let result = [
            "sessionId": sessionId,
            "endTime": Int64(endTime.timeIntervalSince1970),
            "duration": duration * 1000,  // Convert to milliseconds
            "totalPings": pingCount,
            "state": "completed",
        ]

        self.sessionId = nil
        self.sessionStartTime = nil
        pingCount = 0

        return result
    }

    /// Perform a single ping measurement
    @objc func performPing(direction: [String: Double], maxRange: Double) -> [String: Any] {
        guard isSessionActive else {
            return ["error": "No active session"]
        }

        let startTime = Date()
        pingCount += 1

        // Play chirp signal
        let chirpStartTime = playChirpSignal()

        // Record echo for analysis
        let recordingDuration = min(maxRange * 2 / 343.0, 0.5)  // Max 500ms recording
        let echoData = recordEcho(duration: recordingDuration)

        // Analyze echo for distance calculation
        let analysisResult = analyzeEcho(echoData: echoData, chirpStartTime: chirpStartTime)

        let processingTime = Date().timeIntervalSince(startTime) * 1000  // Convert to ms

        return [
            "id": UUID().uuidString,
            "timestamp": Int64(startTime.timeIntervalSince1970 * 1000),
            "direction": direction,
            "distance": analysisResult["distance"] ?? 0.0,
            "confidence": analysisResult["confidence"] ?? 0.0,
            "timeOfFlight": analysisResult["timeOfFlight"] ?? 0.0,
            "signalQuality": analysisResult["signalQuality"] ?? [:],
            "processingTime": processingTime,
        ]
    }

    /// Get device capabilities for Chiroptera
    @objc func getCapabilities() -> [String: Any] {
        return createCapabilitiesResponse()
    }

    /// Validate configuration against device capabilities
    @objc func validateConfiguration(config: [String: Any]) -> Bool {
        guard let freqStart = config["frequencyStart"] as? Double,
            let freqEnd = config["frequencyEnd"] as? Double,
            let sampleRate = config["sampleRate"] as? Double
        else {
            return false
        }

        // Check frequency range against device capabilities
        let nyquistFreq = sampleRate / 2
        return freqEnd <= nyquistFreq && freqStart >= 100 && freqEnd <= 24000
    }

    /// Check if Chiroptera is currently available
    @objc func isAvailable() -> Bool {
        return audioSession?.isInputAvailable ?? false && audioSession?.outputVolume ?? 0 > 0
            && isInitialized
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession?.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession?.setActive(true)
        } catch {
            print("Failed to setup audio session: \\(error)")
        }
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        outputNode = audioEngine?.outputNode

        // Configure audio format for high-quality capture
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) {
            [weak self] buffer, time in
            self?.processAudioBuffer(buffer: buffer, time: time)
        }
    }

    private func generateChirpSignal() {
        let sampleCount = Int(sampleRate * chirpDuration)
        chirpSignal = Array(repeating: 0.0, count: sampleCount)

        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let frequency =
                Double(frequencyStart) + (Double(frequencyEnd - frequencyStart) * t / chirpDuration)

            // Generate linear frequency sweep with Hann window
            let amplitude = 0.1 * sin(.pi * t / chirpDuration)  // Hann window
            chirpSignal[i] = Float(amplitude * sin(2.0 * .pi * frequency * t))
        }
    }

    private func setupFFT() {
        let log2n = vDSP_Length(log2(Double(chirpSignal.count)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }

    private func playChirpSignal() -> TimeInterval {
        guard let audioEngine = audioEngine else { return 0 }

        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat, frameCapacity: UInt32(chirpSignal.count))!

        // Copy chirp signal to audio buffer
        let channelData = audioBuffer.floatChannelData![0]
        for i in 0..<chirpSignal.count {
            channelData[i] = chirpSignal[i]
        }
        audioBuffer.frameLength = UInt32(chirpSignal.count)

        // Create and configure player node
        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: outputNode!, format: audioFormat)

        let playTime = CACurrentMediaTime()
        playerNode.scheduleBuffer(audioBuffer)
        playerNode.play()

        return playTime
    }

    private func recordEcho(duration: TimeInterval) -> [Float] {
        // In a real implementation, this would capture audio during the specified duration
        // For now, return empty array as placeholder
        let sampleCount = Int(sampleRate * duration)
        return Array(repeating: 0.0, count: sampleCount)
    }

    private func analyzeEcho(echoData: [Float], chirpStartTime: TimeInterval) -> [String: Any] {
        guard !echoData.isEmpty, !chirpSignal.isEmpty else {
            return createDefaultAnalysisResult()
        }

        // Perform cross-correlation analysis
        let correlation = performCrossCorrelation(signal1: chirpSignal, signal2: echoData)

        // Find peak correlation
        let (peakIndex, peakValue) = findPeakCorrelation(correlation: correlation)

        // Calculate time of flight
        let timeOfFlight = Double(peakIndex) / sampleRate * 1_000_000  // Convert to microseconds

        // Calculate distance (speed of sound = 343 m/s)
        let distance = (timeOfFlight / 1_000_000) * 343.0 / 2.0  // Divide by 2 for round trip

        // Calculate signal quality metrics
        let signalQuality = calculateSignalQuality(
            correlation: correlation,
            peakValue: peakValue,
            echoData: echoData
        )

        return [
            "distance": distance,
            "confidence": min(peakValue * 2.0, 1.0),  // Confidence based on peak correlation
            "timeOfFlight": timeOfFlight,
            "signalQuality": signalQuality,
        ]
    }

    private func performCrossCorrelation(signal1: [Float], signal2: [Float]) -> [Float] {
        guard let fftSetup = fftSetup else { return [] }

        let n = max(signal1.count, signal2.count)
        let log2n = vDSP_Length(log2(Double(n)))

        // Implement FFT-based cross-correlation
        // This is a simplified version - full implementation would use vDSP functions

        var result = Array(repeating: Float(0.0), count: n)

        // Simple correlation for demonstration
        for i in 0..<min(signal1.count, signal2.count) {
            var sum: Float = 0.0
            for j in 0..<min(signal1.count - i, signal2.count) {
                sum += signal1[j] * signal2[j + i]
            }
            result[i] = sum
        }

        return result
    }

    private func findPeakCorrelation(correlation: [Float]) -> (index: Int, value: Float) {
        guard !correlation.isEmpty else { return (0, 0.0) }

        var maxIndex = 0
        var maxValue = correlation[0]

        for (index, value) in correlation.enumerated() {
            if value > maxValue {
                maxValue = value
                maxIndex = index
            }
        }

        return (maxIndex, maxValue)
    }

    private func calculateSignalQuality(correlation: [Float], peakValue: Float, echoData: [Float])
        -> [String: Any]
    {
        // Calculate signal-to-noise ratio
        let signalPower = echoData.map { $0 * $0 }.reduce(0, +) / Float(echoData.count)
        let snr = 20.0 * log10(signalPower + 0.001)  // Add small value to avoid log(0)

        // Calculate echo clarity (sharpness of correlation peak)
        let clarity =
            peakValue
            / (correlation.map { abs($0) }.reduce(0, +) / Float(correlation.count) + 0.001)

        return [
            "peakCorrelation": peakValue,
            "signalToNoiseRatio": snr,
            "echoClarity": min(clarity, 1.0),
            "noiseLevel": -snr,
            "frequencyResponse": 0.8,  // Placeholder - would analyze frequency domain
        ]
    }

    private func createDefaultAnalysisResult() -> [String: Any] {
        return [
            "distance": 0.0,
            "confidence": 0.0,
            "timeOfFlight": 0.0,
            "signalQuality": [
                "peakCorrelation": 0.0,
                "signalToNoiseRatio": -60.0,
                "echoClarity": 0.0,
                "noiseLevel": 60.0,
                "frequencyResponse": 0.0,
            ],
        ]
    }

    private func createCapabilitiesResponse() -> [String: Any] {
        let audioSession = AVAudioSession.sharedInstance()

        return [
            "supportsUltrasonic": true,
            "hasHardwareEchoCancellation": audioSession.availableCategories.contains(
                .playAndRecord),
            "hasHardwareNoiseSuppression": true,
            "supportsStereoAudio": audioSession.maximumInputNumberOfChannels > 1,
            "hasHighQualityAudio": true,
            "maxSampleRate": Int(audioSession.sampleRate),
            "minSampleRate": 8000,
            "supportedFormats": ["PCM", "Float32"],
            "audioLatency": audioSession.inputLatency + audioSession.outputLatency,
            "limitations": [],
        ]
    }

    private func processAudioBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // Process incoming audio buffer for real-time analysis
        // This would be used for continuous monitoring
    }

    private func cleanup() {
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)

        if let fftSetup = fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }

        try? audioSession?.setActive(false)

        isInitialized = false
        isSessionActive = false
    }
}
