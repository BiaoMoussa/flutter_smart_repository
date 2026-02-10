import '../../domain/entities/offline_action.dart';

/// Represents the status of a synchronization attempt.
enum SyncStatus { starting, success, failure }

/// Data structure representing a single synchronization event.
class SyncEvent<T> {
  final OfflineAction<T> action;
  final SyncStatus status;
  final DateTime timestamp;
  final String? errorMessage;

  SyncEvent({
    required this.action,
    required this.status,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
