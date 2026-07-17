// Rinnen-Trenner (Katalog: `GrooveDivider`, Design-Element "Trenn-Nut").
// 1:1 nach Rolands Trenn-Nut.svg: eine pillen-foermige, eingelassene Rinne mit
// vertikalem Verlauf (dunkel oben -> heller unten), eingerueckt vom Rand, mit
// vollstaendig runden Enden. Als nativer Gradient nachgebaut (statt SVG) ->
// gestochen scharf und leichtgewichtig; Farben/Stops sind exakt aus der SVG.

import 'package:flutter/material.dart';

class GrooveDivider extends StatelessWidget {
  const GrooveDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(2)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E212D), Color(0xFF32373D), Color(0xFF3C464C)],
          stops: [0.0, 0.52, 1.0],
        ),
      ),
    );
  }
}
