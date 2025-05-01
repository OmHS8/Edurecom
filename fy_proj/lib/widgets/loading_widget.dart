import 'package:flutter/material.dart';
import 'dart:math' as math;

class SimpleLoadingWidget extends StatefulWidget {
  const SimpleLoadingWidget({super.key});

  @override
  State<SimpleLoadingWidget> createState() => _SimpleLoadingWidgetState();
}

class _SimpleLoadingWidgetState extends State<SimpleLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: CustomPaint(
                painter: BWLoadingPainter(
                  progress: _controller.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BWLoadingPainter extends CustomPainter {
  final double progress;

  BWLoadingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    // Draw the dots in a pattern
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 4; i++) {
      final double offset = i * 0.25;
      final double completeness = (progress + offset) % 1.0;
      final double dotRadius = radius * 0.15 * (1.0 - completeness * 0.5);
      
      // Position dots on four corners moving toward center
      double angle = i * math.pi / 2;
      double distanceFromCenter = radius * 0.6 * (1.0 - completeness);
      
      final dotX = center.dx + math.cos(angle) * distanceFromCenter;
      final dotY = center.dy + math.sin(angle) * distanceFromCenter;
      
      // Alternate black and white dots
      if (i % 2 == 0) {
        paint.color = Colors.black;
      } else {
        paint.color = Colors.grey.shade500;
      }
      
      canvas.drawCircle(Offset(dotX, dotY), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(BWLoadingPainter oldDelegate) => 
    oldDelegate.progress != progress;
}