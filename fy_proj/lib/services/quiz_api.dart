import 'dart:convert';
import 'package:fy_proj/services/auth_api_service.dart';
import 'package:http/http.dart' as http;
import '../resources/models.dart';


class QuizResponse {
  final int quizId;
  final String quizTitle;
  final int attemptId;
  final List<Question> questions;

  QuizResponse({
    required this.quizId,
    required this.quizTitle,
    required this.attemptId,
    required this.questions,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      quizId: json['quiz_id'],
      quizTitle: json['quiz_title'],
      attemptId: json['attempt_id'],
      questions: (json['questions'] as List)
          .map((question) => Question.fromJson(question))
          .toList(),
    );
  }
}


class QuizApiService {

  final String baseUrl = 'http://192.168.0.102:8000';

  QuizApiService._privateConstructor();

  static final QuizApiService _instance = QuizApiService._privateConstructor();

  factory QuizApiService() {
    return _instance;
  }
  
  // New method to fetch quizzes by subject ID
  Future<List<Quiz>> fetchQuizzesBySubject(int subjectId) async {
    final url = "$baseUrl/api/get-quizzes/?subject_id=$subjectId";
    final headers = await AuthApiService().getHeaders();
    final response = await http.get(
      Uri.parse(url),
      headers: headers
    );    
    
    if (response.statusCode == 200) {
      final jsData = json.decode(response.body);
      List<Quiz> quizzes = (jsData['quizzes'] as List)
          .map((quiz) => Quiz.fromJson(quiz))
          .toList();
      return quizzes;
    } else {
      throw Exception("Failed to fetch quizzes: ${response.statusCode}");
    }
  }

  Future<QuizResponse> fetchQuizQuestionsData(int quizId) async {
    final url = "$baseUrl/api/get-questions/?quiz_id=$quizId";
    final headers = await AuthApiService().getHeaders();
    final response = await http.get(
      Uri.parse(url),
      headers: headers
    );    
    
    if (response.statusCode == 200) {
      final jsData = json.decode(response.body);
      return QuizResponse.fromJson(jsData);
    } else {
      throw Exception("Failed to fetch quiz data: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> submitQuiz(int quizId, List<Map<String, dynamic>> answers) async {
    final url = "$baseUrl/api/submit-quiz/";
    final headers = await AuthApiService().getHeaders();
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: json.encode({
        'quiz_id': quizId,
        'answers': answers,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to submit quiz: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> submitQuizWithTimer(
    int quizId, 
    List<Map<String, dynamic>> answers,
    Map<String, dynamic> timerData
  ) async {
    final url = "$baseUrl/api/submit-quiz/";
    final headers = await AuthApiService().getHeaders();
    
    // Create the request body
    Map<String, dynamic> requestBody = {
      'quiz_id': quizId,
      'answers': answers,
    };

    // Add timer data if available
    if (timerData.isNotEmpty) {
      requestBody['timer_data'] = timerData;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        ...headers,
        "Content-Type": "application/json",
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to submit quiz: ${response.statusCode}");
    }
  }
}