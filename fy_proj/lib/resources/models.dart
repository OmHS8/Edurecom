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
  final double rating;

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
    return Resource(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      url: json['url'],
      resourceType: json['resource_type'],
      keywords: (json['keywords'] as List)
          .map((keyword) => Keyword.fromJson(keyword))
          .toList(),
      rating: json['rating'] != null ? json['rating'].toDouble() : 0.0,
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