## 0.0.2

* Documentation and release polish: README links (pub.dev, Contributing), FLUTTER_SMART_REPOSITORY_README rename and updates, pubspec `documentation` and CHANGELOG format.

## 0.0.1

Initial release.

### Features

* **SmartRepository**: Offline-first repository with `getAll`, `getById`, `save` (create), `update`, `delete`.
* **Fetch policies**: `cacheOnly`, `networkOnly`, `cacheFirst`, `networkFirst`, `staleWhileRevalidate`.
* **SyncEngine**: Processes offline queue when connectivity returns; optional conflict resolution.
* **Hive support**: `HiveLocalDataSource`, `HiveOfflineQueue` (configurable box name).
* **Typed errors**: `NetworkFailure`, `ServerFailure`, `CacheFailure`.
* **Conflict resolution**: `TimestampConflictResolver`, custom `ConflictResolver<T>`.
* **Optional**: Encryption service, SyncInspector, DevTools integration.

### Documentation

* README with installation, getting started, use cases, and usage.
* [FLUTTER_SMART_REPOSITORY_README.md](FLUTTER_SMART_REPOSITORY_README.md) for architecture and roadmap.
* Example app in `example/`.
