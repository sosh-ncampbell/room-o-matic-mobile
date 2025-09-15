# 🔒 Room-O-Matic Mobile: Security Implementation Guide

## Overview

This guide provides comprehensive security implementation details for Room-O-Matic Mobile, covering biometric authentication, data encryption, privacy compliance, and secure communication protocols.

## Security Architecture

### Defense in Depth Strategy
```
┌─────────────────────────────────────────────┐
│               User Interface                │ ← Input validation
├─────────────────────────────────────────────┤
│            Application Logic                │ ← Business rules
├─────────────────────────────────────────────┤
│            Platform Channels                │ ← Native security
├─────────────────────────────────────────────┤
│              Data Storage                   │ ← Encryption at rest
├─────────────────────────────────────────────┤
│              Device Security                │ ← Biometric auth
└─────────────────────────────────────────────┘
```

## Biometric Authentication

### iOS Implementation (TouchID/FaceID)

#### Swift Platform Channel Handler
```swift
// ios/Runner/BiometricAuthHandler.swift
import LocalAuthentication
import Flutter

class BiometricAuthHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "room_o_matic/biometrics",
            binaryMessenger: registrar.messenger()
        )
        let instance = BiometricAuthHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "authenticate":
            authenticateUser(result: result)
        case "checkAvailability":
            checkBiometricAvailability(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func authenticateUser(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?

        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            result(FlutterError(
                code: "BIOMETRIC_NOT_AVAILABLE",
                message: error?.localizedDescription,
                details: nil
            ))
            return
        }

        // Perform authentication
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to access your room scans"
        ) { success, authError in
            DispatchQueue.main.async {
                if success {
                    result([
                        "success": true,
                        "method": self.getBiometricType(context: context)
                    ])
                } else {
                    result(FlutterError(
                        code: "AUTHENTICATION_FAILED",
                        message: authError?.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    private func getBiometricType(context: LAContext) -> String {
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .touchID:
                return "touchID"
            case .faceID:
                return "faceID"
            default:
                return "none"
            }
        }
        return "touchID"
    }
}
```

### Android Implementation (Fingerprint/Face)

#### Kotlin Platform Channel Handler
```kotlin
// android/app/src/main/kotlin/BiometricAuthHandler.kt
package com.roomomatic.mobile

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class BiometricAuthHandler(private val activity: FragmentActivity) : MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "authenticate" -> authenticateUser(result)
            "checkAvailability" -> checkBiometricAvailability(result)
            else -> result.notImplemented()
        }
    }

    private fun authenticateUser(result: MethodChannel.Result) {
        val biometricManager = BiometricManager.from(activity)

        when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)) {
            BiometricManager.BIOMETRIC_SUCCESS -> {
                showBiometricPrompt(result)
            }
            BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE -> {
                result.error("NO_HARDWARE", "No biometric features available", null)
            }
            BiometricManager.BIOMETRIC_ERROR_HW_UNAVAILABLE -> {
                result.error("HW_UNAVAILABLE", "Biometric features currently unavailable", null)
            }
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
                result.error("NONE_ENROLLED", "No biometric credentials enrolled", null)
            }
        }
    }

    private fun showBiometricPrompt(result: MethodChannel.Result) {
        val executor = ContextCompat.getMainExecutor(activity)
        val biometricPrompt = BiometricPrompt(activity, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    result.error("AUTHENTICATION_ERROR", errString.toString(), null)
                }

                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(authResult)
                    result.success(mapOf(
                        "success" to true,
                        "method" to "biometric"
                    ))
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    result.error("AUTHENTICATION_FAILED", "Authentication failed", null)
                }
            })

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Authentication")
            .setSubtitle("Authenticate to access your room scans")
            .setNegativeButtonText("Cancel")
            .build()

        biometricPrompt.authenticate(promptInfo)
    }
}
```

### Flutter Integration

