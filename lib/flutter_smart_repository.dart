library;

// Export Domain Layer
export 'domain/repository/smart_repository.dart';
export 'domain/entities/offline_action.dart';
export 'domain/entities/failure.dart';
export 'domain/policies/fetch_policy.dart';
export 'domain/contracts/data_sources.dart';
export 'domain/contracts/conflict_resolver.dart';
export 'domain/contracts/identifiable.dart';
export 'domain/contracts/syncable.dart';

// Export Data Layer
export 'data/local/hive_local_data_source.dart';
export 'data/queue/offline_queue.dart';
export 'data/queue/hive_offline_queue.dart';
export 'data/conflict_resolution/timestamp_resolver.dart';

// Export Core Features
export 'core/connectivity/connectivity_service.dart';
export 'core/encryption/encryption_service.dart';
export 'core/sync_engine/sync_engine.dart';
export 'core/sync_engine/sync_event.dart';
export 'core/sync_engine/sync_inspector.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'domain/entities/offline_action.dart';

class SmartRepositoryInitializer {
  static Future<void> init() async {
    await Hive.initFlutter();

    // IMPORTANT : Enregistrer les deux adaptateurs
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OfflineActionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ActionTypeAdapter()); // L'adaptateur de l'enum
    }
  }
}
