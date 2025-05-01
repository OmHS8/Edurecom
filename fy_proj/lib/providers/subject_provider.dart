import 'package:flutter/material.dart';
import '../services/shared_prefs_service.dart';
import 'package:fy_proj/screens/quiz_list_screen.dart';

class SubjectProvider extends ChangeNotifier {
  int? _selectedSubjectId;
  final SharedPrefsService _sharedPrefsService = SharedPrefsService();
  
  final List<String> subjects = [
    "Operating Systems",
    "Compiler Design",
    "Computer networks",
    "Data Structures and Algorithms"
  ];
  
  int? get selectedSubjectId => _selectedSubjectId;
  
  String? get selectedSubjectName => 
    _selectedSubjectId != null ? subjects[_selectedSubjectId!] : null;
  
  void selectSubject(int index, BuildContext context) {
    _selectedSubjectId = index;
    final subjectId = index + 1; // Incrementing to match the expected subject ID logic
    _sharedPrefsService.setSubjectId(subjectId);
    
    // Navigate to the quiz list screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizListScreen(
            subjectId: subjectId,
            subjectName: subjects[index],
          ),
        ),
      );
    }
    
    notifyListeners();
  }
}