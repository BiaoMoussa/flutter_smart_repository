# flutter_smart_repository

A flexible, **offline-first** data repository for Flutter that coordinates local cache, remote API, and sync queue. Ideal for apps that must work offline and sync when connected.

## Features

- **Offline-first**: Local storage is the source of truth; writes are synced when online.
- **Fetch policies**: `cacheOnly`, `networkOnly`, `cacheFirst`, `networkFirst`, `staleWhileRevalidate`.
- **Unified API**: [SmartRepository] exposes `getAll`, `getById`, `save` (create), `update`, `delete`.
- **Sync engine**: [SyncEngine] processes the offline queue when connectivity returns; supports conflict resolution.
- **Typed errors**: [NetworkFailure], [ServerFailure], [CacheFailure] for clearer error handling.
- **Pluggable**: Implement [LocalDataSource], [RemoteDataSource], [OfflineQueue]; Hive implementations included.

## Use cases

Typical applications where this package is useful:

| Use case | Why it fits |
|----------|-------------|
| **Field / on-site** (sales, audits, inspections) | Data entered with no network (construction site, basement, dead zone); automatic sync when back online. |
| **Note-taking or todo apps** | Create and edit notes locally, instant read from cache, background sync with `staleWhileRevalidate`. |
| **E‑commerce / shopping cart** | Add to cart and orders stored locally while offline; sent to the server when connectivity returns. |
| **CRM / sales force** | Log visits, contacts, and quotes in the field; action queue replayed at the office or on Wi‑Fi. |
| **Long forms** (surveys, healthcare, admin) | No data loss if connection drops; recovery and conflicts handled by [SyncEngine] and a [ConflictResolver]. |
| **Dashboards / reporting** | Instant display from cache (`cacheFirst`), background refresh to keep data up to date. |

In all these cases, a single API (the repository) handles read/write while the package takes care of cache, offline queue, and synchronization.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_smart_repository: ^0.0.2
```

Then run `flutter pub get`. Package on pub.dev: [flutter_smart_repository](https://pub.dev/packages/flutter_smart_repository).

## Getting started

1. **Initialize Hive** (e.g. in `main()` before `runApp`):

```dart
import 'package:flutter_smart_repository/flutter_smart_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SmartRepositoryInitializer.init();
  runApp(MyApp());
}
```

2. **Implement data sources** (or use [HiveLocalDataSource] and your own remote):

```dart
// Example: your entity must work with Hive (adapter) if using HiveLocalDataSource
class Task implements Identifiable {
  @override
  final String id;
  final String title;
  Task(this.id, this.title);
}

// Remote: your API
class TaskRemoteSource implements RemoteDataSource<Task> {
  @override
  Future<Task> fetchById(String id) async => /* ... */;
  @override
  Future<List<Task>> fetchAll() async => /* ... */;
  @override
  Future<void> create(Task item) async => /* ... */;
  @override
  Future<void> update(Task item) async => /* ... */;
  @override
  Future<void> delete(String id) async => /* ... */;
}
```

3. **Create repository and sync engine**:

```dart
final localSource = HiveLocalDataSource<Task>('tasks_box');
final remoteSource = TaskRemoteSource();
final connectivity = ConnectivityServiceImpl(Connectivity());
final queue = HiveOfflineQueue<Task>(); // optional: boxName: 'tasks_queue'

final repository = SmartRepository<Task>(
  localSource: localSource,
  remoteSource: remoteSource,
  connectivity: connectivity,
  offlineQueue: queue,
  fetchPolicy: FetchPolicy.cacheFirst,
);

final syncEngine = SyncEngine<Task>(
  remoteSource: remoteSource,
  localDataSource: localSource,
  offlineQueue: queue,
  connectivity: connectivity,
);
syncEngine.initialize(); // processes queue when back online
```

4. **Use the repository**:

```dart
// Read
final tasks = await repository.getAll();
final task = await repository.getById('1');

// Create
await repository.save('1', Task('1', 'Buy milk'));

// Update
await repository.update('1', Task('1', 'Buy milk and eggs'));

// Delete
await repository.delete('1');
```

## Offline behavior

- **save** / **update** / **delete**: Always applied locally first. If online, remote is called; on failure or when offline, the action is enqueued. [SyncEngine] replays the queue when connectivity is restored.
- **getAll** / **getById**: Behavior depends on [FetchPolicy] (e.g. `cacheFirst` returns cache then falls back to network if empty).

## Documentation

- **Quick start**: this README.
- **Architecture, sync flow, conflict resolution, roadmap**: [FLUTTER_SMART_REPOSITORY_README.md](FLUTTER_SMART_REPOSITORY_README.md).
- **API docs**: run `dart doc` in the package or see the [repository](https://github.com/BiaoMoussa/flutter_smart_repository).

## Contributing

Contributions are welcome. Please open an [issue](https://github.com/BiaoMoussa/flutter_smart_repository/issues) or a [pull request](https://github.com/BiaoMoussa/flutter_smart_repository/pulls).

## License

MIT
