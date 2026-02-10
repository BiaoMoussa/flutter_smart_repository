import 'package:hive/hive.dart';

import '../../domain/contracts/data_sources.dart';
import '../../domain/contracts/identifiable.dart';

/// A generic implementation of LocalDataSource using Hive.
/// [T] is the entity type, which must have a registered Hive adapter.
/// Generic Hive implementation with optional AES-256 encryption support.
class HiveLocalDataSource<T> implements LocalDataSource<T> {
  final String boxName;
  final List<int>? encryptionKey;
  HiveLocalDataSource(this.boxName, {this.encryptionKey});

  Future<Box<T>> _getBox() async {
    return await Hive.openBox<T>(
      boxName,
      encryptionCipher: encryptionKey != null
          ? HiveAesCipher(encryptionKey!)
          : null,
    );
  }

  @override
  Future<void> delete(String id) async {
    final Box box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<List<T>> getAll() async {
    final Box box = await _getBox();
    return box.values.cast<T>().toList();
  }

  @override
  Future<T?> getById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  @override
  Future<void> save(T item) async {
    final box = await _getBox();
    if (item is Identifiable) {
      await box.put(item.id, item);
    } else {
      await box.add(item);
    }
  }

  @override
  Future<void> saveAll(List<T> items) async {
    final box = await _getBox();
    await box.clear();
    for (final item in items) {
      if (item is Identifiable) {
        await box.put(item.id, item);
      } else {
        await box.add(item);
      }
    }
  }
}
