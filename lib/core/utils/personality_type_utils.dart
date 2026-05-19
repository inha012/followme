class PersonalityType {
  final String name;
  final String description;

  const PersonalityType({
    required this.name,
    required this.description,
  });
}

const List<PersonalityType> _personalityTypes = [
  PersonalityType(
    name: '앨리스형',
    description:
        '새로운 세계를 탐험하는 것을 좋아하며 호기심과 모험심이 가득한 자유로운 탐험가입니다.',
  ),
  PersonalityType(
    name: '어린왕자형',
    description:
        '사람과 감정의 의미를 깊이 들여다보며 혼자만의 생각과 상상을 소중히 여기는 사색가입니다.',
  ),
  PersonalityType(
    name: '피터팬형',
    description:
        '사람들과 함께 웃고 어울리는 순간에서 가장 큰 행복과 에너지를 얻는 분위기 메이커입니다.',
  ),
  PersonalityType(
    name: '빨간모자형',
    description:
        '자신만의 방식과 신념을 믿고 두려움 없이 앞으로 나아가는 독립적인 개척자입니다.',
  ),
  PersonalityType(
    name: '백설공주형',
    description:
        '주변 사람들의 감정을 세심하게 살피고 따뜻한 다정함으로 관계를 돌보는 공감형 치유자입니다.',
  ),
  PersonalityType(
    name: '도로시형',
    description:
        '복잡한 상황 속에서도 현실적으로 판단하며 문제의 해답을 끝까지 찾아가는 이성적인 해결사입니다.',
  ),
];

PersonalityType classifyPersonality(List<int> scores, {String? gender}) {
  final normalizedScores = List<int>.generate(
    6,
    (index) => index < scores.length ? scores[index] : 0,
  );

  final maxScore = normalizedScores.reduce((a, b) => a >= b ? a : b);
  final tiedIndices = normalizedScores
      .asMap()
      .entries
      .where((entry) => entry.value == maxScore)
      .map((entry) => entry.key)
      .toList();

  if (tiedIndices.length == 1) {
    return _personalityTypes[tiedIndices.first];
  }

  final priority = _tieBreakPriority(gender);
  final chosenIndex = priority.firstWhere(
    (index) => tiedIndices.contains(index),
    orElse: () => tiedIndices.first,
  );
  return _personalityTypes[chosenIndex];
}

List<int> _tieBreakPriority(String? gender) {
  const femalePriority = [1, 4, 0, 2, 5, 3];
  const malePriority = [1, 5, 0, 3, 4, 2];

  if (gender != null && gender.toUpperCase() == 'M') {
    return malePriority;
  }

  return femalePriority;
}
