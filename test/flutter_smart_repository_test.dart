import 'package:flutter_smart_repository/domain/entities/failure.dart';
import 'package:flutter_smart_repository/domain/policies/fetch_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure', () {
    test('ServerFailure has default message', () {
      final f = ServerFailure();
      expect(f.message, 'Server error occurred');
    });
    test('ServerFailure accepts custom message', () {
      final f = ServerFailure('Custom');
      expect(f.message, 'Custom');
    });
    test('CacheFailure has default message', () {
      final f = CacheFailure();
      expect(f.message, 'Local data unavailable');
    });
    test('NetworkFailure has default message', () {
      final f = NetworkFailure();
      expect(f.message, 'No internet connection');
    });
  });

  group('FetchPolicy', () {
    test('has expected enum values', () {
      expect(FetchPolicy.values.length, 5);
      expect(FetchPolicy.values, contains(FetchPolicy.cacheOnly));
      expect(FetchPolicy.values, contains(FetchPolicy.networkOnly));
      expect(FetchPolicy.values, contains(FetchPolicy.cacheFirst));
      expect(FetchPolicy.values, contains(FetchPolicy.networkFirst));
      expect(FetchPolicy.values, contains(FetchPolicy.staleWhileRevalidate));
    });
  });
}
