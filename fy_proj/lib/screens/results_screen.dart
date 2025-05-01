import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../resources/models.dart';
import '../services/shared_prefs_service.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ResultsScreen({Key? key, required this.resultData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quizResult = QuizResult.fromJson(resultData);
    final completedAt = DateTime.parse(quizResult.completedAt);
    final formattedDate =
        DateFormat('MMM dd, yyyy – hh:mm a').format(completedAt);
    final percentage = quizResult.score;
    final passed = percentage >= 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Quiz Results',
            style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // Score circle
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            passed ? Colors.green.shade50 : Colors.red.shade50,
                        border: Border.all(
                          color: passed ? Colors.green : Colors.red,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.montserrat(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: passed ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              passed ? 'Passed' : 'Failed',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: passed ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildStatRow('Correct Answers',
                        '${quizResult.correctAnswers}/${quizResult.totalQuestions}'),
                    const SizedBox(height: 12),
                    _buildStatRow('Completed On', formattedDate),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Recommendations Header
              Text(
                'Recommended Resources',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // No recommendations
              if (quizResult.recommendations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Text(
                    'No recommendations available at this time.',
                    style: GoogleFonts.montserrat(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              // List of recommendation cards
              ...quizResult.recommendations.map((rec) {
                IconData icon;
                switch (rec.resource.resourceType) {
                  case 1:
                    icon = Icons.video_library_rounded;
                    break;
                  case 2:
                    icon = Icons.article_rounded;
                    break;
                  case 3:
                    icon = Icons.picture_as_pdf_rounded;
                    break;
                  default:
                    icon = Icons.link_rounded;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final url = Uri.parse(rec.resource.url);
                        await launchUrl(url, mode: LaunchMode.inAppWebView);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child:
                                      Icon(icon, size: 24, color: Colors.black),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    rec.resource.title,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Relevance: ${(rec.relevanceScore * 100).toInt()}%',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13, color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              rec.resource.description,
                              style: GoogleFonts.montserrat(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: rec.resource.keywords.map((kw) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    kw.text,
                                    style: GoogleFonts.montserrat(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Return Home Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    SharedPrefsService().clearQuizData();
                    Navigator.popUntil(context, (r) => r.isFirst);
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
                  child: Text(
                    'Return to Home',
                    style: GoogleFonts.montserrat(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 15, color: Colors.grey.shade700)),
        Text(value,
            style: GoogleFonts.montserrat(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
