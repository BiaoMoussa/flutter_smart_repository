import 'dart:developer' as dev;
import '../sync_engine/sync_event.dart';

/// Service to bridge the repository activities with Flutter DevTools.
class DevToolsService {
  static const String _extensionEventName = 'smart_repository.sync_event';

  /// Posts a synchronization event to the Dart developer stream.
  static void logSyncEvent(SyncEvent event) {
    dev.postEvent(_extensionEventName, {
      'id': event.action.id,
      'type': event.action.actionType.toString(),
      'status': event.status.name,
      'timestamp': event.timestamp.toIso8601String(),
      'error': event.errorMessage,
    });
  }

  /// Logs a general repository update (e.g., cache refresh).
  static void logRepositoryUpdate(String boxName, String action) {
    dev.postEvent('smart_repository.update', {
      'box': boxName,
      'action': action,
      'time': DateTime.now().toIso8601String(),
    });
  }
}
