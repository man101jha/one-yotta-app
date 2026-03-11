class FinancialsDataManager {
  static final FinancialsDataManager _instance = FinancialsDataManager._internal();

  factory FinancialsDataManager() {
    return _instance;
  }
  FinancialsDataManager._internal();

  Map<String, dynamic>? creditNotesData;
  List<dynamic> _paymentHistoryData = [];
  Map<String , dynamic>? invoicesData;
  Map<String , dynamic>? transactionData;
  Map<String , dynamic>? availableBalanceData;
  Map<String , dynamic>? usedExpiredBalanceData;

  void setFinancialsData(Map<String, dynamic> data) {
    creditNotesData = data;
  }

  Map<String, dynamic>? getFinancialsData() {
    return creditNotesData;
  }

void setPaymentHistoryData(List<dynamic> data) {
  _paymentHistoryData = data;
}

List<dynamic> getPaymentHistoryData() {
  return _paymentHistoryData;
}

voidSetInvoicesData(Map<String, dynamic> data){
  invoicesData=data;
}

Map<String, dynamic>? getInvoicesData(){
  return invoicesData;
}
void setTransactionData(Map<String, dynamic> data){
  transactionData=data;
}

Map<String, dynamic>? getTransactionData(){
  return transactionData;
}
void setAvailableBalanceData(Map<String, dynamic> data) {
  availableBalanceData = data;
}

Map<String, dynamic>? getAvailableBalanceData() {
  return availableBalanceData;
}
void setUsedExpiredBalanceData(Map<String, dynamic> data) {
  usedExpiredBalanceData = data;
}

Map<String, dynamic>? getUsedExpiredBalanceData() {
  return usedExpiredBalanceData;
}
}