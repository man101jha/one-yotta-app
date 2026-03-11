class TicketDataManager {
  static final TicketDataManager _instance = TicketDataManager._internal();

  factory TicketDataManager() {
    return _instance;
  }

  TicketDataManager._internal();

  Map<String, dynamic>? sessionData;
  Map<String, dynamic>? catSubData;
  Map<String, dynamic>? projectListData;
  Map<String, dynamic>? catSubDataServRequest;


  void setTicketData(Map<String, dynamic> data) {
    sessionData = data;
  }

  Map<String, dynamic>? getTicketData() {
    return sessionData;
  }


  void setCatSubcatData(Map<String, dynamic> data) {
    catSubData = data;
  }

  Map<String, dynamic>? getCatSubcatData() {
    return catSubData;
  }

   void setProjectListData(Map<String, dynamic> data) {
    projectListData = data;
  }

  Map<String, dynamic>? getProjectListData() {
    return projectListData;
  }

  void setCatSubDataServRequest(Map<String, dynamic> data) {
    catSubDataServRequest = data;
  }

  Map<String, dynamic>? getCatSubDataServRequest() {
    return catSubDataServRequest;
  }
}
