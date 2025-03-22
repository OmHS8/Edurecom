import 'package:flutter/material.dart';
import 'package:fy_proj/providers/quiz_provider.dart';
import 'package:fy_proj/resources/models.dart';
import 'package:fy_proj/screens/quiz_screen.dart';
import 'package:fy_proj/services/quiz_api.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizListScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const QuizListScreen({
    Key? key, 
    required this.subjectId, 
    required this.subjectName
  }) : super(key: key);

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final QuizApiService _quizApiService = QuizApiService();
  final QuizProvider _quizProvider = QuizProvider();
  late Future<List<Quiz>> _quizzesFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quizzesFuture = _quizApiService.fetchQuizzesBySubject(widget.subjectId);
  }

  void _startQuiz(Quiz quiz) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _quizProvider.loadQuizData(quiz.id);
      if (mounted) {
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => const QuizScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load quiz: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName} Quizzes'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        shadowColor: Colors.black,
        elevation: 10,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Quiz>>(
              future: _quizzesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading quizzes: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No quizzes available for this subject.'),
                  );
                }
                
                final quizzes = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Quizzes',
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: quizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = quizzes[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _startQuiz(quiz),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.quiz,
                                            color: Colors.teal,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              quiz.title,
                                              style: GoogleFonts.lato(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 40),
                                        child: Text(
                                          quiz.description,
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}