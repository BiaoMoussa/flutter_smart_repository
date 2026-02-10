import 'package:flutter/material.dart';
import 'package:flutter_smart_repository/domain/contracts/data_sources.dart';
import 'package:flutter_smart_repository/domain/contracts/identifiable.dart';
import 'package:flutter_smart_repository/domain/entities/offline_action.dart';
import 'package:flutter_smart_repository/domain/policies/fetch_policy.dart';
import 'package:flutter_smart_repository/domain/repository/smart_repository.dart';
import 'package:flutter_smart_repository/core/connectivity/connectivity_service.dart';
import 'package:flutter_smart_repository/data/queue/offline_queue.dart';

/// Simple entity for the example.
class Task implements Identifiable {
  @override
  final String id;
  final String title;
  Task(this.id, this.title);
}

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Repository Example',
      theme: ThemeData(useMaterial3: true),
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  late SmartRepository<Task> _repo;
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = _createRepository();
    _load();
  }

  SmartRepository<Task> _createRepository() {
    final localList = <Task>[];
    final remoteList = <Task>[Task('1', 'Sample from remote')];
    final queueList = <OfflineAction<Task>>[];

    return SmartRepository<Task>(
      localSource: _InMemoryLocal(localList),
      remoteSource: _InMemoryRemote(remoteList),
      connectivity: _FakeConnectivity(true),
      offlineQueue: _InMemoryQueue(queueList),
      fetchPolicy: FetchPolicy.cacheFirst,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getAll();
      setState(() {
        _tasks = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _repo.save(id, Task(id, 'Task $id'));
    _load();
  }

  Future<void> _delete(Task task) async {
    await _repo.delete(task.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Repository Example')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, i) {
                    final t = _tasks[i];
                    return ListTile(
                      title: Text(t.title),
                      subtitle: Text('id: ${t.id}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(t),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// In-memory implementations for the example (no Hive).

class _InMemoryLocal implements LocalDataSource<Task> {
  final List<Task> _list;
  _InMemoryLocal(this._list);

  @override
  Future<Task?> getById(String id) async {
    try {
      return _list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Task>> getAll() async => List.from(_list);

  @override
  Future<void> save(Task item) async {
    final i = _list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      _list[i] = item;
    } else {
      _list.add(item);
    }
  }

  @override
  Future<void> saveAll(List<Task> items) async {
    _list.clear();
    _list.addAll(items);
  }

  @override
  Future<void> delete(String id) async => _list.removeWhere((e) => e.id == id);
}

class _InMemoryRemote implements RemoteDataSource<Task> {
  final List<Task> _list;
  _InMemoryRemote(this._list);

  @override
  Future<Task> fetchById(String id) async {
    final f = _list.where((e) => e.id == id).toList();
    if (f.isEmpty) throw Exception('Not found');
    return f.first;
  }

  @override
  Future<List<Task>> fetchAll() async => List.from(_list);

  @override
  Future<void> create(Task item) async => _list.add(item);

  @override
  Future<void> update(Task item) async {
    final i = _list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      _list[i] = item;
    } else {
      _list.add(item);
    }
  }

  @override
  Future<void> delete(String id) async => _list.removeWhere((e) => e.id == id);
}

class _FakeConnectivity implements ConnectivityService {
  final bool connected;
  _FakeConnectivity(this.connected);

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(connected);
}

class _InMemoryQueue implements OfflineQueue<Task> {
  final List<OfflineAction<Task>> _actions;
  _InMemoryQueue(this._actions);

  @override
  Future<void> enqueue(OfflineAction<Task> action) async => _actions.add(action);

  @override
  Future<List<OfflineAction<Task>>> getAll() async => List.from(_actions);

  @override
  Future<void> remove(String actionId) async =>
      _actions.removeWhere((a) => a.id == actionId);

  @override
  Future<void> clear() async => _actions.clear();
}
