// Define a model class for Question
class Question {
  final int id;
  final String text;
  final String? imageUrl;
  final List<Option> options;

  Question({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.options,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      imageUrl: json['image'],
      options: (json['options'] as List)
          .map((option) => Option.fromJson(option))
          .toList(),
    );
  }
}

class Quiz {
  final int id;
  final String title;
  final String description;
  final int subject;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      subject: json['subject']
    );
  }
}

class Option {
  final int id;
  final String text;

  Option({
    required this.id,
    required this.text,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'],
      text: json['text'],
    );
  }
}

class Keyword {
  final int id;
  final String text;

  Keyword({
    required this.id,
    required this.text,
  });

  factory Keyword.fromJson(Map<String, dynamic> json) {
    return Keyword(
      id: json['id'],
      text: json['text'],
    );
  }
}

class Resource {
  final int id;
  final String title;
  final String description;
  final String url;
  final int resourceType;
  final List<Keyword> keywords;
  double rating;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.resourceType,
    required this.keywords,
    required this.rating,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
  // Handle the rating with proper type conversion
    double ratingValue = 0.0;
    // print("Rating from api response ${json["avrating"]}");
    if (json['average_rating'] != null) {
      if (json['average_rating'] is num) {
        ratingValue = (json['average_rating'] as num).toDouble();
      } else if (json['average_rating'] is String) {
        ratingValue = double.tryParse(json['average_rating']) ?? 0.0;
      }
    }

    return Resource(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      resourceType: json['resource_type'],
      keywords: (json['keywords'] as List)
          .map((keyword) => Keyword.fromJson(keyword))
          .toList(),
      rating: ratingValue,
    );
  }
}

class Recommendation {
  final int id;
  final Resource resource;
  final double relevanceScore;
  final String createdAt;
  final bool viewed;

  Recommendation({
    required this.id,
    required this.resource,
    required this.relevanceScore,
    required this.createdAt,
    required this.viewed,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'],
      resource: Resource.fromJson(json['resource']),
      relevanceScore: json['relevance_score'].toDouble(),
      createdAt: json['created_at'],
      viewed: json['viewed'],
    );
  }
}

class QuizResult {
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final String completedAt;
  final List<Recommendation> recommendations;

  QuizResult({
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.completedAt,
    required this.recommendations,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'].toDouble(),
      correctAnswers: json['correct_answers'],
      totalQuestions: json['total_questions'],
      completedAt: json['completed_at'],
      recommendations: json['recommendations'] != null
          ? (json['recommendations'] as List)
              .map((rec) => Recommendation.fromJson(rec))
              .toList()
          : [],
    );
  }
}

class UserStatistics {
  final int quizzesAttempted;
  final int quizzesCompleted;
  final int totalQuizzesAvailable;
  final double accuracyRate;
  final double averageScore;
  final String dateJoined;
  final String? weakestSubjectName;
  final int recommendationsReceived;
  final String? averageCompletionTime;
  final String? fastestQuizCompletion;
  final String? fastestQuizName;
  final String? slowestQuizCompletion;
  final String? slowestQuizName;
  final double quizCompletionRate;

  UserStatistics({
    required this.quizzesAttempted,
    required this.quizzesCompleted,
    required this.totalQuizzesAvailable,
    required this.accuracyRate,
    required this.averageScore,
    required this.dateJoined,
    this.weakestSubjectName,
    required this.recommendationsReceived,
    this.averageCompletionTime,
    this.fastestQuizCompletion,
    this.fastestQuizName,
    this.slowestQuizCompletion,
    this.slowestQuizName,
    required this.quizCompletionRate,
  });

  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      quizzesAttempted: json['quizzes_attempted'] ?? 0,
      quizzesCompleted: json['quizzes_completed'] ?? 0,
      totalQuizzesAvailable: json['total_quizzes_available'] ?? 0,
      accuracyRate: (json['accuracy_rate'] ?? 0.0).toDouble(),
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
      dateJoined: json['date_joined'] ?? '',
      weakestSubjectName: json['weakest_subject_name'],
      recommendationsReceived: json['recommendations_received'] ?? 0,
      averageCompletionTime: json['average_completion_time'],
      fastestQuizCompletion: json['fastest_quiz_completion'],
      fastestQuizName: json['fastest_quiz_name'],
      slowestQuizCompletion: json['slowest_quiz_completion'],
      slowestQuizName: json['slowest_quiz_name'],
      quizCompletionRate: (json['quiz_completion_rate'] ?? 0.0).toDouble(),
    );
  }
}

class QuizTimingData {
  final int quizId;
  final String quizTitle;
  final String date;
  final double durationMinutes;
  final int questionCount;
  final int correctAnswers;
  final double score;

  QuizTimingData({
    required this.quizId,
    required this.quizTitle,
    required this.date,
    required this.durationMinutes,
    required this.questionCount,
    required this.correctAnswers,
    required this.score,
  });

  factory QuizTimingData.fromJson(Map<String, dynamic> json) {
    return QuizTimingData(
      quizId: json['quiz_id'],
      quizTitle: json['quiz_title'],
      date: json['date'],
      durationMinutes: (json['duration_minutes'] ?? 0.0).toDouble(),
      questionCount: json['question_count'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
      score: (json['score'] ?? 0.0).toDouble(),
    );
  }
}

class SubjectPerformance {
  final String subjectName;
  final int attempts;
  final double averageScore;

  SubjectPerformance({
    required this.subjectName,
    required this.attempts,
    required this.averageScore,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    return SubjectPerformance(
      subjectName: json['subject_name'],
      attempts: json['attempts'] ?? 0,
      averageScore: (json['average_score'] ?? 0.0).toDouble(),
    );
  }
}