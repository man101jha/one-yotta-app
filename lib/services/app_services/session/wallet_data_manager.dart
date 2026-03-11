class WalletDataManager {
  static final WalletDataManager _instance = WalletDataManager._internal();
  factory WalletDataManager() => _instance;
  WalletDataManager._internal();
  Map<String, dynamic>? walletData;
  dynamic walletHistoryData;
  void setWalletData(Map<String, dynamic> data) {
    walletData = data;
  }

  void setWalletHistoryData(dynamic data) {
    walletHistoryData = data;
  }

  Map<String, dynamic>? getWalletData() {
    return walletData;
  }

  dynamic getWalletHistoryData() {
    return walletHistoryData;
  }
}
