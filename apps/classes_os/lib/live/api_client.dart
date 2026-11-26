import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'config.dart';

typedef Json = Map<String, dynamic>;

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int? statusCode;
  final String message;
  @override
  String toString() => message;
}

/// Thin Dio wrapper that attaches the Firebase ID token to every request.
class ApiClient {
  ApiClient(this._auth)
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _auth.currentUser?.getIdToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    }));
  }

  final FirebaseAuth _auth;
  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, [Object? body]) => _send(() => _dio.post<T>(path, data: body ?? {}));

  Future<T> put<T>(String path, Object body) => _send(() => _dio.put<T>(path, data: body));

  Future<T> patch<T>(String path, Object body) => _send(() => _dio.patch<T>(path, data: body));

  Future<T> delete<T>(String path) => _send(() => _dio.delete<T>(path));

  Future<List<Json>> list(String path, {Map<String, dynamic>? query}) async =>
      (await get<List<dynamic>>(path, query: query)).cast<Json>();

  Future<T> _send<T>(Future<Response<T>> Function() fn) async {
    try {
      return (await fn()).data as T;
    } on DioException catch (e) {
      final data = e.response?.data;
      var msg = switch (e.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout =>
          "Can't reach the server at ${AppConfig.apiUrl}",
        _ => e.message ?? 'Network error',
      };
      if (data is Map && data['message'] != null) {
        final m = data['message'];
        msg = m is List ? m.join(', ') : m.toString();
      }
      throw ApiException(e.response?.statusCode, msg);
    }
  }
}
