// Lauf-Datenmodell — ein Lauf als BUENDEL roher Messpunkte (Zielarchitektur-Samen
// „Lauf = Buendel roher, spaeter signierter Sensordaten").
//
// Wichtige Rollentrennung (Roland 2026-07-20): Die App auf Handy ODER UHR gibt
// LIVE-Feedback (Tempo, Aktivitaetstyp, Warnung) — das ist ein BERATENDER
// Client-Klassifikator. Die VERBINDLICHE Wertung („zaehlt der Lauf fuer die
// Wette?") macht spaeter der SERVER ueber die (signierten) Rohdaten. Deshalb ist
// der Lauf hier ein B: der Wechsel „simuliert -> echt gemessen -> server-geprueft"
// ist nur ein Austausch der Datenquelle, kein Umbau.

/// Quelle der Rohdaten. Eine am Koerper getragene Uhr ist ein staerkerer
/// Vertrauensanker als ein Handy in der Tasche (Anti-Cheat). Heute simuliert.
enum RunSource { phone, watch }

extension RunSourceX on RunSource {
  String get label => this == RunSource.watch ? 'watch' : 'phone';
}

/// Aus dem Tempo abgeleiteter Aktivitaetstyp (beratender Client-Klassifikator).
/// Reihenfolge = Anspruch: walking < jogging < running.
enum ActivityType { walking, jogging, running }

extension ActivityTypeX on ActivityType {
  String get label => switch (this) {
        ActivityType.walking => 'walking',
        ActivityType.jogging => 'jogging',
        ActivityType.running => 'running',
      };
}

/// Tempo-Schwellen in Sekunden pro km (Produktentscheidung, jederzeit tunebar).
/// Kleiner = schneller = anspruchsvoller. running < 6:00 < jogging < 9:00 < walking.
const int kRunningMaxPace = 360; // 6:00 min/km
const int kJoggingMaxPace = 540; // 9:00 min/km

/// Ordnet ein momentanes Tempo (Sek/km) einem Aktivitaetstyp zu.
ActivityType classifyPace(int paceSecPerKm) {
  if (paceSecPerKm <= 0) return ActivityType.walking;
  if (paceSecPerKm <= kRunningMaxPace) return ActivityType.running;
  if (paceSecPerKm <= kJoggingMaxPace) return ActivityType.jogging;
  return ActivityType.walking;
}

/// Welchen Aktivitaetstyp verlangt die Sportart der Wette (fuer die Warnung)?
/// (Sport lebt in models/bet.dart; hier nur die Zuordnung, ohne Import-Zyklus:
/// running -> running, alles andere -> jogging.)
ActivityType requiredActivityForRunning(bool isRunning) =>
    isRunning ? ActivityType.running : ActivityType.jogging;

/// Ein roher Messpunkt (heute simuliert; spaeter GPS/Sensor, signiert).
class RunSample {
  final int tSec; // Sekunden seit Start
  final int meters; // kumulierte Distanz
  final int paceSecPerKm; // momentanes Tempo
  const RunSample({required this.tSec, required this.meters, required this.paceSecPerKm});

  ActivityType get activity => classifyPace(paceSecPerKm);
}

/// Ein zusammenhaengender Abschnitt EINES Aktivitaetstyps.
class RunSegment {
  final ActivityType type;
  final int meters;
  final int seconds;
  const RunSegment(this.type, this.meters, this.seconds);
}

/// Ein Lauf = Quelle + Buendel roher Punkte. Kennzahlen/Segmente werden abgeleitet.
class Run {
  final RunSource source;
  final List<RunSample> samples;
  const Run({required this.source, required this.samples});

  int get totalMeters => samples.isEmpty ? 0 : samples.last.meters;
  int get totalSeconds => samples.isEmpty ? 0 : samples.last.tSec;

  /// Durchschnittstempo in Sek/km (0, solange nichts zurueckgelegt).
  int get avgPaceSecPerKm =>
      totalMeters <= 0 ? 0 : (totalSeconds * 1000 / totalMeters).round();

  /// Distanz (Meter), die MINDESTENS im geforderten Typ zurueckgelegt wurde
  /// (gleicher oder anspruchsvollerer Typ zaehlt — running zaehlt fuer jogging).
  int qualifyingMeters(ActivityType required) {
    int m = 0;
    for (int i = 1; i < samples.length; i++) {
      if (samples[i].activity.index >= required.index) {
        m += (samples[i].meters - samples[i - 1].meters);
      }
    }
    return m;
  }

  /// Zusammenhaengende Segmente nach Aktivitaetstyp (fuer die Anzeige).
  List<RunSegment> get segments {
    final out = <RunSegment>[];
    for (int i = 1; i < samples.length; i++) {
      final t = samples[i].activity;
      final dm = samples[i].meters - samples[i - 1].meters;
      final ds = samples[i].tSec - samples[i - 1].tSec;
      if (out.isNotEmpty && out.last.type == t) {
        final s = out.removeLast();
        out.add(RunSegment(t, s.meters + dm, s.seconds + ds));
      } else {
        out.add(RunSegment(t, dm, ds));
      }
    }
    return out;
  }
}
