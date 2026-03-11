import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myaccount/services/app_services/session/session_manager.dart';
import 'package:myaccount/services/app_services/ticket_service/get_ticket_details.dart';
import 'package:myaccount/services/auth_service.dart';
import 'package:myaccount/utilities/global.colors.dart';
import 'package:myaccount/widgets/bottom_navigation.dart';
import 'package:myaccount/widgets/common_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:excel/excel.dart' as ex;
// import 'dart:html' as html;

class TicketDetailsView extends StatefulWidget {
  final Map<String, dynamic> ticketData;
  const TicketDetailsView({super.key, required this.ticketData});

  @override
  State<TicketDetailsView> createState() => _TicketDetailsViewState();
}

class _TicketDetailsViewState extends State<TicketDetailsView> {
  final TextEditingController _textController = TextEditingController();
  final TicketDetailsService _ticketDetailsService = TicketDetailsService();
  final ScrollController _horizontalController = ScrollController();
  final List<Map<String, String>> messages = [];
  PlatformFile? selectedFile;
  Map<String, dynamic>? _ticketDetails;
  List<Map<String, dynamic>> allAttachments = [];
  bool isLoading = true;
  final labelStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: GlobalColors.textcolor,
);
 List<Map<String, dynamic>>? attachmentData;
  List<Map<String, dynamic>> attachmentArray = [];
  List<PlatformFile> selectedFiles = [];
bool _isSending = false;

  void _pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    // withData: true,
    type: FileType.custom,
    allowedExtensions: [
      'jpg',
      'jpeg',
      'png',
      'txt',
      'docx',
      'xlsx',
      'csv',
      'pdf',
      'msg',
    ],
  );

  if (result != null) {
    final file = result.files.single;

    if (file.size > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File size must be less than 5MB')),
      );
      return;
    }

    final bytes = await File(file.path!).readAsBytes();
    // final bytes = file.bytes ??
    // await File(file.path!).readAsBytes();
    final ext = file.extension?.toLowerCase();

  Uint8List processedBytes = Uint8List.fromList(bytes);
    // 🔐 Apply protection only for CSV
    if (ext == 'csv') {
      processedBytes = sanitizeCsvContent(Uint8List.fromList(bytes));
    }
    // 🔐 Basic validation only for XLSX
    if (ext == 'xlsx') {
    processedBytes = sanitizeExcel(Uint8List.fromList(bytes));
    }


    // Other file types → bypass (no changes)
    final base64String = base64Encode(processedBytes);

    String contentType;
    if (ext == 'msg') {
      contentType = 'application/vnd.ms-outlook';
    } else if (ext == 'pdf') {
      contentType = 'application/pdf';
    } else if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    } else if (ext == 'png') {
      contentType = 'image/png';
    } else if (ext == 'docx') {
      contentType =
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    } else if (ext == 'xlsx') {
      contentType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else if (ext == 'csv') {
      contentType = 'text/csv';
    } else if (ext == 'txt') {
      contentType = 'text/plain';
    } else {
      contentType = 'application/octet-stream';
    }

    final attach = {
      'contentType': contentType,
      'filename': file.name,
      'csize': file.size,
      'size': file.size > 1048576
          ? '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'
          : '${(file.size / 1024).toStringAsFixed(2)} KB',
      'content': base64String,
    };

    selectedFiles.add(file);
    attachmentArray.add(attach);

    setState(() {
      attachmentData = attachmentArray;
    });
  }
}



Uint8List sanitizeCsvContent(Uint8List bytes) {
  String content = utf8.decode(bytes, allowMalformed: true);

  // Formula injection protection
  final formulaRegex = RegExp(r'(?<=^|,)\s*"?\s*([=+\-@#])', multiLine: true);

  content = content.replaceAllMapped(formulaRegex, (match) {
    return "'${match.group(0)}";
  });

  // URL protection
  final urlRegex = RegExp(r'(?<=^|,)(\s*)(https?:\/\/|www\.)',
      caseSensitive: false,
      multiLine: true);

  content = content.replaceAllMapped(urlRegex, (match) {
    return "'${match.group(0)}";
  });

  return Uint8List.fromList(utf8.encode(content));
}