#### Biometric Service
```dart
// lib/infrastructure/security/biometric_service.dart
import 'package:flutter/services.dart';

class BiometricService {
  static const MethodChannel _channel = MethodChannel('room_o_matic/biometrics');

  /// Check if biometric authentication is available
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod('checkAvailability');
      return result['available'] as bool;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user with biometrics
  Future<BiometricAuthResult> authenticate() async {
    try {
      final result = await _channel.invokeMethod('authenticate');
      return BiometricAuthResult.success(
        method: result['method'] as String,
      );
    } on PlatformException catch (e) {
      return BiometricAuthResult.failure(
        error: e.code,
        message: e.message ?? 'Authentication failed',
      );
    }
  }
}

sealed class BiometricAuthResult {
  const BiometricAuthResult();

  factory BiometricAuthResult.success({required String method}) = BiometricSuccess;
  factory BiometricAuthResult.failure({required String error, required String message}) = BiometricFailure;
}

class BiometricSuccess extends BiometricAuthResult {
  const BiometricSuccess({required this.method});
  final String method;
}

class BiometricFailure extends BiometricAuthResult {
  const BiometricFailure({required this.error, required this.message});
  final String error;
  final String message;
}
```

## Data Encryption

### AES-256 Encryption Service

#### Core Encryption Implementation
```dart
// lib/infrastructure/security/encryption_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16;  // 128 bits

  late final Encrypter _encrypter;
  late final Key _key;

  EncryptionService() {
    _initializeEncryption();
  }

  void _initializeEncryption() {
    // In production, derive key from secure key derivation function
    _key = _generateSecureKey();
    _encrypter = Encrypter(AES(_key, mode: AESMode.gcm));
  }

  /// Encrypt sensitive data
  Future<EncryptedData> encrypt(String plaintext) async {
    try {
      final iv = IV.fromSecureRandom(_ivLength);
      final encrypted = _encrypter.encrypt(plaintext, iv: iv);

      return EncryptedData(
        ciphertext: encrypted.base64,
        iv: iv.base64,
        tag: encrypted.bytes.sublist(encrypted.bytes.length - 16),
      );
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypt sensitive data
  Future<String> decrypt(EncryptedData encryptedData) async {
    try {
      final iv = IV.fromBase64(encryptedData.iv);
      final encrypted = Encrypted.fromBase64(encryptedData.ciphertext);

      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Generate secure encryption key
  Key _generateSecureKey() {
    // In production, use device keystore/keychain
    final secureRandom = SecureRandom();
    final keyBytes = secureRandom.nextBytes(_keyLength);
    return Key(Uint8List.fromList(keyBytes));
  }

  /// Derive key from user credentials
  Key deriveKeyFromCredentials(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return Key(Uint8List.fromList(digest.bytes));
  }
}

class EncryptedData {
  const EncryptedData({
    required this.ciphertext,
    required this.iv,
    required this.tag,
  });

  final String ciphertext;
  final String iv;
  final Uint8List tag;

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'iv': iv,
    'tag': base64.encode(tag),
  };

  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
    ciphertext: json['ciphertext'],
    iv: json['iv'],
    tag: base64.decode(json['tag']),
  );
}

class EncryptionException implements Exception {
  const EncryptionException(this.message);
  final String message;

  @override
  String toString() => 'EncryptionException: $message';
}
```

### Secure Storage Implementation

#### iOS Keychain Integration
```swift
// ios/Runner/SecureStorageHandler.swift
import Security
import Foundation

class SecureStorageHandler {

    func store(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func retrieve(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        return status == errSecSuccess ? result as? Data : nil
    }

    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
```

#### Android Keystore Integration
```kotlin
// android/app/src/main/kotlin/SecureStorageHandler.kt
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class SecureStorageHandler {
    companion object {
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val AES_MODE = "AES/GCM/NoPadding"
    }

    private val keyStore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply {
        load(null)
    }

    fun generateKey(alias: String): SecretKey {
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
        val keyGenParameterSpec = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationValidityDurationSeconds(300) // 5 minutes
            .build()

        keyGenerator.init(keyGenParameterSpec)
        return keyGenerator.generateKey()
    }

    fun encrypt(alias: String, data: ByteArray): EncryptedData {
        val secretKey = keyStore.getKey(alias, null) as SecretKey
        val cipher = Cipher.getInstance(AES_MODE)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)

        val encryptedBytes = cipher.doFinal(data)
        val iv = cipher.iv

        return EncryptedData(encryptedBytes, iv)
    }

    fun decrypt(alias: String, encryptedData: EncryptedData): ByteArray {
        val secretKey = keyStore.getKey(alias, null) as SecretKey
        val cipher = Cipher.getInstance(AES_MODE)
        val spec = GCMParameterSpec(128, encryptedData.iv)
        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)

        return cipher.doFinal(encryptedData.ciphertext)
    }

    data class EncryptedData(
        val ciphertext: ByteArray,
        val iv: ByteArray
    )
}
```

