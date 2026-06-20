class AppException implements Exception {
  final String message;
  final String prefix;

  AppException(this.message, this.prefix);

  @override
  String toString() {
    return "$prefix: $message";
  }
}

class HardwareException extends AppException {
  HardwareException([String message = "Could not fetch hardware ID."])
    : super(message, "Hardware Error");
}

class CryptoException extends AppException {
  CryptoException([String message = "Encryption/Decryption failed."])
    : super(message, "Crypto Error");
}

class CacheException extends AppException {
  CacheException([String message = "Failed to access secure storage."])
    : super(message, "Cache Error");
}

class ServerException extends AppException {
  ServerException([String message = "Server returned an error."])
    : super(message, "Server Error");
}

class NetworkException extends AppException {
  NetworkException([String message = "Network connection failed."])
    : super(message, "Network Error");
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => message;
}
