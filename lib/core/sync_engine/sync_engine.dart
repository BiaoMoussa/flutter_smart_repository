import 'dart:async';

import '../../data/queue/offline_queue.dart';
import '../../domain/contracts/conflict_resolver.dart';
import '../../domain/contracts/data_sources.dart';
import '../../domain/entities/offline_action.dart';
import '../connectivity/connectivity_service.dart';
import 'sync_event.dart';

class SyncEngine<T> {
  final RemoteDataSource<T> remoteSource;
  final LocalDataSource<T> localDataSource;
  final OfflineQueue<T> offlineQueue;
  final ConnectivityService connectivity;
  final ConflictResolver<T>? conflictResolver;

  StreamSubscription? _connectivitySubscription;
  final StreamController<SyncEvent<T>> _syncEventController =
      StreamController<SyncEvent<T>>.broadcast();
  Stream<SyncEvent<T>> get syncEvents => _syncEventController.stream;

  SyncEngine({
    required this.remoteSource,
    required this.offlineQueue,
    required this.connectivity,
    required this.localDataSource,
    this.conflictResolver,
  });

  void initialize() {
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      isConnected,
    ) {
      if (isConnected) {
        processQueue();
      }
    });
  }

  Future<void> processQueue() async {
    final actions = await offlineQueue.getAll();
    for (OfflineAction<T> action in actions) {
      _syncEventController.add(
        SyncEvent(action: action, status: SyncStatus.starting),
      );

      try {
        if (action.actionType == ActionType.update) {
          final T? payload = action.data;
          if (payload == null) {
            await offlineQueue.remove(action.id);
            continue;
          }
          if (conflictResolver != null) {
            final T remoteVersion = await remoteSource.fetchById(action.id);
            final T resolved = await conflictResolver!.resolve(
              payload,
              remoteVersion,
            );
            await remoteSource.update(resolved);
            await localDataSource.save(resolved);
          } else {
            await remoteSource.update(payload);
            await localDataSource.save(payload);
          }
        } else if (action.actionType == ActionType.create) {
          final T? payload = action.data;
          if (payload == null) {
            await offlineQueue.remove(action.id);
            continue;
          }
          await remoteSource.create(payload);
          await localDataSource.save(payload);
        } else if (action.actionType == ActionType.delete) {
          await remoteSource.delete(action.id);
        }
        await offlineQueue.remove(action.id);
        _syncEventController.add(
          SyncEvent(action: action, status: SyncStatus.success),
        );
      } catch (e) {
        _syncEventController.add(
          SyncEvent(
            action: action,
            status: SyncStatus.failure,
            errorMessage: e.toString(),
          ),
        );
        break;
      }
    }
  }

  // Call this when the SyncEngine is no longer needed to clean up resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncEventController.close();
  }
}
