class TopResult {
  final String label;
  final double confidence;

  TopResult({required this.label, required this.confidence});

  factory TopResult.fromJson(Map<String, dynamic> json) {
    return TopResult(
      label: json['label'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
      };
}

class ResultModel {
  final String label;
  final double confidence;
  final List<TopResult> topResults;

  ResultModel({
    required this.label,
    required this.confidence,
    required this.topResults,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    final rawTop = json['top_results'] as List<dynamic>? ?? [];
    return ResultModel(
      label: json['label'] ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      topResults: rawTop
          .map((e) => TopResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'top_results': topResults.map((e) => e.toJson()).toList(),
      };
}
