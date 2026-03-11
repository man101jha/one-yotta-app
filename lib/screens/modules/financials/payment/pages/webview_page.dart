import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:myaccount/screens/modules/financials/payment/data/payData.dart';
import 'package:url_launcher/url_launcher.dart';

class WebviewPage extends StatefulWidget {
  final PaymentData? data;

  const WebviewPage({
    Key? key,
    this.data,
  }) : super(key: key);

  @override
  State<WebviewPage> createState() => _WebviewPageState();
}

class _WebviewPageState extends State<WebviewPage> {
  bool loading = true;
  bool _handledResult = false;
  late InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  useHybridComposition: true,
                  clearCache: true,
                ),

                /// 🔐 SSL trust
                onReceivedServerTrustAuthRequest:
                    (controller, challenge) async {
                  return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.PROCEED,
                  );
                },

                initialData: InAppWebViewInitialData(
                  data: _loadHTML(),
                ),

                onWebViewCreated: (controller) {
                  _controller = controller;
                },

                onLoadStart: (_, url) {
                  setState(() => loading = true);
                  debugPrint("🔄 LoadStart: $url");
                },

                /// ✅ FIXED SUCCESS / FAILURE HANDLING
                onLoadStop: (_, url) {
                  setState(() => loading = false);

                  if (url == null || _handledResult) return;

                  final pageUrl = url.toString();
                  debugPrint("✅ LoadStop: $pageUrl");

                  final result = _extractPaymentResult(pageUrl);
                  if (result == null) return;

                  _handledResult = true;

                  if (!mounted) return;

                  _showSnackBar(
                    isSuccess: result.isSuccess,
                    paymentId: result.transactionId,
                  );

                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (mounted) {
                      Navigator.pop(context, result.isSuccess);
                    }
                  });
                },

                shouldOverrideUrlLoading:
                    (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri == null || _handledResult) {
                    return NavigationActionPolicy.ALLOW;
                  }

                  final result = _extractPaymentResult(uri.toString());
                  if (result != null) {
                    _handledResult = true;

                    _showSnackBar(
                      isSuccess: result.isSuccess,
                      paymentId: result.transactionId,
                    );

                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (mounted) {
                        Navigator.pop(context, result.isSuccess);
                      }
                    });

                    return NavigationActionPolicy.CANCEL;
                  }

                  /// External UPI apps
                  if (uri.scheme == 'upi' ||
                      uri.scheme == 'phonepe' ||
                      uri.scheme == 'paytmmp' ||
                      uri.scheme == 'tez') {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    return NavigationActionPolicy.CANCEL;
                  }

                  return NavigationActionPolicy.ALLOW;
                },

                onLoadError: (_, __, ___, message) {
                  debugPrint("❌ WebView error: $message");

                  if (!_handledResult && mounted) {
                    _handledResult = true;
                    _showSnackBar(isSuccess: false);

                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (mounted) {
                        Navigator.pop(context, false);
                      }
                    });
                  }
                },
              ),

              if (loading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ PARSE RESULT FROM URL (SOURCE OF TRUTH)
  _PaymentResult? _extractPaymentResult(String url) {
    try {
      final uri = Uri.parse(url.replaceFirst('#/', ''));
      final status = uri.queryParameters['status'];
      if (status == null) return null;

      final isSuccess = status.toLowerCase() == 'success';

      return _PaymentResult(
        isSuccess: isSuccess,
        transactionId: uri.queryParameters['transaction_id'],
      );
    } catch (_) {
      return null;
    }
  }

  /// ✅ Snackbar
  void _showSnackBar({
    required bool isSuccess,
    String? paymentId,
  }) {
    final message = isSuccess
        ? 'Payment successful\nTransaction ID: ${paymentId ?? '-'}'
        : 'Payment failed or cancelled';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ Back button
  Future<bool> _onWillPop() async {
    if (_handledResult) return false;

    Navigator.pop(context, false);
    return false;
  }

  /// ✅ Auto-submit CCAvenue form
  String _loadHTML() {
    const url =
        "https://test.ccavenue.com/transaction/transaction.do?command=initiateTransaction";

    final encRequest = widget.data?.encVal ?? '';
    final accessCode = widget.data?.accessCode ?? '';

    return '''
<!DOCTYPE html>
<html>
<body>
  <form id="paymentForm" method="post" action="$url">
    <input type="hidden" name="encRequest" value="$encRequest" />
    <input type="hidden" name="access_code" value="$accessCode" />
  </form>
  <script>
    document.getElementById("paymentForm").submit();
  </script>
</body>
</html>
''';
  }
}

/// ✅ Result model
class _PaymentResult {
  final bool isSuccess;
  final String? transactionId;

  _PaymentResult({
    required this.isSuccess,
    this.transactionId,
  });
}
