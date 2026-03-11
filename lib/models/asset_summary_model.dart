class AssetSummary {
  final int totalCount;
  final Map<String, int> assetTypeDetails;

  AssetSummary({
    required this.totalCount,
    required this.assetTypeDetails,
  });

  factory AssetSummary.fromJson(Map<String, dynamic> json) {
    final assetTypeDetails = Map<String, int>.from(json['assetTypeDetails']);
    return AssetSummary(
      totalCount: int.parse(json['totalCount']),
      assetTypeDetails: assetTypeDetails,
    );
  }
}
