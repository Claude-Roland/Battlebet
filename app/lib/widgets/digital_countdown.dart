// Digital-Countdown (Katalog: `DigitalCountdown`).
// Zeigt eine Zeit-/Countdown-Zeichenkette in Sieben-Segment-Digitalziffern
// (Schrift DSEG7, passend zum Design-Font "Digital-7"). Ziffern und ':' werden
// digital gesetzt; Einheiten-Buchstaben (d/h/m) bleiben klein im normalen Font,
// da die Sieben-Segment-Schrift keine Buchstaben-Glyphen hat.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DigitalCountdown extends StatelessWidget {
  const DigitalCountdown(
    this.text, {
    super.key,
    this.digitSize = 22,
    this.color = const Color(0xFF9BD64B), // LCD-Gruen
  });

  final String text;
  final double digitSize;
  final Color color;

  static final _isDigit = RegExp(r'[0-9:]');

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[
      for (final ch in text.split(''))
        TextSpan(
          text: ch,
          style: _isDigit.hasMatch(ch)
              ? TextStyle(fontFamily: 'DSEG7', fontSize: digitSize, color: color, height: 1.0)
              : TextStyle(fontSize: digitSize * 0.55, color: AppColors.textMuted, fontWeight: FontWeight.w600),
        ),
    ];
    return RichText(text: TextSpan(children: spans));
  }
}
