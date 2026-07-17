// Verlaufs-Kurve (Katalog: `SportChart` / "bet data").
// Eine einfache Sparkline auf einem feinen Gitter — zeigt die Wertentwicklung
// einer Wette. MVP: die Datenpunkte kommen berechnet aus dem BetDetailScreen.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ValueChart extends StatelessWidget {
  const ValueChart({super.key, required this.data, this.height = 90});

  final List<double> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ChartPainter(data)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.data);

  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    // Feines Gitter
    final grid = Paint()
      ..color = const Color(0xFF333A43)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (int i = 0; i <= 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    if (data.length < 2) return;

    final maxV = data.reduce((a, b) => a > b ? a : b);
    final minV = data.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - ((data[i] - minV) / range) * size.height * 0.9 - size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final line = Paint()
      ..color = AppColors.price
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => oldDelegate.data != data;
}
