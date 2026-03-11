import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../security/ssl_pinning.dart';

class ApiClientDio {
  static final ApiClientDio _instance = ApiClientDio._internal();
  late Dio dio;

  factory ApiClientDio() => _instance;

  ApiClientDio._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => SecureHttpClient.create(),
    );

    _addInterceptors();
  }

  static const String _baseUrl = 'https://uatmyaccountapi.yotta.com';

  void _addInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach token
          // options.headers['Authorization'] = 'Bearer token';
          handler.next(options);
        },
        onError: (e, handler) {
          handler.next(e);
        },
      ),
    );
  }
}
