import 'package:flutter_smart_repository/core/connectivity/connectivity_service.dart';
import 'package:flutter_smart_repository/domain/contracts/data_sources.dart';
import 'package:flutter_smart_repository/domain/contracts/identifiable.dart';
import 'package:flutter_smart_repository/domain/entities/failure.dart';
import 'package:flutter_smart_repository/domain/entities/offline_action.dart';
import 'package:flutter_smart_repository/domain/policies/fetch_policy.dart';
import 'package:flutter_smart_repository/domain/repository/smart_repository.dart';
import 'package:flutter_smart_repository/data/queue/offline_queue.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeItem implements Identifiable {
  @override
  final String id;
  final String name;
  _FakeItem(this.id, this.name);
}

void main() {
  late List<_FakeItem> localList;
  late List<_FakeItem> remoteList;
  late bool isConnected;
  late List<OfflineAction<_FakeItem>> queueActions;

  setUp(() {
    localList = [];
    remoteList = [_FakeItem('1', 'Remote')];
    isConnected = true;
    queueActions = [];
  });

  LocalDataSource<_FakeItem> createLocal() {
    return _FakeLocalDataSource(localList);
  }

  RemoteDataSource<_FakeItem> createRemote() {
    return _FakeRemoteDataSource(remoteList);
  }

  ConnectivityService createConnectivity() {
    return _FakeConnectivity(isConnected);
  }

  OfflineQueue<_FakeItem> createQueue() {
    return _FakeOfflineQueue(queueActions);
  }

  SmartRepository<_FakeItem> createRepo({
    FetchPolicy policy = FetchPolicy.cacheFirst,
  }) {
    return SmartRepository<_FakeItem>(
      remoteSource: createRemote(),
      localSource: createLocal(),
      connectivity: createConnectivity(),
      offlineQueue: createQueue(),
      fetchPolicy: policy,
    );
  }

  group('SmartRepository.getAll', () {
    test('cacheOnly returns only local data', () async {
      localList.add(_FakeItem('a', 'Local'));
      final repo = createRepo();
      final result = await repo.getAll(policy: FetchPolicy.cacheOnly);
      expect(result.length, 1);
      expect(result.first.id, 'a');
      expect(result.first.name, 'Local');
    });

    test('cacheFirst returns local when non-empty', () async {
      localList.add(_FakeItem('a', 'Local'));
      final repo = createRepo();
      final result = await repo.getAll(policy: FetchPolicy.cacheFirst);
      expect(result.length, 1);
      expect(result.first.name, 'Local');
    });

    test('cacheFirst falls back to remote when local empty and online', () async {
      isConnected = true;
      final repo = createRepo();
      final result = await repo.getAll(policy: FetchPolicy.cacheFirst);
      expect(result.length, 1);
      expect(result.first.name, 'Remote');
    });

    test('networkOnly throws NetworkFailure when offline', () async {
      isConnected = false;
      final repo = createRepo();
      expect(
        () => repo.getAll(policy: FetchPolicy.networkOnly),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('networkFirst returns local on remote failure when online', () async {
      isConnected = true;
      localList.add(_FakeItem('a', 'Local'));
      final repo = SmartRepository<_FakeItem>(
        remoteSource: _ThrowingRemoteDataSource(),
        localSource: createLocal(),
        connectivity: createConnectivity(),
        offlineQueue: createQueue(),
        fetchPolicy: FetchPolicy.networkFirst,
      );
      final result = await repo.getAll(policy: FetchPolicy.networkFirst);
      expect(result.length, 1);
      expect(result.first.name, 'Local');
    });
  });

  group('SmartRepository.getById', () {
    test('cacheOnly returns local by id', () async {
      localList.add(_FakeItem('x', 'LocalX'));
      final repo = createRepo();
      final result = await repo.getById('x', policy: FetchPolicy.cacheOnly);
      expect(result, isNotNull);
      expect(result!.id, 'x');
      expect(result.name, 'LocalX');
    });

    test('cacheOnly returns null when not found', () async {
      final repo = createRepo();
      final result = await repo.getById('missing', policy: FetchPolicy.cacheOnly);
      expect(result, isNull);
    });

    test('cacheFirst returns remote when local null and online', () async {
      isConnected = true;
      remoteList.add(_FakeItem('r1', 'FromRemote'));
      final repo = createRepo();
      final result = await repo.getById('r1', policy: FetchPolicy.cacheFirst);
      expect(result, isNotNull);
      expect(result!.name, 'FromRemote');
    });
  });

  group('SmartRepository.save', () {
    test('saves locally and enqueues when offline', () async {
      isConnected = false;
      final item = _FakeItem('new', 'Item');
      final repo = createRepo();
      await repo.save('new', item);
      expect(localList.length, 1);
      expect(localList.first.id, 'new');
      expect(queueActions.length, 1);
      expect(queueActions.first.actionType, ActionType.create);
    });

    test('when online: saves locally and calls remote create, no enqueue', () async {
      isConnected = true;
      final item = _FakeItem('on1', 'OnlineCreate');
      final repo = createRepo();
      await repo.save('on1', item);
      expect(localList.length, 1);
      expect(remoteList.length, 2); // had one, added one
      expect(remoteList.any((e) => e.id == 'on1'), isTrue);
      expect(queueActions, isEmpty);
    });
  });

  group('SmartRepository.update', () {
    test('when offline: saves locally and enqueues update', () async {
      isConnected = false;
      localList.add(_FakeItem('up1', 'Old'));
      final item = _FakeItem('up1', 'Updated');
      final repo = createRepo();
      await repo.update('up1', item);
      expect(localList.first.name, 'Updated');
      expect(queueActions.length, 1);
      expect(queueActions.first.actionType, ActionType.update);
    });

    test('when online: saves locally and calls remote update, no enqueue', () async {
      isConnected = true;
      remoteList.add(_FakeItem('up2', 'Old'));
      localList.add(_FakeItem('up2', 'Old'));
      final item = _FakeItem('up2', 'Updated');
      final repo = createRepo();
      await repo.update('up2', item);
      expect(localList.first.name, 'Updated');
      expect(remoteList.firstWhere((e) => e.id == 'up2').name, 'Updated');
      expect(queueActions, isEmpty);
    });
  });

  group('SmartRepository.delete', () {
    test('removes from local and enqueues when offline', () async {
      isConnected = false;
      localList.add(_FakeItem('d1', 'ToDelete'));
      final repo = createRepo();
      await repo.delete('d1');
      expect(localList, isEmpty);
      expect(queueActions.length, 1);
      expect(queueActions.first.actionType, ActionType.delete);
    });
  });
}

class _FakeLocalDataSource implements LocalDataSource<_FakeItem> {
  final List<_FakeItem> list;
  _FakeLocalDataSource(this.list);

  @override
  Future<_FakeItem?> getById(String id) async {
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<_FakeItem>> getAll() async => List.from(list);

  @override
  Future<void> save(_FakeItem item) async {
    final i = list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
  }

  @override
  Future<void> saveAll(List<_FakeItem> items) async {
    list.clear();
    list.addAll(items);
  }

  @override
  Future<void> delete(String id) async {
    list.removeWhere((e) => e.id == id);
  }
}

class _FakeRemoteDataSource implements RemoteDataSource<_FakeItem> {
  final List<_FakeItem> list;
  _FakeRemoteDataSource(this.list);

  @override
  Future<_FakeItem> fetchById(String id) async {
    final found = list.where((e) => e.id == id).toList();
    if (found.isEmpty) throw Exception('Not found');
    return found.first;
  }

  @override
  Future<List<_FakeItem>> fetchAll() async => List.from(list);

  @override
  Future<void> create(_FakeItem item) async => list.add(item);

  @override
  Future<void> update(_FakeItem item) async {
    final i = list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
  }

  @override
  Future<void> delete(String id) async {}
}

class _ThrowingRemoteDataSource implements RemoteDataSource<_FakeItem> {
  @override
  Future<_FakeItem> fetchById(String id) async => throw Exception('Network error');

  @override
  Future<List<_FakeItem>> fetchAll() async => throw Exception('Network error');

  @override
  Future<void> create(_FakeItem item) async {}

  @override
  Future<void> update(_FakeItem item) async {}

  @override
  Future<void> delete(String id) async {}
}

class _FakeConnectivity implements ConnectivityService {
  final bool connected;
  _FakeConnectivity(this.connected);

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(connected);
}

class _FakeOfflineQueue implements OfflineQueue<_FakeItem> {
  final List<OfflineAction<_FakeItem>> actions;
  _FakeOfflineQueue(this.actions);

  @override
  Future<void> enqueue(OfflineAction<_FakeItem> action) async {
    actions.add(action);
  }

  @override
  Future<List<OfflineAction<_FakeItem>>> getAll() async => List.from(actions);

  @override
  Future<void> remove(String actionId) async {
    actions.removeWhere((a) => a.id == actionId);
  }

  @override
  Future<void> clear() async => actions.clear();
}
