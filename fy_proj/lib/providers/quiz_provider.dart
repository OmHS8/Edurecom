import 'package:flutter/foundation.dart';
import 'package:fy_proj/services/quiz_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../resources/models.dart';

class QuizProvider with ChangeNotifier {
  List<Question> _quizData = [];
  int? _quizId;
  int? _attemptId;
  String? _quizTitle;
  Map<int, int> _selectedAnswers = {}; // Stores selected answer indices by question ID

  QuizProvider._privateConstructor();

  static final QuizProvider _instance = QuizProvider._privateConstructor();

  factory QuizProvider() {
    return _instance;
  }

  int? get quizId => _quizId;
  int? get attemptId => _attemptId;
  String? get quizTitle => _quizTitle;
  List<Question> get quizData => _quizData;
  Map<int, int> get selectedAnswers => _selectedAnswers;

  // Fetch quiz data from API
  Future<void> loadQuizData(int quizId) async {
    // Clear previous quiz data
    await clearAnswers();
    
    final quizApiService = QuizApiService();
    final quizResponse = await quizApiService.fetchQuizQuestionsData(quizId);
    
    _quizData = quizResponse.questions;
    _quizId = quizResponse.quizId;
    _attemptId = quizResponse.attemptId;
    _quizTitle = quizResponse.quizTitle;
    
    await loadAnswersFromPrefs();
    notifyListeners();
  }

  // Get selected answer index for a question (returns null if not selected)
  int? getSelectedAnswer(int questionId) {
    return _selectedAnswers[questionId];
  }
  
  // Set selected answer index for a question
  Future<void> setSelectedAnswer(int questionId, int optionId) async {
    _selectedAnswers[questionId] = optionId;
    notifyListeners();
    await saveSelectedAnswerToPrefs(questionId, optionId);
  }

  // Save selected answer index to SharedPreferences
  Future<void> saveSelectedAnswerToPrefs(int questionId, int optionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('answer_${_quizId}_$questionId', optionId);
  }

  // Load selected answers from SharedPreferences
  Future<void> loadAnswersFromPrefs() async {
    if (_quizId == null) return;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedAnswers.clear();
    
    for (final question in _quizData) {
      int? optionId = prefs.getInt('answer_${_quizId}_${question.id}');
      if (optionId != null) {
        _selectedAnswers[question.id] = optionId;
      }
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> getSubmissionFormat() {
    List<Map<String, dynamic>> submission = [];
    
    // Include all questions in the quiz, not just answered ones
    for (var question in _quizData) {
      submission.add({
        'question_id': question.id,
        'selected_option_id': _selectedAnswers[question.id] ?? -1, // Use -1 or null to indicate unanswered
      });
    }
    
    return submission;
  }

  // Clear answers from memory and SharedPreferences for the current quiz
  Future<void> clearAnswers() async {
    if (_quizId != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Clear answers from preferences
      for (final question in _quizData) {
        await prefs.remove('answer_${_quizId}_${question.id}');
      }
      
      // Clear the selected answers map
      _selectedAnswers.clear();
      notifyListeners();
    }
  }

  // Reset quiz state completely (for use after submission)
  Future<void> resetQuiz() async {
    await clearAnswers();
    _quizData = [];
    _quizId = null;
    _attemptId = null;
    _quizTitle = null;
    notifyListeners();
  }
}