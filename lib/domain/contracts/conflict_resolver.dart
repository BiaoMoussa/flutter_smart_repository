/// Interface for resolving conflicts between local and remote data.
abstract class ConflictResolver<T> {
  /// Compares local and remote versions and returns the "winning" version.
  Future<T> resolve(T local, T remote);
}
