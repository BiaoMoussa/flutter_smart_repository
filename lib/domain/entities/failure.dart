abstract class Failure {
  final String message;
  Failure(this.message);
}

class ServerFailure extends Failure {
  ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  CacheFailure([super.message = 'Local data unavailable']);
}

class NetworkFailure extends Failure {
  NetworkFailure([super.message = 'No internet connection']);
}
