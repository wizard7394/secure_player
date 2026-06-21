import 'dart:convert';
import 'dart:typed_data';
import 'dart:developer';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../error/app_exceptions.dart';
import '../../src/rust/api/simple.dart';

class TokenSecurity {
  final String _salt = "DevStorage_Secure_Salt_9988!";
  static String? _cachedHwId;
  static String? _cachedSpecs;

  Future<String> _getHardwareId() async {
    if (_cachedHwId != null) {
      log("[TokenSecurity] ⚡ Using cached HWID", name: 'Security');
      return _cachedHwId!;
    }
    log(
      "[TokenSecurity] ⏳ Calling Rust core to fetch HWID...",
      name: 'Security',
    );
    try {
      final rawId = await Future.value(getSystemHardwareId());
      if (rawId.startsWith("UNKNOWN_")) {
        log(
          "[TokenSecurity] ⚠️ Warning: Hardware ID fallback triggered.",
          name: 'Security',
        );
      }
      _cachedHwId = rawId;
      log("[TokenSecurity] ✅ HWID Fetched successfully.", name: 'Security');
      return rawId;
    } catch (e) {
      log("[TokenSecurity] ❌ Error fetching HWID: $e", name: 'Security');
      throw HardwareException("Failed to read native hardware footprint: $e");
    }
  }

  Future<String> getDeviceHash() async {
    log(
      "[TokenSecurity] 🔐 Generating SHA256 Hash for device...",
      name: 'Security',
    );
    final hwId = await _getHardwareId();
    final bytes = utf8.encode(hwId + _salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<enc.Key> _getHardwareKey() async {
    final hwId = await _getHardwareId();
    final bytes = utf8.encode(hwId + _salt);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  Future<String> encryptToken(String token) async {
    log("[TokenSecurity] 🔒 Encrypting JWT Token...", name: 'Security');
    try {
      final key = await _getHardwareKey();
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(token, iv: iv);
      log("[TokenSecurity] ✅ Token encrypted successfully.", name: 'Security');
      return "${iv.base64}:${encrypted.base64}";
    } catch (e) {
      log("[TokenSecurity] ❌ Token encryption failed: $e", name: 'Security');
      throw CryptoException("Failed to secure token: $e");
    }
  }

  Future<String?> decryptToken(String encryptedData) async {
    log(
      "[TokenSecurity] 🔓 Decrypting JWT Token from storage...",
      name: 'Security',
    );
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) return null;

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedToken = enc.Encrypted.fromBase64(parts[1]);
      final key = await _getHardwareKey();

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(encryptedToken, iv: iv);
      log("[TokenSecurity] ✅ Token decrypted successfully.", name: 'Security');
      return decrypted;
    } catch (e) {
      log(
        "[TokenSecurity] ❌ Security Warning: Token decryption failed.",
        name: 'Security',
      );
      return null;
    }
  }

  Future<String> fetchSystemSpecs() async {
    if (_cachedSpecs != null) {
      log("[TokenSecurity] ⚡ Using cached System Specs", name: 'Security');
      return _cachedSpecs!;
    }
    log(
      "[TokenSecurity] ⏳ Calling Rust core to fetch System Specs...",
      name: 'Security',
    );
    try {
      final specs = await Future.value(getSystemSpecs());
      _cachedSpecs = specs;
      log(
        "[TokenSecurity] ✅ System Specs Fetched successfully.",
        name: 'Security',
      );
      return specs;
    } catch (e) {
      log("[TokenSecurity] ❌ Error fetching Specs: $e", name: 'Security');
      return "Unknown Specs";
    }
  }
}
