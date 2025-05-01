import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ResourceRatingDialog extends StatefulWidget {
  final int resourceId;
  final double currentRating;
  final Future<double?> Function(double) onSubmit;

  const ResourceRatingDialog({
    Key? key,
    required this.resourceId,
    required this.currentRating,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ResourceRatingDialog> createState() => _ResourceRatingDialogState();
}

class _ResourceRatingDialogState extends State<ResourceRatingDialog> {
  double? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.currentRating;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Rate this Resource"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingBar.builder(
            initialRating: widget.currentRating,
            minRating: 1,
            direction: Axis.horizontal,
            itemCount: 5,
            itemSize: 30,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              _selectedRating = rating;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text("Submit"),
          onPressed: () async {
            if (_selectedRating != null) {
              final updatedRating = await widget.onSubmit(_selectedRating!);
              if (updatedRating != null) {
                Navigator.of(context).pop(updatedRating); // return updated value
              }
            }
          },
        ),
      ],
    );
  }
}
