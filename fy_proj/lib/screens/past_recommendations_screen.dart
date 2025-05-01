import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../resources/models.dart';
import '../services/quiz_api.dart';
import '../widgets/loading_widget.dart';
import '../widgets/resource_rating_widget.dart';

class PastRecommendationsScreen extends StatefulWidget {
  const PastRecommendationsScreen({super.key});

  @override
  State<PastRecommendationsScreen> createState() => _PastRecommendationsScreenState();
}

class _PastRecommendationsScreenState extends State<PastRecommendationsScreen> {
  late Future<List<Recommendation>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    setState(() {
      _recommendationsFuture = _fetchRecommendations();
    });
  }

  // Fetch recommendations from API
  Future<List<Recommendation>> _fetchRecommendations() async {
    return await QuizApiService().fetchUserRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Recommendation>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: SimpleLoadingWidget());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No past recommendations found.',
                style: GoogleFonts.lato(fontSize: 18),
              ),
            );
          }

          final recommendations = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              return _buildRecommendationCard(recommendations[index]);
            },
          );
        },
      ),
    );
  }

  // Helper method to build recommendation cards
  Widget _buildRecommendationCard(Recommendation recommendation) {
    // Determine icon based on resource type
    IconData resourceIcon;
    switch (recommendation.resource.resourceType) {
      case 1:
        resourceIcon = Icons.video_library;
        break;
      case 2:
        resourceIcon = Icons.article;
        break;
      case 3:
        resourceIcon = Icons.video_camera_back;
        break;
      default:
        resourceIcon = Icons.link;
    }

    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Icon(resourceIcon, size: 24, color: const Color.fromARGB(255, 173, 255, 252)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      recommendation.resource.title,
                      style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        final updatedRating = await showDialog<double>(
                          context: context,
                          builder: (context) => ResourceRatingDialog(
                            resourceId: recommendation.resource.id,
                            currentRating: recommendation.resource.rating,
                            onSubmit: (rating) => QuizApiService().submitResourceRating(recommendation.resource.id, rating),
                          ),
                        );

                        if (updatedRating != null) {
                          setState(() {
                            recommendation.resource.rating = updatedRating;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 168, 168, 168).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Color.fromARGB(255, 173, 255, 252), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              recommendation.resource.rating.toStringAsFixed(1),
                              style: GoogleFonts.lato(fontSize: 14, color: const Color.fromARGB(255, 255, 255, 255)),
                            ),
                          ],
                        ),
                      ),
                    )
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.resource.description,
                style: GoogleFonts.lato(fontSize: 15, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: recommendation.resource.keywords.map((keyword) {
                  return Chip(
                    label: Text(keyword.text, style: GoogleFonts.lato(fontSize: 14)),
                    backgroundColor: const Color.fromARGB(255, 173, 255, 252),
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
