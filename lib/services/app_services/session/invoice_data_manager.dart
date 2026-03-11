class InvoiceDataManager {
  static final InvoiceDataManager _instance = InvoiceDataManager._internal();

  factory InvoiceDataManager() {
    return _instance;
  }

  InvoiceDataManager._internal();

  Map<String, dynamic>? sessionData;

  void setInvoiceData(Map<String, dynamic> data) {
    sessionData = data;
  }

  Map<String, dynamic>? getInvoiceData() {
    return sessionData;
  }
}
