// shared_prefs_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  // Singleton implementation
  static final SharedPrefsService _instance = SharedPrefsService._internal();
  
  factory SharedPrefsService() {
    return _instance;
  }
  
  SharedPrefsService._internal();

  // Get and set subject ID
  Future<void> setSubjectId(int subjectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('subject_id', subjectId);
  }

  Future<int?> getSubjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('subject_id');
  }

  // Timer preferences
  Future<void> setTimerPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_enabled', enabled);
  }

  Future<bool> getTimerPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('timer_enabled') ?? false;
  }

  Future<void> setTimerDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timer_duration', minutes);
  }

  Future<int> getTimerDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('timer_duration') ?? 30; // Default 30 minutes
  }

  // Quiz start time
  Future<void> setQuizStartTime(DateTime startTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quiz_start_time', startTime.toIso8601String());
  }

  Future<DateTime?> getQuizStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('quiz_start_time');
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  // Clear all quiz-related preferences
  Future<void> clearQuizData() async {
    final prefs = await SharedPreferences.getInstance();
    // Get all keys
    final keys = prefs.getKeys();
    
    // Remove all answer keys and timer data
    for (final key in keys) {
      if (key.startsWith('answer_') || 
          key == 'timer_enabled' || 
          key == 'timer_duration' ||
          key == 'quiz_start_time') {
        await prefs.remove(key);
      }
    }
  }
}