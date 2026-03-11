import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'dart:html' as html;
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadManualService {
  final AuthService _authService = AuthService();
  Future<http.Response> downloadManualsList() async {
    final token = await _authService.getAccessToken();

    if (token == null) {
      throw Exception('Access token not found.');
    }

    print('Calling session starter API...');
    print('Token: $token');

    final response = await http.get(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_uploads/api/v1/report/show/download-list'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response code: ${response.statusCode}');
    print('Response body: ${response.body}');
    return response;
  }
  // for web
// Future<void> downloadManual({
//   required String bucketId,
//   required String objectKey,
//   required String fileName,
// }) async {
//   final token = await _authService.getAccessToken();
//   if (token == null) {
//     throw Exception('Access token not found.');
//   }

//   final response = await http.post(
//     Uri.parse('https://uatmyaccountapi.yotta.com/my_uploads/api/v1/report/cht/download/file-download'),
//     headers: {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//     },
//     body: jsonEncode({
//       "bucket-name": bucketId,
//       "object-key": objectKey,
//       "real-file-name": fileName,
//     }),
//   );

//   if (response.statusCode == 200) {
//     final bytes = response.bodyBytes;

//     if (kIsWeb) {
//       final blob = html.Blob([bytes]);
//       final url = html.Url.createObjectUrlFromBlob(blob);
//       final anchor = html.AnchorElement(href: url)
//         ..setAttribute('download', fileName)
//         ..click();
//       html.Url.revokeObjectUrl(url);
//     } else {
//       final dir = await getApplicationDocumentsDirectory();
//       final filePath = '${dir.path}/$fileName';
//       final file = io.File(filePath);
//       await file.writeAsBytes(bytes);
//       await OpenFile.open(filePath);
//     }
//   } else {
//     print('Download failed: ${response.statusCode}');
//     print(response.body);
//   }}
//  For android/ios
  Future<void> downloadManual({
  required String bucketId,
  required String objectKey,
  required String fileName,
}) async {
  final token = await _authService.getAccessToken();
  if (token == null) {
    throw Exception('Access token not found.');
  }

  if (kIsWeb) {
    print('Web download not fully implemented in this file yet to avoid dart:html conflicts.');
    return;
  }

  final permissionStatus = await Permission.storage.request();
  if (!permissionStatus.isGranted) {
    return;
  }

  final url = 'https://uatmyaccountapi.yotta.com/my_uploads/api/v1/report/cht/download/file-download';

  final dio = Dio();

  try {
    final response = await dio.post(
      url,
      data: {
        "bucket-name": bucketId,
        "object-key": objectKey,
        "real-file-name": fileName,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.bytes,
      ),
    );

    if (response.statusCode == 200) {
      final downloadDir = await _getDownloadDirectory();
      final filePath = '${downloadDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.data);
      await OpenFile.open(filePath);
    } else {
      print('Download failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('Error during file download: $e');
  }
}

Future<Directory> _getDownloadDirectory() async {
  if (!kIsWeb && Platform.isAndroid) {
    final dir = Directory('/storage/emulated/0/Download');
    if (await dir.exists()) return dir;
    return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
  } else {
    return await getApplicationDocumentsDirectory();
  }
}
}