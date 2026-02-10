## 0.0.1

* Initial release: SmartRepository, SyncEngine, fetch policies, Hive data sources, offline queue.
* **Improvements (pre-release):**
  * [SmartRepository] Added `update(id, item)`; `save` is create-only.
  * [SmartRepository] Throws [NetworkFailure] instead of generic Exception when network required but offline.
  * [OfflineAction] `data` is now `T?` (null for delete); constructor allows null payload for [ActionType.delete].
  * [SyncEngine] Handles update without resolver (last-write-wins); saves to local after create; skips create/update when payload is null.
  * [HiveOfflineQueue] Configurable `boxName` (optional constructor param); default remains `offline_actions_box`.
  * [getById] Stale-while-revalidate background fetch now uses `.catchError` to avoid unhandled futures.
  * README with description, features, getting started, and usage.
  * Example app (`example/`) with in-memory data sources.
  * Tests: NetworkFailure on networkOnly offline; save when online; update (offline/online); SyncEngine update with resolver; delete with null payload.