## Privacy Compliance (GDPR)

### Data Minimization
```dart
// lib/domain/privacy/data_minimization.dart
class DataMinimizationService {
  /// Anonymize location data
  GeoLocation anonymizeLocation(GeoLocation location) {
    // Reduce precision to neighborhood level (±100m)
    final lat = (location.latitude * 1000).round() / 1000;
    final lng = (location.longitude * 1000).round() / 1000;

    return GeoLocation(
      latitude: lat,
      longitude: lng,
      timestamp: location.timestamp,
      // Remove device-specific identifiers
      deviceId: null,
      accuracy: null,
    );
  }

  /// Remove personally identifiable information from scan metadata
  RoomScan sanitizeScanData(RoomScan scan) {
    return scan.copyWith(
      // Remove device identifiers
      deviceModel: null,
      deviceId: null,
      // Anonymize timestamps (round to hour)
      timestamp: DateTime(
        scan.timestamp.year,
        scan.timestamp.month,
        scan.timestamp.day,
        scan.timestamp.hour,
      ),
      // Remove precise location data
      location: scan.location != null
          ? anonymizeLocation(scan.location!)
          : null,
    );
  }
}
```

### GDPR Compliance Service
```dart
// lib/application/services/gdpr_service.dart
class GDPRService {
  final EncryptionService _encryption;
  final DatabaseService _database;

  GDPRService(this._encryption, this._database);

  /// Export all user data (Article 20: Right to data portability)
  Future<GDPRExport> exportUserData() async {
    final roomScans = await _database.getAllRoomScans();
    final settings = await _database.getUserSettings();
    final privacySettings = await _database.getPrivacySettings();

    return GDPRExport(
      timestamp: DateTime.now(),
      data: {
        'room_scans': roomScans.map((s) => s.toJson()).toList(),
        'app_settings': settings.toJson(),
        'privacy_settings': privacySettings.toJson(),
        'export_metadata': {
          'format_version': '1.0',
          'export_reason': 'gdpr_data_portability',
          'data_controller': 'Room-O-Matic Mobile',
        },
      },
    );
  }

  /// Delete all user data (Article 17: Right to erasure)
  Future<void> deleteAllUserData() async {
    await _database.deleteAllRoomScans();
    await _database.deleteUserSettings();
    await _database.deletePrivacySettings();
    await _database.deleteAllCachedData();

    // Clear secure storage
    await _clearSecureStorage();

    // Log deletion for audit trail
    await _logDataDeletion();
  }

  /// Rectify user data (Article 16: Right to rectification)
  Future<void> rectifyUserData(Map<String, dynamic> corrections) async {
    for (final entry in corrections.entries) {
      await _database.updateUserData(entry.key, entry.value);
    }

    await _logDataRectification(corrections);
  }

  Future<void> _clearSecureStorage() async {
    // Implementation specific to secure storage
  }

  Future<void> _logDataDeletion() async {
    // Log for audit purposes (no personal data)
    final auditLog = AuditLogEntry(
      action: 'data_deletion',
      timestamp: DateTime.now(),
      details: 'User requested complete data deletion under GDPR Article 17',
    );

    await _database.insertAuditLog(auditLog);
  }
}
```

## Network Security

