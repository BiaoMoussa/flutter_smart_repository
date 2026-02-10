abstract class LocalDataSource<T> {
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<void> save(T item);
  Future<void> saveAll(List<T> items);
  Future<void> delete(String id);
}

abstract class RemoteDataSource<T> {
  Future<T> fetchById(String id);
  Future<List<T>> fetchAll();
  Future<void> create(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
}
