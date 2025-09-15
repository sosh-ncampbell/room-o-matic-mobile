import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var chiropteraSensor: ChiropteraSensor?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        // Setup Chiroptera platform channel
        setupChiropteraChannel(controller: controller)

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func setupChiropteraChannel(controller: FlutterViewController) {
        chiropteraSensor = ChiropteraSensor()

        let chiropteraChannel = FlutterMethodChannel(
            name: "chiroptera_sensor",
            binaryMessenger: controller.binaryMessenger
        )

        chiropteraChannel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self, let sensor = self.chiropteraSensor else {
                result(
                    FlutterError(
                        code: "UNAVAILABLE", message: "Chiroptera sensor not available",
                        details: nil))
                return
            }

            switch call.method {
            case "initializeChiroptera":
                let config = call.arguments as? [String: Any] ?? [:]
                let capabilities = sensor.initializeChiroptera(config: config)
                result(capabilities)

            case "startSession":
                let config = call.arguments as? [String: Any] ?? [:]
                let sessionData = sensor.startSession(config: config)
                result(sessionData)

            case "stopSession":
                if let args = call.arguments as? [String: Any],
                    let sessionId = args["sessionId"] as? String
                {
                    let sessionResult = sensor.stopSession(sessionId: sessionId)
                    result(sessionResult)
                } else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENT", message: "Session ID required", details: nil))
                }

            case "performPing":
                if let args = call.arguments as? [String: Any],
                    let direction = args["direction"] as? [String: Double],
                    let maxRange = args["maxRange"] as? Double
                {
                    let pingResult = sensor.performPing(direction: direction, maxRange: maxRange)
                    result(pingResult)
                } else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENT", message: "Direction and maxRange required",
                            details: nil))
                }

            case "getCapabilities":
                let capabilities = sensor.getCapabilities()
                result(capabilities)

            case "validateConfiguration":
                if let config = call.arguments as? [String: Any] {
                    let isValid = sensor.validateConfiguration(config: config)
                    result(isValid)
                } else {
                    result(
                        FlutterError(
                            code: "INVALID_ARGUMENT", message: "Configuration required",
                            details: nil))
                }

            case "isAvailable":
                let isAvailable = sensor.isAvailable()
                result(isAvailable)

            case "calibrateAudioSystem":
                // Placeholder for calibration - would implement audio system calibration
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
