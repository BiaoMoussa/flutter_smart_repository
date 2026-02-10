
import '../utils/devtools_service.dart';
import 'sync_event.dart';

/// Singleton inspector to monitor sync activities across the app.
class SyncInspector {
  static final SyncInspector _instance = SyncInspector._internal();
  factory SyncInspector() => _instance;
  SyncInspector._internal();

  final List<SyncEvent> _history = [];

  /// Returns a read-only list of all sync events recorded.
  List<SyncEvent> get history => List.unmodifiable(_history);

  /// Attaches the inspector to a SyncEngine to start recording events.
  void attach<T>(Stream<SyncEvent<T>> eventStream) {
    eventStream.listen((event) {
      _history.add(event);
      // Optional: limit history size
      if (_history.length > 100) _history.removeAt(0);
      // Send the event to Flutter DevTools
      DevToolsService.logSyncEvent(event);
    });
  }

  void clearHistory() => _history.clear();
}
