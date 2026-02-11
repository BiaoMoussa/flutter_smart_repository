import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityServiceImpl(this._connectivity);

  /// Crée une instance utilisant le plugin connectivity_plus (réseau du téléphone).
  factory ConnectivityServiceImpl.defaultInstance() =>
      ConnectivityServiceImpl(Connectivity());

  @override
  Future<bool> get isConnected async {
    final List<ConnectivityResult> result = await _connectivity
        .checkConnectivity();
    return _isConnected(result);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (result) => _isConnected(result),
    );
  }

  bool _isConnected(List<ConnectivityResult> result) {
    return result.any((res) => res != ConnectivityResult.none);
  }
}
