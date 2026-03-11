import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../security/ssl_pinning.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClientHttp {
  static final ApiClientHttp _instance = ApiClientHttp._internal();
  late http.Client _client;

  factory ApiClientHttp() => _instance;

  ApiClientHttp._internal() {
    if (kIsWeb) {
      _client = http.Client();
    } else {
      _client = IOClient(SecureHttpClient.create());
    }
  }

  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
  }) {
    return _client.get(
      Uri.parse(url),
      headers: headers,
    );
  }

  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _client.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
  }

  void dispose() {
    _client.close();
  }
}
