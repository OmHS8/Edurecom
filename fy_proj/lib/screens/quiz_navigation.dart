// quiz_navigation.dart
import 'package:flutter/material.dart';
import '../resources/models.dart';

class QuizNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<Question> questions;
  final Function(int) onQuestionTap;
  final Map<int, int> answeredQuestions;

  const QuizNavigationBar({
    super.key,
    required this.currentIndex,
    required this.questions,
    required this.onQuestionTap,
    required this.answeredQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        itemBuilder: (context, index) {
          // Get the actual question ID for this index
          int questionId = questions[index].id;
          
          // Check if this question has been answered by its ID
          bool isAnswered = answeredQuestions.containsKey(questionId);
          bool isCurrentQuestion = currentIndex == index;

          return GestureDetector(
            onTap: () => onQuestionTap(index),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentQuestion
                    ? Colors.blue
                    : isAnswered
                        ? const Color.fromARGB(225, 72, 208, 208)
                        : Colors.grey[300],
              ),
              child: Center(
                child: Text(
                  (index + 1).toString(),
                  style: TextStyle(
                    color: isCurrentQuestion || isAnswered ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
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