import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../services/quiz_api.dart';
import '../services/shared_prefs_service.dart';
import '../widgets/loading_widget.dart';
import 'quiz_navigation.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  bool isLoading = true, dialogShown = false;
  bool isTimerEnabled = false;
  int timerDurationMinutes = 30;
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

  Future<void> _loadQuizData() async {
    setState(() => isLoading = true);
    final qp = Provider.of<QuizProvider>(context, listen: false);
    if (qp.quizId != null) await qp.loadQuizData(qp.quizId!);
    setState(() {
      isLoading = false;
      currentQuestionIndex = 0;
    });
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text('Quiz Timer', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Would you like to time this quiz?', style: GoogleFonts.montserrat()),
              SwitchListTile(
                title: Text('Enable Timer', style: GoogleFonts.montserrat()),
                value: isTimerEnabled,
                onChanged: (v) => setSt(() => isTimerEnabled = v),
              ),
              if (isTimerEnabled)
                Row(
                  children: [
                    Text('Duration (min):', style: GoogleFonts.montserrat()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '30',
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (v) => setSt(() => timerDurationMinutes = int.tryParse(v) ?? 30),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _startQuiz();
              },
              child: Text('Start Quiz', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _startQuiz() {
    if (isTimerEnabled) {
      _quizStartTime = DateTime.now();
      _secondsRemaining = timerDurationMinutes * 60;
      _startTimer();
      SharedPrefsService().setTimerPreference(isTimerEnabled);
      SharedPrefsService().setTimerDuration(timerDurationMinutes);
      SharedPrefsService().setQuizStartTime(_quizStartTime!);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _autoSubmitQuiz();
      }
    });
  }

  Future<void> _autoSubmitQuiz() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Time\'s up! Submitting...')));
    await _submitQuiz();
  }

  String get _formattedTime {
    final m = _secondsRemaining ~/ 60;
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _submitQuiz() async {
    try {
      final qp = Provider.of<QuizProvider>(context, listen: false);
      final quizId = qp.quizId;
      if (quizId == null) throw 'Quiz ID not found';

      final answers = qp.getSubmissionFormat();
      if (answers.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Answer at least one question')));
        return;
      }

      Map<String, dynamic> timerData = {};
      if (isTimerEnabled && _quizStartTime != null) {
        final taken = DateTime.now().difference(_quizStartTime!).inSeconds;
        timerData = {
          'timer_enabled': true,
          'duration_seconds': taken,
          'max_duration_minutes': timerDurationMinutes
        };
      }

      final result = await QuizApiService().submitQuizWithTimer(quizId, answers, timerData);
      _timer?.cancel();
      await qp.resetQuiz();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultsScreen(resultData: result)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error submitting: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final qp = Provider.of<QuizProvider>(context);
    final quizData = qp.quizData;

    if (isLoading || quizData.isEmpty) {
      return const Center(child: SimpleLoadingWidget());
    }

    final q = quizData[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(qp.quizTitle ?? 'Quiz', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isTimerEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _formattedTime,
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Question navigation
              QuizNavigationBar(
                currentIndex: currentQuestionIndex,
                questions: quizData,
                onQuestionTap: (i) => setState(() => currentQuestionIndex = i),
                answeredQuestions: qp.selectedAnswers,
              ),

              const SizedBox(height: 24),

              // Question text
              Text(
                'Q${currentQuestionIndex + 1}) ${q.text}',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

              // Options list
              Expanded(
                child: ListView.separated(
                  itemCount: q.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final opt = q.options[idx];
                    final selected = qp.getSelectedAnswer(q.id) == opt.id;
                    return GestureDetector(
                      onTap: () => qp.setSelectedAnswer(q.id, opt.id),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.black.withOpacity(0.1) : Colors.white,
                          border: Border.all(
                            color: selected ? Colors.black : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: selected ? Colors.black : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt.text,
                                style: GoogleFonts.montserrat(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Prev / Next buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: currentQuestionIndex > 0
                        ? () => setState(() => currentQuestionIndex--)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Previous', style: GoogleFonts.montserrat()),
                  ),
                  ElevatedButton(
                    onPressed: currentQuestionIndex < quizData.length - 1
                        ? () => setState(() => currentQuestionIndex++)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Next', style: GoogleFonts.montserrat()),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Submit Quiz', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                        content: Text('Are you sure you want to submit?', style: GoogleFonts.montserrat()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text('Cancel', style: GoogleFonts.montserrat()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Submit', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) await _submitQuiz();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Submit Quiz', style: GoogleFonts.montserrat(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}