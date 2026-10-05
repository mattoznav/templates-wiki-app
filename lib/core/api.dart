import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cache.dart';
import 'config.dart';

/// Turn any failure into one sentence for the user.
String errorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'PokéAPI cannot be reached. Check your connection and try again.';
      case DioExceptionType.badResponse:
        if (error.response?.statusCode == 404) return 'This entry does not exist.';
        if (error.response?.statusCode == 429) return 'Too many requests to PokéAPI. Wait a minute and try again.';
        return 'PokéAPI answered with an error (${error.response?.statusCode}). Try again later.';
      default:
        break;
    }
  }
  if (error is GraphQLException) return error.message;
  return 'Something went wrong. Try again.';
}

class GraphQLException implements Exception {
  GraphQLException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// PokéAPI client: REST for single resources, GraphQL for the catalogue.
/// Every response goes through [DiskCache]; when the network fails, a stale
/// copy is used if there is one.
class PokeApi {
  PokeApi(this._dio, this._cache);

  final Dio _dio;
  final DiskCache _cache;

  Future<T> _cached<T>(String key, Duration maxAge, Future<T> Function() load, {bool refresh = false}) async {
    final hit = await _cache.read(key);
    if (hit != null && !refresh && hit.age < maxAge) return hit.value as T;
    try {
      final value = await load();
      await _cache.write(key, value);
      return value;
    } catch (_) {
      if (hit != null) return hit.value as T;
      rethrow;
    }
  }

  /// A REST resource such as `pokemon/25` or `evolution-chain/10`.
  Future<Map<String, dynamic>> resource(String path) async {
    final data = await _cached<Object?>('rest_$path', detailMaxAge, () async {
      final res = await _dio.get<Map<String, dynamic>>('$restUrl/$path/');
      return res.data;
    });
    return Map<String, dynamic>.from(data as Map);
  }

  /// The catalogue query in assets/catalog.graphql: every species, move, type,
  /// ability and game in a single request.
  Future<Map<String, dynamic>> catalog({bool refresh = false}) async {
    final data = await _cached<Object?>('graphql_catalog_v1', catalogMaxAge, () async {
      final query = await rootBundle.loadString('assets/catalog.graphql');
      final res = await _dio.post<Map<String, dynamic>>(graphqlUrl, data: {'query': query});
      final body = res.data!;
      if (body['errors'] != null) {
        throw GraphQLException('PokéAPI could not answer the catalogue query. Try again later.');
      }
      return body['data'];
    }, refresh: refresh);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<int> cacheSize() => _cache.sizeInBytes();
  Future<void> clearCache() => _cache.clear();
}

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);
final diskCacheProvider = Provider<DiskCache>((ref) => throw UnimplementedError('Overridden in main()'));

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );
});

final apiProvider = Provider<PokeApi>((ref) => PokeApi(ref.watch(dioProvider), ref.watch(diskCacheProvider)));
