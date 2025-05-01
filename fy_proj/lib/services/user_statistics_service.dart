import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fy_proj/services/auth_api_service.dart';
import '../resources/models.dart';

class UserStatisticsApiService {
  final String baseUrl = 'http://localhost:8000';

  UserStatisticsApiService._privateConstructor();

  static final UserStatisticsApiService _instance = UserStatisticsApiService._privateConstructor();

  factory UserStatisticsApiService() {
    return _instance;
  }

  Future<UserStatistics> fetchUserStatistics() async {
    final url = '$baseUrl/api/user/statistics/';
    final headers = await AuthApiService().getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserStatistics.fromJson(data);
    } else {
      throw Exception('Failed to fetch user statistics: ${response.statusCode}');
    }
  }

  Future<List<QuizTimingData>> fetchQuizTimingData() async {
    final url = '$baseUrl/api/user/quiz-timing-data/';
    final headers = await AuthApiService().getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => QuizTimingData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch quiz timing data: ${response.statusCode}');
    }
  }

  Future<List<SubjectPerformance>> fetchSubjectPerformance() async {
    final url = '$baseUrl/api/user/subject-performance/';
    final headers = await AuthApiService().getHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => SubjectPerformance.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch subject performance: ${response.statusCode}');
    }
  }
}