import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'pinned_keys.dart';

class SecureHttpClient {
  static HttpClient create() {
    final client = HttpClient();

    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      try {
        // Extract certificate bytes
        final pem = cert.pem;
        final lines = pem
            .split('\n')
            .where((l) => !l.startsWith('---'))
            .toList();
        final certBytes = base64.decode(lines.join());

        // SHA-256 hash
        final sha256Hash =
            base64.encode(sha256.convert(certBytes).bytes);

        return pinnedPublicKeyHashes.contains(sha256Hash);
      } catch (_) {
        return false;
      }
    };

    return client;
  }
}
