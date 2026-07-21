// Money — Geld als Betrag + Waehrung, nie als blosse Kommazahl.
// (Zielarchitektur-Samen 6.1: "Geld als Betrag in Cent + Waehrung statt double".)
//
// Warum: Kommazahlen (double) rechnen ungenau — 0.1 + 0.2 ergibt am Computer
// 0.30000000000000004. Bei Geld fuehrt das zu Rundungsfehlern. Deshalb halten
// wir Geld als GANZE Zahl in der KLEINSTEN Einheit (Cent) plus den ISO-Waehrungs-
// code ("EUR", "USD"). Eine Wette ist immer "einwaehrungsrein" (ein Pot = eine
// Waehrung), darum traegt jeder Betrag seine Waehrung mit sich.

/// Ein Geldbetrag in einer bestimmten Waehrung.
class Money {
  /// Betrag in der kleinsten Einheit (Cent). 1250 = 12,50.
  final int minor;

  /// ISO-4217-Waehrungscode, z. B. "EUR" oder "USD".
  final String currency;

  const Money(this.minor, this.currency);

  /// Bequemer Bau aus einem "grossen" Betrag: Money.of(12.50, 'EUR') = 1250 Cent.
  factory Money.of(num major, String currency) => Money((major * 100).round(), currency);

  /// Betrag als grosse Einheit (12.50) — nur fuer Anzeige/Berechnung, nicht zum Speichern.
  double get major => minor / 100;

  /// n-facher Betrag (z. B. Einsatz × Teilnehmer). Waehrung bleibt gleich.
  Money operator *(int n) => Money(minor * n, currency);

  /// Anteiliger Betrag (z. B. Pot × 0,9 nach 10 % Fee). Kaufmaennisch gerundet.
  Money scale(double factor) => Money((minor * factor).round(), currency);

  /// Ganzzahlig geteilt (z. B. Pot ÷ Durchhalter). Rest verfaellt (Cent-genau).
  Money dividedBy(int n) => Money(n == 0 ? minor : minor ~/ n, currency);

  /// Waehrungszeichen fuer die Anzeige; unbekannte Codes zeigen den Code selbst.
  String get symbol => switch (currency) {
        'EUR' => '€',
        'USD' => '\$',
        'GBP' => '£',
        _ => currency,
      };

  /// Anzeige mit Tausender-Trennung und zwei Nachkommastellen: "1,262.50 €".
  /// (EN-Basisformat: "," als Tausender, "." als Komma — Locale-Feinschliff spaeter.)
  String format() {
    final neg = minor < 0;
    final cents = minor.abs();
    final whole = (cents ~/ 100).toString();
    final frac = (cents % 100).toString().padLeft(2, '0');
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '${neg ? '-' : ''}${buf.toString()}.$frac $symbol';
  }

  /// Wie [format], aber OHNE Nachkommastellen — fuer enge Darstellungen
  /// (z. B. die Pot/Teilnehmer-Angabe in der Listen-Ueberzeile): "3,456 €".
  String formatWhole() {
    final neg = minor < 0;
    final whole = (minor.abs() ~/ 100).toString();
    final buf = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
      buf.write(whole[i]);
    }
    return '${neg ? '-' : ''}${buf.toString()} $symbol';
  }
}
