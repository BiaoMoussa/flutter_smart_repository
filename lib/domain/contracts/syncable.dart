/// Interface that entities must implement to support timestamp-based resolution.
abstract class Syncable {
  DateTime get updatedAt;
}
