import 'package:flutter/foundation.dart';

import '../../core/connectivity/connectivity_service.dart';
import '../../data/queue/offline_queue.dart';
import '../contracts/data_sources.dart';
import '../entities/failure.dart';
import '../entities/offline_action.dart';
import '../policies/fetch_policy.dart';

/// Offline-first repository that coordinates local cache, remote API, and sync queue.
///
/// Use [save] for creating new entities (calls [RemoteDataSource.create] when online).
/// Use [update] for modifying existing entities (calls [RemoteDataSource.update] when online).
/// Use [delete] to remove an entity locally and on the server (or enqueue when offline).
class SmartRepository<T> {
  final RemoteDataSource<T> remoteSource;
  final LocalDataSource<T> localSource;
  final ConnectivityService connectivity;
  final FetchPolicy fetchPolicy;
  final OfflineQueue<T> offlineQueue;

  SmartRepository({
    required this.remoteSource,
    required this.localSource,
    required this.connectivity,
    required this.offlineQueue,
    this.fetchPolicy = FetchPolicy.cacheFirst,
  });

  // --- READ OPERATIONS ---

  /// Returns a single entity by [id], or null if not found.
  /// Uses [policy] or the default [fetchPolicy]; see [getAll] for behavior per policy.
  Future<T?> getById(String id, {FetchPolicy? policy}) async {
    final activePolicy = policy ?? fetchPolicy;
    final isOnline = await connectivity.isConnected;

    switch (activePolicy) {
      case FetchPolicy.cacheOnly:
        return await localSource.getById(id);
      case FetchPolicy.networkOnly:
        if (isOnline) return await remoteSource.fetchById(id);
        throw NetworkFailure(
          'NetworkOnly mode required but no connection available.',
        );
      case FetchPolicy.cacheFirst:
        final T? local = await localSource.getById(id);
        if (local != null) return local;
        return isOnline ? await remoteSource.fetchById(id) : null;
      case FetchPolicy.networkFirst:
        if (isOnline) {
          try {
            return await remoteSource.fetchById(id);
          } catch (_) {
            return await localSource.getById(id);
          }
        }
        return await localSource.getById(id);
      case FetchPolicy.staleWhileRevalidate:
        final T? local = await localSource.getById(id);
        if (isOnline) {
          remoteSource
              .fetchById(id)
              .then((remote) => localSource.save(remote))
              .catchError((_) {});
        }
        return local;
    }
  }

  /// Returns all entities. [policy] overrides the default [fetchPolicy]:
  /// [FetchPolicy.cacheOnly], [FetchPolicy.networkOnly], [FetchPolicy.cacheFirst],
  /// [FetchPolicy.networkFirst], [FetchPolicy.staleWhileRevalidate].
  Future<List<T>> getAll({FetchPolicy? policy}) async {
    final activePolicy = policy ?? fetchPolicy;
    final isOnline = await connectivity.isConnected;

    switch (activePolicy) {
      case FetchPolicy.cacheOnly:
        return await localSource.getAll();
      case FetchPolicy.networkOnly:
        if (isOnline) return await remoteSource.fetchAll();
        throw NetworkFailure(
          'NetworkOnly mode required but no connection available.',
        );
      case FetchPolicy.cacheFirst:
        final List<T> localData = await localSource.getAll();
        if (localData.isNotEmpty) return localData;
        return isOnline ? await remoteSource.fetchAll() : localData;

      case FetchPolicy.networkFirst:
        if (isOnline) {
          try {
            return await remoteSource.fetchAll();
          } catch (e) {
            return await localSource.getAll();
          }
        }
        return await localSource.getAll();
      case FetchPolicy.staleWhileRevalidate:
        final List<T> localData = await localSource.getAll();
        if (isOnline) {
          // Triggers the background update without waiting for the result
          _fetchAllFromRemote().catchError((e) {
            if (kDebugMode) {
              print("Background sync failed: $e");
            }
            return localData;
          });
        }

        return localData;
    }
  }

  // --- WRITE OPERATIONS (SYNC & OFFLINE) ---

  /// Creates an entity: saves locally and calls [RemoteDataSource.create] when online.
  /// If offline or the remote call fails, the action is enqueued for later sync.
  Future<void> save(String id, T item) async {
    await localSource.save(item);
    if (await connectivity.isConnected) {
      try {
        await remoteSource.create(item);
        return;
      } catch (_) {
        await _enqueueAction(id, item, ActionType.create);
      }
    } else {
      await _enqueueAction(id, item, ActionType.create);
    }
  }

  /// Updates an entity: saves locally and calls [RemoteDataSource.update] when online.
  /// If offline or the remote call fails, the action is enqueued for later sync.
  Future<void> update(String id, T item) async {
    await localSource.save(item);
    if (await connectivity.isConnected) {
      try {
        await remoteSource.update(item);
        return;
      } catch (_) {
        await _enqueueAction(id, item, ActionType.update);
      }
    } else {
      await _enqueueAction(id, item, ActionType.update);
    }
  }

  /// Deletes an entity locally and schedules remote deletion (or enqueues when offline).
  Future<void> delete(String id) async {
    await localSource.delete(id);

    if (await connectivity.isConnected) {
      try {
        await remoteSource.delete(id);
      } catch (_) {
        await _enqueueAction(id, null, ActionType.delete);
      }
    } else {
      await _enqueueAction(id, null, ActionType.delete);
    }
  }

  // --- PRIVATE HELPERS ---

  Future<List<T>> _fetchAllFromRemote() async {
    final List<T> remoteData = await remoteSource.fetchAll();
    await localSource.saveAll(remoteData); // Update cache
    return remoteData;
  }

  Future<void> _enqueueAction(String id, T? data, ActionType type) async {
    final action = OfflineAction<T>(id: id, actionType: type, data: data);
    await offlineQueue.enqueue(action);
  }
}
