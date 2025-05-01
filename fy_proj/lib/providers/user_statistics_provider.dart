import 'package:flutter/material.dart';
import '../services/user_statistics_service.dart';
import '../resources/models.dart';

class UserStatisticsProvider extends ChangeNotifier {
  final UserStatisticsApiService _apiService = UserStatisticsApiService();
  
  UserStatistics? _statistics;
  List<QuizTimingData> _timingData = [];
  List<SubjectPerformance> _subjectPerformance = [];
  
  bool _isLoading = false;
  String? _error;
  
  UserStatistics? get statistics => _statistics;
  List<QuizTimingData> get timingData => _timingData;
  List<SubjectPerformance> get subjectPerformance => _subjectPerformance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadAllStatistics() async {
    _setLoading(true);
    _error = null;
    
    try {
      // Fetch all statistics in parallel
      final results = await Future.wait([
        _apiService.fetchUserStatistics(),
        _apiService.fetchQuizTimingData(),
        _apiService.fetchSubjectPerformance(),
      ]);
      
      _statistics = results[0] as UserStatistics;
      _timingData = results[1] as List<QuizTimingData>;
      _subjectPerformance = results[2] as List<SubjectPerformance>;
      
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }
  
  Future<void> refreshStatistics() async {
    try {
      _statistics = await _apiService.fetchUserStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> refreshTimingData() async {
    try {
      _timingData = await _apiService.fetchQuizTimingData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<void> refreshSubjectPerformance() async {
    try {
      _subjectPerformance = await _apiService.fetchSubjectPerformance();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Helper method to format duration string for UI display
  String formatDuration(String? durationString) {
    if (durationString == null) return 'N/A';
    
    // Parse the duration string (format: HH:MM:SS)
    final parts = durationString.split(':');
    if (parts.length != 3) return durationString;
    
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = double.parse(parts[2]);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}