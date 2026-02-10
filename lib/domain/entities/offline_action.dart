import 'package:hive/hive.dart';

part 'offline_action.g.dart';

@HiveType(typeId: 1) // Not the same ID that OfflineAction
enum ActionType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

@HiveType(typeId: 0)
class OfflineAction<T> {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ActionType actionType;

  @HiveField(2)
  final Object? rawData;

  @HiveField(3)
  final DateTime createdAt;

  /// Entity payload. Null for [ActionType.delete]; non-null for create/update.
  T? get data => rawData as T?;

  OfflineAction({
    required this.id,
    required this.actionType,
    T? data,
    Object? rawData,
    DateTime? createdAt,
  }) : assert(
         data != null || rawData != null || actionType == ActionType.delete,
         'Provide either data or rawData (or use ActionType.delete)',
       ),
       rawData = rawData ?? data,
       createdAt = createdAt ?? DateTime.now();
}
