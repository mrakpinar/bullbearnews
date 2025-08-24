class CoinAnalysisResult {
  final String coinName;
  final String analysis;
  final Map<String, dynamic> technicalIndicators;
  final String sentiment;
  final double confidence;
  final bool isError;

  CoinAnalysisResult({
    required this.coinName,
    required this.analysis,
    required this.technicalIndicators,
    required this.sentiment,
    required this.confidence,
    required this.isError,
  });
}
