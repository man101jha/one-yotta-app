class AssetDataManager {
  static final AssetDataManager _instance = AssetDataManager._internal();

  factory AssetDataManager() {
    return _instance;
  }

  AssetDataManager._internal();

  Map<String, dynamic>? sessionData;

  void setAssetData(Map<String, dynamic> data) {
    sessionData = data;
  }

  Map<String, dynamic>? getAssetData() {
    return sessionData;
  }
}
