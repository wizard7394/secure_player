import 'package:flutter/material.dart';

class FloatingWatermarkPainter extends CustomPainter {
  final String text;
  final double progressX;
  final double progressY;

  FloatingWatermarkPainter({
    required this.text,
    required this.progressX,
    required this.progressY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white.withValues(
        alpha: 0.10,
      ), // شفافیت به شدت پایین (۱۰ درصد)
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 4.0, // فاصله حروف بیشتر برای نامرئی‌تر شدن
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 4,
          offset: const Offset(1, 1),
        ),
      ],
    );

    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);

    // محاسبه فضایی که متن می‌تونه توش حرکت کنه بدون اینکه بیرون بزنه
    final availableWidth = size.width - textPainter.width;
    final availableHeight = size.height - textPainter.height;

    final safeWidth = availableWidth > 0 ? availableWidth : 0.0;
    final safeHeight = availableHeight > 0 ? availableHeight : 0.0;

    final dx = progressX * safeWidth;
    final dy = progressY * safeHeight;

    textPainter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant FloatingWatermarkPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.progressX != progressX ||
        oldDelegate.progressY != progressY;
  }
}
