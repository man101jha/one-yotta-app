class OrderDataManager {
  static final OrderDataManager _instance = OrderDataManager._internal();

  factory OrderDataManager() {
    return _instance;
  }

  OrderDataManager._internal();

  Map<String, dynamic>? sessionData;

  void setOrderData(Map<String, dynamic> data) {
    sessionData = data;
  }

  Map<String, dynamic>? getOrdersHeadDetails() {
    return sessionData;
  }
}
