import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: "access_token");
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !JwtDecoder.isExpired(token);
  }

  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  final String clientId = "yotta-front-end";
  final String tokenEndpoint =
      "https://uatidp.yotta.com/realms/myaccount/protocol/openid-connect/token";

  Future<bool> loginWithCredentials(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'password',
          'client_id': clientId,
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _secureStorage.write(key: "access_token", value: data['access_token']);
        await _secureStorage.write(key: "id_token", value: data['id_token']);
        print("Access Token: ${data['access_token']}");
        return true;
      } else {
        print("Login failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }
}
