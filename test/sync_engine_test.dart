import 'package:flutter_smart_repository/core/connectivity/connectivity_service.dart';
import 'package:flutter_smart_repository/core/sync_engine/sync_engine.dart';
import 'package:flutter_smart_repository/core/sync_engine/sync_event.dart';
import 'package:flutter_smart_repository/domain/contracts/conflict_resolver.dart';
import 'package:flutter_smart_repository/domain/contracts/data_sources.dart';
import 'package:flutter_smart_repository/domain/entities/offline_action.dart';
import 'package:flutter_smart_repository/data/queue/offline_queue.dart';
import 'package:flutter_test/flutter_test.dart';

class _Item {
  final String id;
  final String name;
  _Item(this.id, this.name);
}

void main() {
  late List<_Item> localStore;
  late List<_Item> remoteStore;
  late List<OfflineAction<_Item>> queue;
  late List<SyncEvent<_Item>> events;

  setUp(() {
    localStore = [];
    remoteStore = [];
    queue = [];
    events = [];
  });

  SyncEngine<_Item> createEngine({bool withResolver = false}) {
    final remote = _SyncRemoteDataSource(remoteStore);
    final local = _SyncLocalDataSource(localStore);
    final q = _SyncOfflineQueue(queue);
    final connectivity = _SyncConnectivity(true);
    final engine = SyncEngine<_Item>(
      remoteSource: remote,
      localDataSource: local,
      offlineQueue: q,
      connectivity: connectivity,
      conflictResolver: withResolver ? _SyncConflictResolver() : null,
    );
    engine.syncEvents.listen(events.add);
    return engine;
  }

  group('SyncEngine.processQueue', () {
    test('create: sends to remote and saves to local', () async {
      final item = _Item('c1', 'Created');
      queue.add(OfflineAction<_Item>(id: 'c1', actionType: ActionType.create, data: item));
      final engine = createEngine();
      await engine.processQueue();
      await Future<void>.value(); // allow stream listeners to run
      expect(remoteStore.length, 1);
      expect(remoteStore.first.id, 'c1');
      expect(localStore.length, 1);
      expect(localStore.first.name, 'Created');
      expect(queue, isEmpty);
      expect(events.any((e) => e.status == SyncStatus.success), isTrue);
    });

    test('delete: calls remote delete and removes from queue', () async {
      queue.add(OfflineAction<_Item>(
        id: 'd1',
        actionType: ActionType.delete,
        data: null,
      ));
      remoteStore.add(_Item('d1', 'ToDelete'));
      final engine = createEngine();
      await engine.processQueue();
      expect(remoteStore, isEmpty);
      expect(queue, isEmpty);
    });

    test('update with resolver: uses resolved version on remote and local', () async {
      final updated = _Item('u2', 'LocalWins');
      queue.add(OfflineAction<_Item>(id: 'u2', actionType: ActionType.update, data: updated));
      remoteStore.add(_Item('u2', 'Remote'));
      localStore.add(_Item('u2', 'Old'));
      // Resolver returns local (first arg)
      final engine = createEngine(withResolver: true);
      await engine.processQueue();
      expect(remoteStore.length, 1);
      expect(remoteStore.first.name, 'LocalWins');
      expect(localStore.first.name, 'LocalWins');
      expect(queue, isEmpty);
    });

    test('update without resolver: last-write-wins to remote and local', () async {
      final item = _Item('u1', 'Updated');
      queue.add(OfflineAction<_Item>(id: 'u1', actionType: ActionType.update, data: item));
      remoteStore.add(_Item('u1', 'Old'));
      localStore.add(_Item('u1', 'Old'));
      final engine = createEngine(withResolver: false);
      await engine.processQueue();
      expect(remoteStore.length, 1);
      expect(remoteStore.first.name, 'Updated');
      expect(localStore.length, 1);
      expect(localStore.first.name, 'Updated');
      expect(queue, isEmpty);
    });
  });
}

class _SyncLocalDataSource implements LocalDataSource<_Item> {
  final List<_Item> list;
  _SyncLocalDataSource(this.list);

  @override
  Future<_Item?> getById(String id) async {
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<_Item>> getAll() async => List.from(list);

  @override
  Future<void> save(_Item item) async {
    final i = list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
  }

  @override
  Future<void> saveAll(List<_Item> items) async {
    list.clear();
    list.addAll(items);
  }

  @override
  Future<void> delete(String id) async => list.removeWhere((e) => e.id == id);
}

class _SyncRemoteDataSource implements RemoteDataSource<_Item> {
  final List<_Item> list;
  _SyncRemoteDataSource(this.list);

  @override
  Future<_Item> fetchById(String id) async {
    final f = list.where((e) => e.id == id).toList();
    if (f.isEmpty) throw Exception('Not found');
    return f.first;
  }

  @override
  Future<List<_Item>> fetchAll() async => List.from(list);

  @override
  Future<void> create(_Item item) async => list.add(item);

  @override
  Future<void> update(_Item item) async {
    final i = list.indexWhere((e) => e.id == item.id);
    if (i >= 0) list[i] = item;
  }

  @override
  Future<void> delete(String id) async => list.removeWhere((e) => e.id == id);
}

class _SyncOfflineQueue implements OfflineQueue<_Item> {
  final List<OfflineAction<_Item>> actions;
  _SyncOfflineQueue(this.actions);

  @override
  Future<void> enqueue(OfflineAction<_Item> action) async => actions.add(action);

  @override
  Future<List<OfflineAction<_Item>>> getAll() async => List.from(actions);

  @override
  Future<void> remove(String actionId) async =>
      actions.removeWhere((a) => a.id == actionId);

  @override
  Future<void> clear() async => actions.clear();
}

class _SyncConnectivity implements ConnectivityService {
  final bool connected;
  _SyncConnectivity(this.connected);

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(connected);
}

class _SyncConflictResolver implements ConflictResolver<_Item> {
  @override
  Future<_Item> resolve(_Item local, _Item remote) async => local;
}
