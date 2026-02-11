# 🚀 Smart Repository Flutter

A flexible, offline-first, multi-platform data repository designed for
Flutter applications.

------------------------------------------------------------------------

## 📌 Overview

`flutter_smart_repository` is a highly extensible repository layer that
simplifies data management in Flutter applications by providing:

-   Offline-first architecture
-   Automatic synchronization
-   Conflict resolution strategies
-   Smart caching policies
-   Multi-platform support
-   Clean Architecture ready
-   State management friendly (Bloc, Riverpod, etc.)

------------------------------------------------------------------------

## 🎯 Goals

This package aims to solve common problems Flutter developers face when
managing data:

-   Handling offline scenarios
-   Synchronizing local and remote data
-   Reducing boilerplate repository code
-   Providing a unified data access strategy
-   Supporting scalable and maintainable architecture

------------------------------------------------------------------------

## 📱 Platform Support

  Platform   Status
  ---------- --------------
  Android    ✅ Supported
  iOS        ✅ Supported
  Web        🔜 Planned
  Windows    🔜 Planned
  macOS      🔜 Planned
  Linux      🔜 Planned

------------------------------------------------------------------------

## 🧠 Core Concepts

### 1️⃣ Smart Repository

The Smart Repository acts as a unified entry point between the
application and data sources.

It orchestrates:

-   Local data storage
-   Remote API calls
-   Synchronization
-   Conflict resolution
-   Fetch strategies

------------------------------------------------------------------------

### 2️⃣ Data Sources

The package uses two main data sources:

#### Local Data Source

Handles persistence using local storage technologies such as:

-   Hive
-   Isar
-   SQLite
-   Custom adapters

#### Remote Data Source

Handles communication with backend services using:

-   REST APIs
-   GraphQL
-   WebSockets
-   Custom network providers

------------------------------------------------------------------------

### 3️⃣ Fetch Policies

Fetch policies define how data is retrieved.

  -----------------------------------------------------------------------
  Policy                           Description
  -------------------------------- --------------------------------------
  cacheOnly                        Fetch data only from local storage

  networkOnly                      Fetch data only from remote server

  cacheFirst                       Try cache, fallback to network

  networkFirst                     Try network, fallback to cache

  staleWhileRevalidate             Return cache immediately and update
                                   from network
  -----------------------------------------------------------------------

------------------------------------------------------------------------

### 4️⃣ Synchronization Engine

The synchronization engine ensures consistency between local and remote
data.

Features:

-   Automatic background synchronization
-   Offline write queue
-   Network state monitoring
-   Retry with exponential backoff
-   Sync progress tracking

------------------------------------------------------------------------

### 5️⃣ Conflict Resolution

Conflicts occur when local and remote data are modified simultaneously.

Supported strategies:

-   Last Write Wins
-   Timestamp Based
-   Custom Resolver

------------------------------------------------------------------------

### 6️⃣ Offline Queue

All write operations performed offline are stored in a queue and
automatically synchronized when connectivity is restored.

------------------------------------------------------------------------

## 🏗 Architecture

The package follows Clean Architecture principles.

    flutter_smart_repository
    │
    ├── core
    │   ├── sync_engine
    │   ├── connectivity
    │   └── encryption
    │
    ├── domain
    │   ├── repository
    │   ├── entities
    │   ├── policies
    │   └── contracts
    │
    ├── data
    │   ├── local
    │   ├── queue
    │   └── conflict_resolution
    │
    └── utils

------------------------------------------------------------------------

## ⚙️ Basic Usage (Target API)

### Define Entity

```dart
class User implements Identifiable {
  @override
  final String id;
  final String name;
  User(this.id, this.name);
}
```

### Create Repository

```dart
final repository = SmartRepository<User>(
  remoteSource: userRemoteSource,
  localSource: userLocalSource,
  connectivity: connectivity,
  offlineQueue: queue,
  fetchPolicy: FetchPolicy.cacheFirst,
);
```

### Fetch Data

```dart
final users = await repository.getAll();
```

------------------------------------------------------------------------

## 🔄 Synchronization Flow

    User Action
         ↓
    Smart Repository
         ↓
    Local Storage
         ↓
    Offline Queue
         ↓
    Sync Engine
         ↓
    Remote Server

------------------------------------------------------------------------

## 🧪 Testing Strategy

-   Unit tests for policies
-   Sync engine tests
-   Conflict resolution tests
-   Integration tests

------------------------------------------------------------------------

## 🛠 Development Roadmap

### Phase 1 — Core Foundation ✅

-   Repository abstraction
-   Fetch policies
-   Basic local/remote support

### Phase 2 — Synchronization Engine ✅

-   Offline queue
-   Connectivity monitoring
-   Sync events

### Phase 3 — Conflict Resolution ✅

-   Built-in resolvers (e.g. TimestampConflictResolver)
-   Custom resolver support

### Phase 4 — Storage Adapters ✅

-   Hive adapter (local + queue)

### Phase 5 — Advanced Features ✅

-   Encryption support
-   Sync inspector
-   DevTools integration

------------------------------------------------------------------------

## 🤝 Contributing

Contributions are welcome. Please open an issue or a pull request on [GitHub](https://github.com/BiaoMoussa/flutter_smart_repository).

------------------------------------------------------------------------

## 📜 License

MIT License

------------------------------------------------------------------------

## 🌟 Vision

Provide the Flutter ecosystem with a powerful, scalable, and
developer-friendly data management layer.
