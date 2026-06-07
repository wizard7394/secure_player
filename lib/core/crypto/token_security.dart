import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:device_info_plus/device_info_plus.dart';

class TokenSecurity {
  final String _salt = "DevStorage_Secure_Salt_9988!";

  Future<String> _getHardwareId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isWindows) {
      final info = await deviceInfo.windowsInfo;
      return info.deviceId;
    } else if (Platform.isMacOS) {
      final info = await deviceInfo.macOsInfo;
      return info.systemGUID ?? 'unknown_mac';
    } else if (Platform.isLinux) {
      final info = await deviceInfo.linuxInfo;
      return info.machineId ?? 'unknown_linux';
    }
    return 'unknown_device';
  }

  Future<String> getDeviceHash() async {
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
    final key = await _getHardwareKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(token, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }

  Future<String?> decryptToken(String encryptedData) async {
    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) return null;

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedToken = enc.Encrypted.fromBase64(parts[1]);
      final key = await _getHardwareKey();

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encryptedToken, iv: iv);
    } catch (e) {
      return null;
    }
  }
}
