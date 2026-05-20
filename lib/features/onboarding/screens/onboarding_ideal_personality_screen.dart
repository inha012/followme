import 'package:flutter/material.dart';
import 'onboarding_personality_result_screen.dart';
import 'personality_questions.dart';
import 'personality_test_screen.dart';

class OnboardingIdealPersonalityScreen extends StatelessWidget {
  const OnboardingIdealPersonalityScreen({
    super.key,
    required this.userName,
    required this.myPersonalityScores,
  });

  final String userName;
  final List<int> myPersonalityScores;

  Widget _buildTitle(String givenName) {
    const titleStyle = TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w700,
      fontSize: 24,
      height: 32 / 24,
      color: Color(0xFF262626),
    );

    return Text.rich(
      TextSpan(
        style: titleStyle,
        children: [
          TextSpan(text: '$givenName님이 '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF6DA),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('추구하는 모습을', style: titleStyle),
            ),
          ),
          const TextSpan(text: ' 알려주세요'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final givenName = userName.length > 1 ? userName.substring(1) : userName;
    return PersonalityTestScreen(
      title: '$givenName님이 추구하는 모습을 알려주세요',
      subtitle: "이상향을 설정할게요.",
      accentColor: const Color(0xFFEEC22A),
      cardBgColor: const Color(0xFFFEF6DA),
      questions: kIdealQuestions,
      onComplete: (scores) => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnboardingPersonalityResultScreen(
            userName: userName,
            myPersonalityScores: myPersonalityScores,
            idealPersonalityScores: scores,
          ),
        ),
      ),
      titleWidget: _buildTitle(givenName),
    );
  }
}
