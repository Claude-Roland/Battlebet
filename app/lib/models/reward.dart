// Belohnungen (Socken / Lorbeer / Batches) — SAMEN fuer spaeter.
//
// Roland 2026-07-20: Socken, Lorbeer und Batches sollen JETZT so angelegt sein,
// dass wir sie SPAETER live im Recorder nachruesten koennen — ohne Umbau. Deshalb
// steht hier heute nur das Modell + eine (bewusst leere) Ableitung. Die
// Live-Einblendung waehrend des Laufs und der Abschluss-Screen werden erst dann
// gebaut, wenn wir die Belohnungen scharf schalten.
//
// Architektur-Prinzip (wie bei den Segmenten im Lauf): Belohnungen werden aus dem
// ROHEN Lauf ABGELEITET — sie sind kein zusaetzlicher Zustand, den man mitschleppt
// oder synchron halten muss. Heute liefert die Ableitung []; spaeter fuellen wir
// nur die Regeln. Der Lauf selbst bleibt unveraendert, und weil der Server ueber
// dieselben Rohdaten urteilt, kann er dieselben Regeln anwenden.

import 'run.dart';

/// Art der Belohnung. Reihenfolge ist frei — nur ein stabiler Samen fuer spaeter.
/// (Rolands Begriffe: Socke, Lorbeer, Batch.)
enum RewardKind { sock, laurel, batch }

extension RewardKindX on RewardKind {
  String get label => switch (this) {
        RewardKind.sock => 'Socke',
        RewardKind.laurel => 'Lorbeer',
        RewardKind.batch => 'Batch',
      };
}

/// Eine vergebene Belohnung: WAS (kind) und WOFUER (reason) — plus optionaler
/// Anker im Lauf (Sekunde/Meter), damit die spaetere Live-Anzeige weiss, WANN die
/// Belohnung aufpoppt. Heute nur ein Traeger; wird noch nirgends erzeugt.
class Reward {
  final RewardKind kind;
  final String reason; // z. B. "5 km am Stueck gejoggt" — Text ist Platzhalter
  final int? atSec; // wann im Lauf verdient (fuer die Live-Einblendung), optional
  final int? atMeters; // bei welchem Meter verdient, optional
  const Reward(this.kind, this.reason, {this.atSec, this.atMeters});
}

/// Leitet die Belohnungen eines Laufs ab. HEUTE SAMEN: liefert bewusst eine leere
/// Liste — die Regeln (welche Leistung gibt welche Socke/welchen Lorbeer/Batch)
/// legen wir fest, wenn wir die Belohnungen scharf schalten. Die Signatur bleibt
/// dann gleich, nur der Rumpf fuellt sich. Genau das meint „spaeter nachruesten".
List<Reward> evaluateRewards(Run run) {
  // TODO(spaeter): Regeln definieren und den Lauf (run.segments / run.samples /
  // run.qualifyingMeters) auswerten, z. B.
  //   - Socke   je X km im geforderten Tempo
  //   - Lorbeer fuer einen komplett qualifizierten Lauf
  //   - Batch   fuer Meilensteine (erste 5 km, Bestzeit, Lauf-Serie ...)
  // Der Parameter `run` ist heute schon da, damit die Aufrufstelle spaeter
  // unveraendert bleibt.
  return const <Reward>[];
}