void validateExcelFile(List<int> bytes) {
  if (bytes.isEmpty) {
    throw Exception("Invalid Excel file");
  }

  // Optional: basic ZIP signature check for XLSX
  if (!(bytes[0] == 0x50 && bytes[1] == 0x4B)) {
    throw Exception("Corrupted Excel file");
  }
}


Uint8List sanitizeExcel(Uint8List bytes) {
  final oldExcel = ex.Excel.decodeBytes(bytes);
  final newExcel = ex.Excel.createExcel();

  for (var table in oldExcel.tables.keys) {
    final oldSheet = oldExcel.tables[table]!;
    final newSheet = newExcel[table];

    for (int rowIndex = 0; rowIndex < oldSheet.rows.length; rowIndex++) {
      for (int colIndex = 0;
          colIndex < oldSheet.rows[rowIndex].length;
          colIndex++) {

        final cell = oldSheet.rows[rowIndex][colIndex];
        if (cell == null || cell.value == null) continue;

        String value = cell.value.toString().trim();

        // Same logic as Angular
        if (value.isNotEmpty) {
          final dangerousChars = ['=', '+', '-', '@', '#'];

          if (dangerousChars.contains(value[0])) {
            value = "'$value";
          }

          final urlRegex = RegExp(r'^(https?:\/\/|www\.)',
              caseSensitive: false);

          if (urlRegex.hasMatch(value)) {
            value = "'$value";
          }
        }

        // ALWAYS write as plain string into new file
        newSheet
            .cell(ex.CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex))
            .value = value.toString();
      }
    }
  }

  // Remove default empty sheet if exists
  if (newExcel.tables.keys.contains('Sheet1') &&
      !oldExcel.tables.keys.contains('Sheet1')) {
    newExcel.delete('Sheet1');
  }

  return Uint8List.fromList(newExcel.encode()!);
}



  void _removeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      attachmentData?.removeAt(index);
    });
  }

  void _showSelectedFilesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selected Files'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: selectedFiles.length,
              itemBuilder: (context, index) {
                final file = selectedFiles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(file.name),
                    subtitle: Text("${(file.size / 1024).toStringAsFixed(2)} KB"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _removeFile(index);
                        });
                        Navigator.pop(context);
                        _showSelectedFilesDialog();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }


  void _fetchTicketDetails() async {
    isLoading=true;
    try {
      final ticketId = widget.ticketData['ticketid']?.toString();
      if (ticketId != null && ticketId.isNotEmpty) {
        final response = await _ticketDetailsService.getTicketDetailsData(ticketId);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> articles = data['ticket'][0]['Articles'] ?? [];
          final List<dynamic> attachmentsData = data['ticket'][0]['Attachments'] ?? [];
          List<Map<String, String>> chatMessages = [];
          List<Map<String, dynamic>> attachments = [];

          for (var item in articles) {
            final articleId = item['ArticleID'];

            // Add message to chat
            chatMessages.add({
              'create_time': item['AddedOn'],
              'owner': item['AddedBy'],
              'owner_type': item['Type'] == 'External'?'sender':'receiver',
              'desc_content': item['SenderType'] == 'system' ? item['Subject']: item['Body'],
              // 'attach':item['Attachment'] ? item['Attachment'] : ''
              //  'attach': attachmentsData ?? ''
            });

           attachments= attachmentsData.map((e) => {
              "File Name": e['Filename'],
              "Created At":e['CreatedOn'],
              "ContentType":e['ContentType'],
              "Content":e['Content'],
                "Size": (() {
                  final sizeString = e['Size'];
                  if (sizeString  == null) return "0 KB"; // or "Unknown"
                    final size = int.tryParse(sizeString.toString());
                    if (size == null) return "0 KB";

                  return size > 1048576
                      ? (size / (1024 * 1024)).toStringAsFixed(2) + " MB"
                      : (size / 1024).toStringAsFixed(2) + " KB";
                })(),}).toList();
            // Collect attachments with ArticleID
            // if (item['Attachment'] != null && item['Attachment'] is List) {
            //   for (var attach in item['Attachment']) {
            //     attach['ArticleID'] = articleId;
            //     attachments.add(attach);
            //   }
            // }
          }

          setState(() {
            _ticketDetails = data;
            allAttachments = attachments;
            messages.clear();
            messages.addAll(chatMessages);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching ticket details: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTicketDetails();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticketData;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: 'Ticket Details'),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          border: Border.all(width: 1.0, color: GlobalColors.borderColor),
        ),
        child: Column(
          children: [
            // Ticket Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 1.0, color: GlobalColors.borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              
              child: Stack(
                children: [
                  // MAIN CARD CONTENT
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${ticket['ticketNo'] ?? ''}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LEFT SIDE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Type', style: labelStyle),
                                Text(ticket['type'] ?? 'N/A'),
                                SizedBox(height: 8),

                                Text('Ticket Number', style: labelStyle),
                                Text(ticket['ticketNo']?.toString() ?? 'N/A'),
                                SizedBox(height: 8),

                                Text('Category', style: labelStyle),
                                Text(ticket['category'] ?? 'N/A'),
                              ],
                            ),
                          ),

                          // RIGHT SIDE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sub Category', style: labelStyle),
                                Text(ticket['subCategory'] ?? 'N/A'),
                                SizedBox(height: 8),

                                Text('Priority', style: labelStyle),
                                Text(ticket['severity'] ?? 'N/A'),
                                SizedBox(height: 8),

                                Text('Status', style: labelStyle),
                                Text(
                                  ticket['status'] ?? 'N/A',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ATTACHMENT ICON (TOP-RIGHT or BOTTOM-RIGHT)
                  Positioned(
                    right: 0,
                    bottom: 0, 
                    child: IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: GlobalColors.mainColor,
                      ),
                      onPressed:
                          () => _showPreviewModal(context, allAttachments),
                    ),
                  ),
                ],
              )

            ),
            const SizedBox(height: 16),

            // Chat & Input Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 1.0, color: GlobalColors.borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                  ?Center(child: CircularProgressIndicator()):Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCustomer = message['owner_type'] == 'sender';
                          return Align(
                            // alignment:
                            //     isCustomer
                            //         ? Alignment.centerRight
                            //         : Alignment.centerLeft,
                            alignment: Alignment.centerRight,
                            child: IntrinsicWidth(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color:
                                    isCustomer
                                        ? Colors.blue[100]
                                        : Colors.grey[300],
                                // borderRadius: BorderRadius.circular(10),
                                borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isCustomer ? 12 : 0),
                                topRight: Radius.circular(isCustomer ? 0 : 12),
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              ),
                              // child: Text(
                              //   Html( data : message['desc_content'] ?? '') as String,

                              //   style: const TextStyle(fontSize: 15),
                              // ),
                              child: Html(
                                data: message['desc_content'] ?? '',
                                style: {
                                  "body": Style(
                                    textAlign: isCustomer ? TextAlign.right : TextAlign.left, // ⬅ aligns inner text inside HTML
                                    // margin: EdgeInsets.zero,    // removes extra padding from <body>
                                    // padding: EdgeInsets.zero,
                                  ),
                                },
                              ),
                            ),
                          ));
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: GlobalColors.borderColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file),
                          color: GlobalColors.mainColor,
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
  onPressed: _isSending
      ? null
      : () async {
          if (_textController.text.trim().isEmpty &&
              (attachmentData == null || attachmentData!.isEmpty)) {
            return; // prevent empty send
          }

          setState(() {
            _isSending = true;
          });

          try {
            final uuid = Uuid();
            final id = uuid.v4();
            final sessionData = SessionManager().getSessionData();
            final bto = sessionData?['bto'];
            final sto = sessionData?['sto'];
            final email = sessionData?['email'];

            String rawMessage = _textController.text.trim();

            String plainTextMessage = html_parser
                .parse(rawMessage)
                .body
                ?.text ?? '';

            final ticket_json = {
              "externalSource": "One Yotta",
              "commChannel": "Internal",
              "commID": "2",
              "mimeType": "text/plain",
              "externalID": "OY#$id",
              "charset": "UTF8",
              "user": email,
              "queue": "",
              "tClass": "",
              "callingCustID": "",
              "associateCustID": "",
              "billToCRMID": bto,
              "supportToCRMID": sto,
              "type": "",
              "project": "",
              "domain": "",
              "category": "",
              "subCategory": "",
              "priority": "",
              "assetUAN": [],
              "subject": ticket['subject'],
              "ticketID": widget.ticketData['ticketid'],
              "message": plainTextMessage,
              "attachment": attachmentData ?? [],
              "state": ticket['status'] == 'Resolved' ? 'Reopen' : ''
            };

            await updateTicket(context, ticket_json);

            // Optional: clear message after success
            _textController.clear();
            attachmentData = [];
          } finally {
            setState(() {
              _isSending = false;
              selectedFiles = [];

            });
          }
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: GlobalColors.mainColor,
  ),
  child: _isSending
      ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
      : const Text(
          'Send',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'poppins',
          ),
        ),
),

                      ],
                    ),
                    if (selectedFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                        onTap: _showSelectedFilesDialog,
                        child: Text(
                          'Selected: ${selectedFiles!.length} file(s)',
                          style: TextStyle(fontSize: 14, color: GlobalColors.textcolor),
                        ),
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: const BottomNavigation(),
    );
  }

   Future<void> updateTicket(BuildContext context, Map<String, dynamic> ticketData) async {
  try {
    final AuthService _authService = AuthService();
    final token = await _authService.getAccessToken();

    if (token == null) throw Exception('Access token not found.');

    final response = await http.post(
      Uri.parse('https://uatmyaccountapi.yotta.com/my_ticket/api/v1/ticket/update_ticket'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(ticketData),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final resData = jsonDecode(response.body);

      if (resData['TicketID'] != null && resData['TicketNumber'] != null) {
        Future.delayed(const Duration(seconds: 1), () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket Updated Successfully.')),
          );
          _textController.clear();
          _fetchTicketDetails();

        });

        // Add optional callbacks like:
        // await fetchTicketData(bto, sto);
        // addTicket(resData);
          
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong, Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Error: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error While Updating ticket: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exception: $e')),
    );
  }
}

