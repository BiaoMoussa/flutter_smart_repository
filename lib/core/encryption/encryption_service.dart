import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Service responsible for managing encryption keys for secure storage.
abstract class EncryptionService {
  /// Retrieves an existing encryption key or generates a new one.
  Future<List<int>> getOrCreateEncryptionKey();
}

class EncryptionServiceImpl implements EncryptionService {
  final FlutterSecureStorage _secureStorage;
  static const String _keyName = 'smart_repository_encryption_key';

  EncryptionServiceImpl(this._secureStorage);

  @override
  Future<List<int>> getOrCreateEncryptionKey() async {
    // Check if the key already exists in secure storage
    final String? encodedKey = await _secureStorage.read(key: _keyName);

    if (encodedKey != null) {
      // Decode the existing key
      return base64Url.decode(encodedKey);
    } else {
      // Generate a new 256-bit secure key
      final List<int> newKey = Hive.generateSecureKey();
      // Persist the key for future use
      await _secureStorage.write(
        key: _keyName,
        value: base64Url.encode(newKey),
      );
      return newKey;
    }
  }
}