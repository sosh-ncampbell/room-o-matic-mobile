#if os(iOS)
    //
    //  ChiropteraSensor.swift
    //  Runner
    //
    //  Chiroptera Sensor for Room-O-Matic Mobile
    //  Bio-inspired echolocation technology named after bats (Chiroptera)
    //  Provides ultrasonic distance measurement using audio signals
    //

    import AVFoundation
    import Accelerate
    import Foundation

    @available(iOS 10.0, *)
    class ChiropteraSensor: NSObject {

        // MARK: - Properties

        private var audioEngine: AVAudioEngine?
        private var audioPlayerNode: AVAudioPlayerNode?
        private var audioInputNode: AVAudioInputNode?
        private var audioSession: AVAudioSession?

        // Signal processing
        private let sampleRate: Double = 44100.0
        private let chirpFrequencyStart: Double = 18000.0  // 18kHz start
        private let chirpFrequencyEnd: Double = 22000.0  // 22kHz end
        private let chirpDuration: Double = 0.1  // 100ms chirp
        private let recordingDuration: Double = 2.0  // 2 second recording

        // Processing queue
        private let processingQueue = DispatchQueue(
            label: "com.roomomatic.chiroptera", qos: .userInitiated)

        // State
        private var isSessionActive = false
        private var capabilities: [String: Any] = [:]

        // Callbacks
        private var distanceCallback: ((String, [String: Any]) -> Void)?
        private var errorCallback: ((String, [String: Any]) -> Void)?

        // Audio data buffers
        private var recordedBuffer: AVAudioPCMBuffer?
        private var chirpBuffer: AVAudioPCMBuffer?

        // MARK: - Initialization

        override init() {
            super.init()
            setupCapabilities()
            setupAudioSession()
        }

        // MARK: - Public Methods

        /// Initialize audio sonar sensor
        func initialize(config: [String: Any], completion: @escaping (Bool, [String: Any]?) -> Void)
        {
            processingQueue.async { [weak self] in
                guard let self = self else {
                    completion(false, ["error": "Sensor deallocated"])
                    return
                }

                do {
                    try self.setupAudioEngine()
                    self.generateChirpSignal()

                    DispatchQueue.main.async {
                        completion(true, self.capabilities)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(false, ["error": error.localizedDescription])
                    }
                }
            }
        }

        /// Start audio sonar session
        func startSession(completion: @escaping (Bool, String?) -> Void) {
            processingQueue.async { [weak self] in
                guard let self = self else {
                    completion(false, "Sensor deallocated")
                    return
                }

                guard let engine = self.audioEngine else {
                    completion(false, "Audio engine not initialized")
                    return
                }

                do {
                    try engine.start()
                    self.isSessionActive = true

                    DispatchQueue.main.async {
                        completion(true, nil)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(false, error.localizedDescription)
                    }
                }
            }
        }

        /// Stop audio sonar session
        func stopSession(completion: @escaping (Bool, String?) -> Void) {
            processingQueue.async { [weak self] in
                guard let self = self else {
                    completion(false, "Sensor deallocated")
                    return
                }

                self.audioEngine?.stop()
                self.isSessionActive = false

                DispatchQueue.main.async {
                    completion(true, nil)
                }
            }
        }

        /// Perform sonar ping measurement
        func performSonarPing(
            direction: [String: Double], completion: @escaping (Bool, [String: Any]?) -> Void
        ) {
            guard isSessionActive else {
                completion(false, ["error": "Audio sonar session not active"])
                return
            }

            processingQueue.async { [weak self] in
                guard let self = self else {
                    completion(false, ["error": "Sensor deallocated"])
                    return
                }

                self.executeSonarPing { result in
                    completion(result.success, result.data)
                }
            }
        }

        /// Measure distance in specific direction
        func measureDistance(
            parameters: [String: Any], completion: @escaping (Bool, [String: Any]?) -> Void
        ) {
            guard isSessionActive else {
                completion(false, ["error": "Audio sonar session not active"])
                return
            }

            let direction =
                parameters["direction"] as? [String: Double] ?? ["x": 0.0, "y": 0.0, "z": 1.0]
            let maxRange = parameters["maxRange"] as? Double ?? 10.0

            performSonarPing(direction: direction) { success, data in
                if success, var pingData = data {
                    pingData["maxRange"] = maxRange
                    pingData["direction"] = direction
                    completion(true, pingData)
                } else {
                    completion(false, data)
                }
            }
        }

        /// Get audio sonar capabilities
        func getCapabilities() -> [String: Any] {
            return capabilities
        }

        /// Set distance callback
        func setDistanceCallback(_ callback: @escaping (String, [String: Any]) -> Void) {
            self.distanceCallback = callback
        }

        /// Set error callback
        func setErrorCallback(_ callback: @escaping (String, [String: Any]) -> Void) {
            self.errorCallback = callback
        }

        // MARK: - Private Methods

        private func setupCapabilities() {
            var caps: [String: Any] = [:]

            // Audio hardware capabilities
            caps["hasAudioInput"] = AVAudioSession.sharedInstance().isInputAvailable
            caps["hasAudioOutput"] = true  // iOS devices always have audio output
            caps["supportsChiroptera"] = true
            caps["supportsUltrasonic"] = true

            // Frequency specifications
            caps["frequencyRange"] = [
                "min": chirpFrequencyStart,
                "max": chirpFrequencyEnd,
            ]

            // Distance specifications
            caps["distanceRange"] = [
                "min": 0.1,  // 10cm minimum
                "max": 10.0,  // 10m maximum (theoretical)
            ]

            caps["accuracy"] = 0.05  // 5cm accuracy
            caps["sampleRate"] = sampleRate
            caps["chirpDuration"] = chirpDuration

            self.capabilities = caps
        }

        private func setupAudioSession() {
            audioSession = AVAudioSession.sharedInstance()

            do {
                try audioSession?.setCategory(
                    .playAndRecord, mode: .measurement,
                    options: [.defaultToSpeaker, .allowBluetooth])
                try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                print("Audio session setup failed: \(error)")
            }
        }

        private func setupAudioEngine() throws {
            audioEngine = AVAudioEngine()
            audioPlayerNode = AVAudioPlayerNode()

            guard let engine = audioEngine,
                let playerNode = audioPlayerNode
            else {
                throw AudioSonarError.setupFailed
            }

            engine.attach(playerNode)

            let inputNode = engine.inputNode
            let outputNode = engine.outputNode
            let format = inputNode.inputFormat(forBus: 0)

            // Connect player to output
            engine.connect(playerNode, to: outputNode, format: format)

            // Setup input tap for recording
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
                [weak self] buffer, when in
                self?.processAudioBuffer(buffer, time: when)
            }

            audioInputNode = inputNode

            try engine.prepare()
        }

        private func generateChirpSignal() {
            guard let engine = audioEngine else { return }

            let format = engine.outputNode.outputFormat(forBus: 0)
            let frameCount = AVAudioFrameCount(chirpDuration * sampleRate)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return
            }

            buffer.frameLength = frameCount

            guard let channelData = buffer.floatChannelData else { return }

            let channelCount = Int(format.channelCount)

            for channel in 0..<channelCount {
                let samples = channelData[channel]

                for frame in 0..<Int(frameCount) {
                    let time = Double(frame) / sampleRate
                    let progress = time / chirpDuration

                    // Linear chirp from start frequency to end frequency
                    let instantFrequency =
                        chirpFrequencyStart + (chirpFrequencyEnd - chirpFrequencyStart) * progress
                    let phase = 2.0 * Double.pi * instantFrequency * time

                    // Apply Hann window to reduce artifacts
                    let window = 0.5 - 0.5 * cos(2.0 * Double.pi * progress)
                    let amplitude = Float(0.1 * window)  // Keep volume low

                    samples[frame] = amplitude * Float(sin(phase))
                }
            }

            chirpBuffer = buffer
        }

        private func executeSonarPing(completion: @escaping (SonarPingResult) -> Void) {
            guard let playerNode = audioPlayerNode,
                let chirpBuffer = chirpBuffer
            else {
                completion(
                    SonarPingResult(success: false, data: ["error": "Audio components not ready"]))
                return
            }

            // Reset recording buffer
            recordedBuffer = nil

            // Schedule chirp playback
            playerNode.scheduleBuffer(chirpBuffer, at: nil, options: [], completionHandler: nil)

            // Start recording and wait for echo
            DispatchQueue.main.asyncAfter(deadline: .now() + recordingDuration) { [weak self] in
                self?.processRecordedAudio(completion: completion)
            }

            // Play the chirp
            if !playerNode.isPlaying {
                playerNode.play()
            }
        }

        private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
            // Store the latest buffer for processing
            // In a real implementation, you'd want to accumulate multiple buffers
            recordedBuffer = buffer
        }

        private func processRecordedAudio(completion: @escaping (SonarPingResult) -> Void) {
            guard let recordedBuffer = recordedBuffer,
                let chirpBuffer = chirpBuffer
            else {
                completion(
                    SonarPingResult(success: false, data: ["error": "No audio data recorded"]))
                return
            }

            processingQueue.async { [weak self] in
                guard let self = self else {
                    completion(
                        SonarPingResult(success: false, data: ["error": "Sensor deallocated"]))
                    return
                }

                let result = self.performCrossCorrelation(
                    signal: recordedBuffer, reference: chirpBuffer)

                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }

        private func performCrossCorrelation(signal: AVAudioPCMBuffer, reference: AVAudioPCMBuffer)
            -> SonarPingResult
        {
            guard let signalData = signal.floatChannelData?[0],
                let referenceData = reference.floatChannelData?[0]
            else {
                return SonarPingResult(
                    success: false, data: ["error": "Unable to access audio data"])
            }

            let signalLength = Int(signal.frameLength)
            let referenceLength = Int(reference.frameLength)

            // Perform cross-correlation to find the delay
            let correlationLength = signalLength + referenceLength - 1
            var correlation = [Float](repeating: 0.0, count: correlationLength)

            vDSP_conv(
                signalData, 1, referenceData, 1, &correlation, 1, vDSP_Length(correlationLength),
                vDSP_Length(referenceLength))

            // Find peak correlation
            var maxCorrelation: Float = 0.0
            var maxIndex: vDSP_Length = 0
            vDSP_maxvi(correlation, 1, &maxCorrelation, &maxIndex, vDSP_Length(correlationLength))

            // Calculate time delay
            let delayInSamples = Double(maxIndex) - Double(referenceLength - 1)
            let delayInSeconds = delayInSamples / sampleRate

            // Calculate distance (divide by 2 for round trip)
            let speedOfSound = 343.0  // m/s at room temperature
            let distance = (delayInSeconds * speedOfSound) / 2.0

            // Validate distance (must be within reasonable range)
            let minDistance = 0.1  // 10cm
            let maxDistance = 10.0  // 10m

            guard distance >= minDistance && distance <= maxDistance else {
                return SonarPingResult(
                    success: false,
                    data: [
                        "error": "Distance out of range",
                        "calculatedDistance": distance,
                        "validRange": ["min": minDistance, "max": maxDistance],
                    ])
            }

            // Calculate confidence based on correlation strength
            let maxPossibleCorrelation = Float(referenceLength)
            let confidence = min(1.0, Double(maxCorrelation / maxPossibleCorrelation))

            let resultData: [String: Any] = [
                "distance": distance,
                "confidence": confidence,
                "delaySeconds": delayInSeconds,
                "correlationPeak": maxCorrelation,
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "method": "chiroptera_echolocation",
                "frequency": "\(chirpFrequencyStart)-\(chirpFrequencyEnd)Hz",
                "chirpDuration": chirpDuration,
                "metadata": [
                    "sampleRate": sampleRate,
                    "signalLength": signalLength,
                    "referenceLength": referenceLength,
                    "maxIndex": maxIndex,
                ],
            ]

            return SonarPingResult(success: true, data: resultData)
        }
    }

    // MARK: - Supporting Types

    private struct SonarPingResult {
        let success: Bool
        let data: [String: Any]?
    }

    private enum AudioSonarError: Error {
        case setupFailed
        case sessionNotActive
        case noAudioData
        case processingFailed

        var localizedDescription: String {
            switch self {
            case .setupFailed:
                return "Audio sonar setup failed"
            case .sessionNotActive:
                return "Audio sonar session not active"
            case .noAudioData:
                return "No audio data available"
            case .processingFailed:
                return "Audio processing failed"
            }
        }
    }
#endif  // iOS
