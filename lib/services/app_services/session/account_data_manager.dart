class AccountDataManager {
  static final AccountDataManager _instance = AccountDataManager._internal();

  factory AccountDataManager() {
    return _instance;
  }

  AccountDataManager._internal();

  Map<String, dynamic>? sessionData;
  Map<String, dynamic>? btoStoData;


  void setAccountData(Map<String, dynamic> data) {
    sessionData = data;
  }

  Map<String, dynamic>? getAccountData() {
    return sessionData;
  }

  void setAccountStoBtoData(Map<String, dynamic> data) {
    btoStoData = data;
  }

  Map<String, dynamic>? getAccountStoBtoData() {
    return btoStoData;
  }
}
