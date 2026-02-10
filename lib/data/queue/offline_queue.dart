import '../../domain/entities/offline_action.dart';

abstract class OfflineQueue<T> {
  Future<void> enqueue(OfflineAction<T> action);
  Future<List<OfflineAction<T>>> getAll();
  Future<void> remove(String id);
  Future<void> clear();
}
