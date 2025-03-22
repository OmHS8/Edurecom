import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../resources/models.dart';
import 'package:intl/intl.dart';
import '../services/shared_prefs_service.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const ResultsScreen({Key? key, required this.resultData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse the result data
    final QuizResult quizResult = QuizResult.fromJson(resultData);
    
    // Format the completed date
    final DateTime completedDate = DateTime.parse(quizResult.completedAt);
    final String formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(completedDate);
    
    // Calculate percentage
    final double percentage = (quizResult.score);
    final bool passed = percentage >= 50.0; // Assuming 60% is passing
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result summary card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Score circle
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: passed ? Colors.green.shade100 : Colors.red.shade100,
                        border: Border.all(
                          color: passed ? Colors.green : Colors.red,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: passed ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              passed ? 'Passed' : 'Failed',
                              style: TextStyle(
                                fontSize: 18,
                                color: passed ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Stats
                    _buildStatRow('Correct Answers', '${quizResult.correctAnswers}/${quizResult.totalQuestions}'),
                    _buildStatRow('Completion Time', formattedDate),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Recommendations section
            const Text(
              'Recommended Resources',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // No recommendations message if empty
            if (quizResult.recommendations.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recommendations available at this time.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              
            // List of recommendation cards
            ...quizResult.recommendations.map((recommendation) => 
              _buildRecommendationCard(context, recommendation)
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Clear quiz data and go to home
                      SharedPrefsService().clearQuizData();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Return to Home', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build stat rows
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build recommendation cards
  Widget _buildRecommendationCard(BuildContext context, Recommendation recommendation) {
    // Determine icon based on resource type
    IconData resourceIcon;
    switch (recommendation.resource.resourceType) {
      case 1: // Video
        resourceIcon = Icons.video_library;
        break;
      case 2: // Article
        resourceIcon = Icons.article;
        break;
      case 3: // PDF
        resourceIcon = Icons.picture_as_pdf;
        break;
      default:
        resourceIcon = Icons.link;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          final Uri url = Uri.parse(recommendation.resource.url);
          await launchUrl(url, mode: LaunchMode.inAppBrowserView);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(resourceIcon, size: 24, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.resource.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Relevance: ${(recommendation.relevanceScore * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.resource.description,
                style: const TextStyle(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: recommendation.resource.keywords.map((keyword) {
                  return Chip(
                    label: Text(
                      keyword.text,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.all(4),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}