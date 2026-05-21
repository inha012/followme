// 0:모험적 1:사색적 2:외향적 3:주도적 4:다정함 5:논리적
class Mission {
  const Mission({required this.text, required this.trait});
  final String text;
  final int trait; // 0~5

  static const traitLabels = ['모험적', '사색적', '외향적', '주도적', '다정함', '논리적'];

  String get traitLabel => trait >= 0 && trait < traitLabels.length
      ? traitLabels[trait]
      : '';

  Map<String, dynamic> toJson() => {'text': text, 'trait': trait};

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        text: json['text'] as String,
        trait: (json['trait'] as num).toInt(),
      );
}

class PredictionResult {
  const PredictionResult({
    required this.fortune,
    required this.missions,
    required this.date,
  });

  final String fortune;
  final List<Mission> missions;
  final String date; // YYYY-MM-DD

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
