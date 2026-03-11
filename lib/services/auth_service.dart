import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:myaccount/services/api_client_http.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _accessTokenExpiryKey = 'access_token_expiry';
  static const _savedUsernameKey = 'saved_username';
  static const _savedPasswordKey = 'saved_password';

  final String clientId = "yotta-front-end";
  final String tokenEndpoint =
      "https://uatidp.yotta.com/realms/myaccount/protocol/openid-connect/token";

      final httpClient = ApiClientHttp();

  // ---------------- LOGIN ----------------

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      final response = await httpClient.post(
        tokenEndpoint,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'password',
          'client_id': clientId,
          'username': username,
          'password': password,
          'scope': 'openid profile email',
        },
      );

      if (response.statusCode != 200) {
        print("Login failed: ${response.body}");
        return false;
      }

      final data = jsonDecode(response.body);

      await _saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );

      await _storage.write(key: _savedUsernameKey, value: username);
      await _storage.write(key: _savedPasswordKey, value: password);

      return true;
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  // ---------------- TOKEN STORAGE ----------------

  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiryTime = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch;

    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(
        key: _accessTokenExpiryKey, value: expiryTime.toString());
  }

  // ---------------- TOKEN VALIDATION ----------------

  Future<bool> _isAccessTokenExpired({int bufferSeconds = 60}) async {
    final expiryStr = await _storage.read(key: _accessTokenExpiryKey);
    if (expiryStr == null) return true;

    final expiry =
        DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));

    return DateTime.now()
        .isAfter(expiry.subtract(Duration(seconds: bufferSeconds)));
  }

  // ---------------- REFRESH TOKEN ----------------

  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': clientId,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode != 200) {
        print("Refresh token expired");
        return false;
      }

      final data = jsonDecode(response.body);

      await _saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        expiresIn: data['expires_in'],
      );

      return true;
    } catch (e) {
      print("Refresh error: $e");
      return false;
    }
  }

  // ---------------- SESSION ----------------

  /// 🔥 ALWAYS RETURNS A VALID TOKEN OR NULL
  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null) return null;

    if (await _isAccessTokenExpired()) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        final autoLogged = await attemptAutoLogin();
        if (!autoLogged) return null;
      }
    }

    return await _storage.read(key: _accessTokenKey);
  }

  // ---------------- AUTOLOGIN ----------------

  Future<bool> attemptAutoLogin() async {
    final username = await _storage.read(key: _savedUsernameKey);
    final password = await _storage.read(key: _savedPasswordKey);
    if (username != null && password != null) {
      try {
        final response = await httpClient.post(
          tokenEndpoint,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'password',
            'client_id': clientId,
            'username': username,
            'password': password,
            'scope': 'openid profile email',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          await _saveTokens(
            accessToken: data['access_token'],
            refreshToken: data['refresh_token'],
            expiresIn: data['expires_in'],
          );
          return true;
        }
      } catch (e) {
        print("Auto login error: $e");
      }
    }
    return false;
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;

    return !JwtDecoder.isExpired(token);
  }

  // ---------------- LOGOUT ----------------

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
