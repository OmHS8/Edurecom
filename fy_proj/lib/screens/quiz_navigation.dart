import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../resources/models.dart';

class QuizNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<Question> questions;
  final void Function(int) onQuestionTap;
  final Map<int, int> answeredQuestions;

  const QuizNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.questions,
    required this.onQuestionTap,
    required this.answeredQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final qId = questions[index].id;
          final isAnswered = answeredQuestions.containsKey(qId);
          final isCurrent = index == currentIndex;

          Color bgColor;
          if (isCurrent) {
            bgColor = Colors.black;
          } else if (isAnswered) {
            bgColor = Colors.grey.shade800;
          } else {
            bgColor = Colors.grey.shade300;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onQuestionTap(index),
                splashColor: Colors.black.withOpacity(0.1),
                child: Container(
                  width:  40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!isCurrent)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCurrent || isAnswered ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
