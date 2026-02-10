import '../../domain/contracts/conflict_resolver.dart';
import '../../domain/contracts/syncable.dart';

/// Strategy that selects the version with the most recent timestamp.
class TimestampConflictResolver<T extends Syncable>
    implements ConflictResolver<T> {
  @override
  Future<T> resolve(T local, T remote) async {
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      return remote;
    }
    return local;
  }
}
