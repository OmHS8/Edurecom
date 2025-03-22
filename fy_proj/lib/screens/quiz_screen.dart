import 'package:flutter/material.dart';
import 'package:fy_proj/services/quiz_api.dart';
import 'package:fy_proj/widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../services/shared_prefs_service.dart';
import 'quiz_navigation.dart';
import 'results_screen.dart';
import 'dart:async';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  bool isLoading = true;
  bool dialogShown = false;
  
  // Timer variables
  bool isTimerEnabled = false;
  int timerDurationMinutes = 30; // Default timer duration
  Timer? _timer;
  int _secondsRemaining = 0;
  DateTime? _quizStartTime;

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show dialog after the first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isLoading && !dialogShown && mounted) {
        _showTimerDialog();
        dialogShown = true;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Load quiz data and subject ID
  Future<void> _loadQuizData() async {
    setState(() {
      isLoading = true;
    });
    
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final quizId = quizProvider.quizId;
    
    if (quizId != null) {
      await quizProvider.loadQuizData(quizId);
    }
    
    setState(() {
      isLoading = false;
      currentQuestionIndex = 0; // Reset to first question when loading new quiz
    });
  }

  // Show dialog to ask if user wants to time the quiz
  void _showTimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Quiz Timer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Would you like to time this quiz?'),
                  SwitchListTile(
                    title: const Text('Enable Timer'),
                    value: isTimerEnabled,
                    onChanged: (value) {
                      setState(() {
                        isTimerEnabled = value;
                      });
                    },
                  ),
                  if (isTimerEnabled)
                    Row(
                      children: [
                        const Text('Duration (minutes): '),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '30',
                            ),
                            onChanged: (value) {
                              setState(() {
                                timerDurationMinutes = int.tryParse(value) ?? 30;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startQuiz();
                  },
                  child: const Text('Start Quiz'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Start the quiz with or without timer
  void _startQuiz() {
    setState(() {
      if (isTimerEnabled) {
        _quizStartTime = DateTime.now();
        _secondsRemaining = timerDurationMinutes * 60;
        _startTimer();
        
        // Save timer preferences
        SharedPrefsService().setTimerPreference(isTimerEnabled);
        SharedPrefsService().setTimerDuration(timerDurationMinutes);
        SharedPrefsService().setQuizStartTime(_quizStartTime!);
      }
    });
  }

  // Start the timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _autoSubmitQuiz();
        }
      });
    });
  }

  // Auto-submit quiz when time is up
  Future<void> _autoSubmitQuiz() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time\'s up! Submitting quiz...')),
    );
    await _submitQuiz();
  }

  // Format time remaining for display
  String get _formattedTimeRemaining {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Submit quiz function
  Future<void> _submitQuiz() async {
    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final quizId = quizProvider.quizId;

      if (quizId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quiz ID not found!")),
        );
        return;
      }

      final answers = quizProvider.getSubmissionFormat();

      if (answers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please answer at least one question!')),
        );
        return;
      }

      // Calculate time taken
      Map<String, dynamic> timerData = {};
      if (isTimerEnabled && _quizStartTime != null) {
        final endTime = DateTime.now();
        final durationSeconds = endTime.difference(_quizStartTime!).inSeconds;
        timerData = {
          'timer_enabled': true,
          'duration_seconds': durationSeconds,
          'max_duration_minutes': timerDurationMinutes
        };
      }

      final result = await QuizApiService().submitQuizWithTimer(quizId, answers, timerData);
      
      // Cancel timer if active
      _timer?.cancel();
      
      // Reset the quiz data after successful submission
      await quizProvider.resetQuiz();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => ResultsScreen(resultData: result),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting quiz: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var quizProvider = Provider.of<QuizProvider>(context);
    var quizData = quizProvider.quizData;

    // Show loading indicator if loading or no quiz data is available
    if (isLoading || quizData.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    // Get the current question data
    var currentQuestionData = quizData[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(quizProvider.quizTitle ?? 'Quiz'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(225, 138, 249, 255),
        actions: [
          // Timer display
          if (isTimerEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  _formattedTimeRemaining,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Navigation bar - passing the full questions list
                QuizNavigationBar(
                  currentIndex: currentQuestionIndex,
                  questions: quizData,
                  onQuestionTap: (index) {
                    setState(() {
                      currentQuestionIndex = index;
                    });
                  },
                  answeredQuestions: quizProvider.selectedAnswers,
                ),
                // Display current question
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Q${currentQuestionIndex + 1}) ${currentQuestionData.text}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Display options using ListView.builder
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestionData.options.length,
                    itemBuilder: (context, index) {
                      final option = currentQuestionData.options[index];
                      bool isSelected = quizProvider.getSelectedAnswer(currentQuestionData.id) == option.id;

                      return GestureDetector(
                        onTap: () {
                          quizProvider.setSelectedAnswer(currentQuestionData.id, option.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color.fromARGB(225, 72, 208, 208).withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? const Color.fromARGB(225, 72, 208, 208) : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: RadioListTile<int>(
                            title: Text(option.text),
                            value: option.id,
                            groupValue: quizProvider.getSelectedAnswer(currentQuestionData.id),
                            activeColor: const Color.fromARGB(225, 72, 208, 208),
                            onChanged: (value) {
                              if (value != null) {
                                quizProvider.setSelectedAnswer(currentQuestionData.id, value);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Navigation buttons (Previous and Next)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: currentQuestionIndex > 0
                          ? () {
                              setState(() {
                                currentQuestionIndex--;
                              });
                            }
                          : null, // Disable if on the first question
                      child: const Text('Previous', style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      onPressed: currentQuestionIndex < quizData.length - 1
                          ? () {
                              setState(() {
                                currentQuestionIndex++;
                              });
                            }
                          : null, // Disable if on the last question
                      child: const Text('Next', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                // Submit button (confirmation dialog for submitting quiz)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      bool? confirmSubmit = await _showSubmitConfirmationDialog(context);
                      if (confirmSubmit == true) {
                        await _submitQuiz();
                      }
                    },
                    child: const Text('Submit', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Confirmation dialog for quiz submission
  Future<bool?> _showSubmitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Submit Quiz'),
          content: const Text('Are you sure you want to submit the quiz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}