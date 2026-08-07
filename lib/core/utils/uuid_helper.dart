import 'dart:math';

class UuidHelper {
  static final Random _random = Random.secure();

  /// Generates a valid RFC-4122 Version 4 UUID string
  static String generateV4() {
    final List<int> bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version to 4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to IETF RFC 4122
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final String hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
