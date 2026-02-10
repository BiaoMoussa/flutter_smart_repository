import 'package:hive/hive.dart';
import '../../domain/entities/offline_action.dart';
import 'offline_queue.dart';

/// Hive-backed implementation of [OfflineQueue].
///
/// [boxName] allows multiple queues (e.g. one per repository type).
/// Defaults to [defaultBoxName] if not specified.
class HiveOfflineQueue<T> implements OfflineQueue<T> {
  static const String defaultBoxName = 'offline_actions_box';

  final String boxName;

  HiveOfflineQueue({String? boxName}) : boxName = boxName ?? defaultBoxName;

  @override
  Future<void> enqueue(OfflineAction<T> action) async {
    final box = await Hive.openBox<OfflineAction<T>>(boxName);
    await box.put(action.id, action);
  }

  @override
  Future<List<OfflineAction<T>>> getAll() async {
    final box = await Hive.openBox<OfflineAction<T>>(boxName);
    final actions = box.values.toList();
    actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return actions;
  }

  @override
  Future<void> remove(String actionId) async {
    final box = await Hive.openBox<OfflineAction<T>>(boxName);
    await box.delete(actionId);
  }

  @override
  Future<void> clear() async {
    final box = await Hive.openBox<OfflineAction<T>>(boxName);
    await box.clear();
  }
}