### Certificate Pinning
```dart
// lib/infrastructure/network/secure_http_client.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_certificate_pinning/dio_certificate_pinning.dart';

class SecureHttpClient {
  late final Dio _dio;

  SecureHttpClient() {
    _dio = Dio();
    _configureInterceptors();
  }

  void _configureInterceptors() {
    // Certificate pinning
    _dio.interceptors.add(
      CertificatePinningInterceptor(
        allowedSHAFingerprints: [
          'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Production cert
          'SHA256:BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Backup cert
        ],
      ),
    );

    // Request/Response logging (development only)
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // Don't log sensitive data
        responseBody: false,
      ));
    }

    // Authentication interceptor
    _dio.interceptors.add(AuthInterceptor());
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add API key or JWT token
    final token = getSecureToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add request signature for API integrity
    final signature = generateRequestSignature(options);
    options.headers['X-Request-Signature'] = signature;

    super.onRequest(options, handler);
  }

  String? getSecureToken() {
    // Retrieve from secure storage
    return null; // Implement secure token retrieval
  }

  String generateRequestSignature(RequestOptions options) {
    // Implement HMAC signature for request integrity
    return 'signature';
  }
}
```

## Security Testing

### Penetration Testing Checklist
```dart
// test/security/security_test.dart
group('Security Testing', () {
  test('Biometric authentication handles errors gracefully', () async {
    final biometricService = BiometricService();

    // Test with biometrics unavailable
    when(mockPlatformChannel.invokeMethod('authenticate'))
        .thenThrow(PlatformException(code: 'NO_HARDWARE'));

    final result = await biometricService.authenticate();
    expect(result, isA<BiometricFailure>());
  });

  test('Encryption uses secure parameters', () {
    final encryptionService = EncryptionService();

    expect(encryptionService.algorithm, equals('AES-256-GCM'));
    expect(encryptionService.keySize, equals(256));
    expect(encryptionService.ivSize, equals(128));
  });

  test('Sensitive data is not logged', () {
    final logger = TestLogger();
    final sensitiveData = 'user_password_123';

    logger.info('User authenticated: ${sanitizeForLogging(sensitiveData)}');

    expect(logger.logs, isNot(contains(sensitiveData)));
    expect(logger.logs, contains('User authenticated: [REDACTED]'));
  });
});
```

## Security Monitoring

### Runtime Application Self-Protection (RASP)
```dart
// lib/infrastructure/security/rasp_monitor.dart
class RASPMonitor {
  static final List<SecurityEvent> _events = [];

  /// Monitor for security threats at runtime
  static void initialize() {
    // Monitor for debugging tools
    _detectDebugging();

    // Monitor for jailbreak/root
    _detectDeviceCompromise();

    // Monitor for hooking/tampering
    _detectTampering();
  }

  static void _detectDebugging() {
    if (kDebugMode) return; // Skip in development

    // Implementation specific to platform
    // iOS: Check for debugger attachment
    // Android: Check for debugging flags
  }

  static void _detectDeviceCompromise() {
    // Check for jailbreak indicators (iOS)
    // Check for root indicators (Android)
  }

  static void _detectTampering() {
    // Verify app signature
    // Check for code injection
    // Monitor for unusual behavior
  }

  static void logSecurityEvent(SecurityEvent event) {
    _events.add(event);

    if (event.severity == SecuritySeverity.critical) {
      _handleCriticalThreat(event);
    }
  }

  static void _handleCriticalThreat(SecurityEvent event) {
    // Lock app
    // Clear sensitive data
    // Log incident
    // Notify security team (if applicable)
  }
}
```

## Security Checklist

### Pre-Release Security Audit
- [ ] Biometric authentication properly implemented
- [ ] All sensitive data encrypted with AES-256
- [ ] Secure storage using platform keystore/keychain
- [ ] Certificate pinning configured for network requests
- [ ] GDPR compliance implemented (export, delete, rectify)
- [ ] Input validation on all external inputs
- [ ] No sensitive data in logs or crash reports
- [ ] Code obfuscation enabled for release builds
- [ ] Runtime security monitoring active
- [ ] Penetration testing completed

### Ongoing Security Maintenance
- [ ] Regular security dependency updates
- [ ] Certificate rotation procedures
- [ ] Security incident response plan
- [ ] Employee security training
- [ ] Regular security assessments
- [ ] Threat model reviews

---

**This security implementation guide ensures Room-O-Matic Mobile meets enterprise-grade security standards while maintaining usability and performance.**