void _showPreviewModal(BuildContext context, List<Map<String, dynamic>> attachments) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            AppBar(
              title: const Text('Attachments List'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1),

            /// TABLE GOES HERE
            // Expanded(
              // child: 
              attachments.isEmpty
                  ? const Center(
                      child: Text("No attachments found"),
                    )
                  : Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true, // 👈 makes scrollbar always visible
                  child:SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                     padding: const EdgeInsets.only(bottom: 16), // 👈 KEY FIX
                      child: DataTable(
                        columnSpacing: 30,         // optional: helps spacing
                        headingRowHeight: 40,
                        dataRowHeight: 48,
                        columns: const [
                          DataColumn(label: Text("File Name")),
                          DataColumn(label: Text("Created At")),
                          DataColumn(label: Text("Size")),
                          DataColumn(label: Text("Download")),
                        ],
                        rows: attachments.map((file) {
                          return DataRow(cells: [
                            DataCell(Text(file["File Name"] ?? "")),
                            DataCell(Text(file["Created At"] ?? "")),
                            DataCell(Text(file["Size"] ?? "")),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () {
                                  _downloadFile(
                                    file["File Name"],
                                    file["Content"],
                                  );
                                },
                              ),
                            )
                          ]);
                        }).toList(),
                      ),
                    ),),
            // ),
          ],
        ),
      );
    },
  );
}

Future<void> _downloadFile(String fileName, String base64Content) async {
  setState(() => isLoading = true);
  try {
    // 2. Decode base64 to bytes
    Uint8List bytes = base64Decode(base64Content);

    final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        await OpenFile.open(file.path);
        setState(() => isLoading = false);
    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File downloaded',
          ),
        ),
      );
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download'),
        ),
      );
    }
} catch (e) {
  setState(() => isLoading = false);
    print("Download error: $e");
  }
}

}
