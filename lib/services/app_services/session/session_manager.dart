class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  Map<String, dynamic>? sessionData;

  void setSessionData(Map<String, dynamic> data) {
    sessionData = data;
  }

  Map<String, dynamic>? getSessionData() {
    return sessionData;
  }
}
