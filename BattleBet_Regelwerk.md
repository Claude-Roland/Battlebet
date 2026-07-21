# BattleBet — Regelwerk & Rahmenbedingungen

*Lebendiges Dokument · Stand 2026-07-21 · einzige Wahrheit für Ökonomie und Spielregeln.*
*Wird bei jeder Entscheidung mitaktualisiert. Geht älteren, verstreuten Notizen vor (u. a. Abschnitt 8 der Zielarchitektur, „Fee 10 % vom Pot", Bronze/Silber/Obsidian-Namen).*

---

## 1. Konzept

BattleBet ist eine Fitness-/Lauf-App mit Wett-Mechanik: „Bet on yourself". Man setzt Geld darauf, ein Lauf­pensum durchzuhalten. Wer durchhält, bekommt seinen Einsatz zurück plus einen Anteil am Geld derer, die aufgeben. Die Plattform verdient nur an den Aussteigern.

**Kern-Versprechen:** *Wer sein Pensum durchhält, verliert nie Geld.* Jeder Durchhalter bekommt mindestens seinen Einsatz zurück; Gewinn entsteht allein aus dem Geld der Aussteiger.

---

## 2. Zugangs-Leiter — Bet Tier 1 / 2 / 3

Nummerische Vertrauens-/Zugangsstufe (bewusst getrennt von den sportlichen Metall-Stufen von SOCKS/Batches). Ein Nutzer *hat* eine Bet-Tier-Stufe (verdient, server-geprüft), ein Pot *fordert* eine Stufe. Regel: **Nutzer-Tier ≥ Pot-Tier** steuert Eröffnen und Beitreten. Gesperrtes wird ausgegraut gezeigt — als Anreiz.

- **Bet Tier 1 · Limited** — kleiner Deckel (z. B. 500), offen für alle.
- **Bet Tier 2 · Limited** — großer Deckel (z. B. 2000).
- **Bet Tier 3 · offen** — kein Deckel, „nie voll".

---

## 3. Pot-Ökonomie

Alles in **einer Währung pro Wette**; Geld als **Cent + ISO-Code** (nie als Kommazahl).

1. **Einsatz** — fester Betrag je Teilnehmer.
2. **Pot** — Summe aller Einsätze.
3. **Aussteiger** verwirken ihr eingezahltes Geld → „Aussteiger-Topf".
4. **Gebühr = 10 % vom Aussteiger-Geld** (nicht vom ganzen Pot, keine Schwelle). Fällt nur an, wenn jemand aussteigt. Steigt niemand aus → keine Gebühr, jeder bekommt genau seinen Einsatz zurück, Plattform verdient null.
5. **Auszahlung je Durchhalter** = eigener Einsatz + (Aussteiger-Geld − Gebühr) ÷ Anzahl Durchhalter. Immer ≥ Einsatz.
6. **Wertzuwachs** (Anzeige) = abgeleitet = (Aussteiger-Geld − Gebühr) ÷ (Durchhalter × Einsatz). Immer ≥ 0 — die Anzeige zeigt nie einen Verlust.

**Beispiel:** 10 × 10 € = 100 € Pot. 3 steigen aus (30 € verwirkt). Gebühr = 3 €. 7 Durchhalter bekommen je 10 € + (30 − 3) ÷ 7 = **13,86 €**. Plattform: 3 €. Keiner unter dem Einsatz. — Steigt niemand aus: jeder 10 € zurück, Plattform 0 €.

*(Server-seitig verifiziert: 3 × 10 €, 1 Aussteiger → Durchhalter je 14,50 €, Gebühr 1 €, kein Cent verschwindet.)*

**Kein Pensum-Zuschlag** (frühere Idee, verworfen): würde „wer durchhält verliert nie" verletzen und ist unnötig.

---

## 4. Pensum & Wochen-Takt

- Eine **Woche = 7 Tage** ist die Takt-Einheit. Eine Wette dauert eine **ganze Zahl von Wochen** — nie krumm, also nie eine angebrochene Woche.
- Das **Wochen-Pensum** = geforderte Läufe pro Woche (z. B. 3×/Woche). Ein Lauf *qualifiziert* für eine Wette, wenn er ihre Anforderung erfüllt: Distanz erreicht, Tempo-/Aktivitätstyp mindestens gefordert, Sportart passt.
- **Wochen-Checkpoint mit Auto-Ausstieg:** An jeder Wochengrenze prüft der Server je aktivem Teilnehmer, ob das Wochen-Pensum erfüllt ist. Wer es verpasst, ist **automatisch ausgestiegen** (Einsatz verwirkt). **Eine verpasste Woche = endgültig raus**, kein Nachholen *(später evtl. eine sanftere „Einsteiger"-Klausel)*.
- Dadurch **gatet das Pensum die Auszahlung von selbst:** am Ende sind die noch Aktiven genau die, die jede Woche geliefert haben — die echten Durchhalter.

**Kein freiwilliges Aussteigen:** Es gibt keinen Knopf, mit dem man die Wette bewusst hinschmeißt — der einzige Weg zu verlieren ist, die Arbeit nicht zu tun. „**Abbrechen**" bedeutet nur: die *aktuelle Lauf-Aufnahme* bewusst verwerfen (kein Geld-Effekt). Die Teilnahme ist damit verbindlich (Härtefall → Abschnitt 8).

**Erinnerung:** Zwei Tage vor dem Wochen-Ende, wenn das Wochen-Pensum noch nicht erfüllt ist, wird erinnert. Echte Push aufs Handy braucht die mobile App + Entwickler-Konten; solange wir im Web/Test laufen, ist es ein In-App-Banner („Diese Woche fehlen dir noch X Läufe, Frist in 2 Tagen").

---

## 5. Einstieg

**Limitierte Pots (Tier 1/2) — 7-Tage-Anmeldung, dann Synchronstart.**
Nach dem Einstellen läuft ein **festes 7-Tage-Anmeldefenster**. Wer in diesen Tagen beitritt, ist gleichgestellt. Bei Fensterschluss **startet die Wette für alle gemeinsam** — identische Uhr, identisches Pensum, kein Nachteil fürs späte Beitreten (das einstiegsfreundlichste Modell). Preis = flacher Einsatz.
- **Mindestens 3 Teilnehmer:** sind bei Fensterschluss weniger dabei, wird die Wette **abgesagt und alle Einsätze zurückgezahlt** (auch der des Erstellers).
- **Countdown im Fenster:** „startet in X Tagen · N dabei" — macht aus Warten Vorfreude.
- **Zwei Uhren:** „eingestellt" (Anmeldefenster + „Neu"-Sortierung) ab dem Einstellen; „Pensum-Uhr" ab Anmeldeschluss.

**Offene Pots (Tier 3) — jederzeit, anteilig.**
Start sofort ab dem Einstellen, Einstieg jederzeit. Preis = **aktueller Anteilswert** (Einsatz + aufgelaufener Wertzuwachs) — damit verschiebt ein Späteinstieg bei den Bestehenden keinen Cent. Das Pensum der angebrochenen **Einstiegs-Woche** ist anteilig:

> noch zu laufen = **aufgerundet( Pensum × Resttage der Woche ÷ 7 )**

Bei 3×/Woche: 3 Resttage → 2 Läufe, 2 Resttage → 1 Lauf. Aufgerundet, also **zugunsten der Länger-Dabei**. Ab der nächsten vollen Woche gilt das volle Pensum.

---

## 6. Entkoppelte Lauf-Uhr

Die Uhr ist **nicht** an eine einzelne Wette gekoppelt. Ein Lauf ist ein eigenständiges Ding (Distanz, Tempo, Zeit, Rohdaten); der Server gleicht ihn gegen **alle** aktiven Wetten ab. Damit kann **ein Lauf das Pensum mehrerer Wetten zugleich erfüllen**.

Gebaut wird das **entkoppelt** (die Obermenge): Läufe stehen für sich, plus ein Schalter „ein Lauf zählt für *alle passenden* Wetten / nur für *seine Heim-Wette*", Standard = **alle passenden**. Entkoppelt kann hartes Koppeln jederzeit nachbilden — umgekehrt nicht. So bleibt die Produkt-Entscheidung offen.

---

## 7. Überlappungs-Deckel

**Höchstens 3 überlappende Wetten gleichzeitig.** Man darf zu einem Zeitpunkt aktiver Teilnehmer in maximal drei Wetten sein (eine limitierte Wette im Anmeldefenster zählt mit — der Einsatz ist gebunden). Eine vierte annehmen, während drei laufen, wird blockiert, bis eine endet.

**Warum:** Da ein einziges Trainingspensum mehrere Pötte gleichzeitig bedient, bleibt der Aufwand konstant, aber der Gewinn (aus Aussteiger-Geld) wächst mit der Zahl der Pötte. Ohne Deckel könnten sehr fitte Läufer schwächere im Schnitt „abziehen". Der Deckel begrenzt den Effizienzvorteil auf das Dreifache. **3 ist ein Startwert und nachjustierbar.** (Die Grund-Asymmetrie „Fitte verlieren nie, finanziert von den Aussteigern" ist gewollt — sie ist der Anreiz, das Pensum zu machen.)

---

## 8. Ausfallkontingent / Ein-Lauf-Gnade *(Design steht, Bau später)*

Ein Härtefall-Puffer für Verletzung/Krankheit:

- **Ein-Lauf-Gnade** verzeiht **einen** fehlenden Lauf einer Woche. Modelliert als „**fügt der Woche einen virtuellen qualifizierenden Lauf hinzu**" — so deckt der eine Joker den Ausfall über *alle* überlappenden Wetten zugleich, nicht pro Wette einen.
- **Verdienen:** erstmals nach **3 Monaten kontinuierlicher Teilnahme** (Wetten überlappend oder direkt hintereinander, mit einer Lücke von **max. 4 Tagen**; größere Lücke setzt die Uhr zurück). Nach Nutzung kommt der nächste Joker erst nach weiteren 3 Monaten.
- **Sichtbar im Profil:** wann man den ersten bekommt bzw. nach Nutzung den nächsten — und der Kontinuitäts-/Lücken-Status.

Jetzt wird nur der Datenplatz dafür angelegt; gebaut wird es, wenn es dran ist.

---

## 9. Technischer Rahmen

- **App:** Flutter (Dart), pixelgenaue Custom-UI, Cross-Platform. UI-Sprache Englisch als Basis.
- **Server:** eigenes Backend auf Hetzner, **Dart Frog + PostgreSQL** — der Server ist die einzige Wahrheit (Konten, Wetten, Läufe, Urteil, Geld-Ledger). Läuft lokal, end-to-end getestet.
- **Geld:** immer Test-Credits, bis die echte Geld-Schicht kommt (reguliert, zuletzt). Echtes Geld = der letzte Schalter.
- **Domain:** battlebet.app (bei Porkbun). Deploy folgt (eigener kleiner Server empfohlen, damit die bestehende Verkaufs-Infrastruktur nie gefährdet ist).
- **Stufenplan:** 0 lokaler Prototyp ✓ → **A** Server-Durchstich (Konten + Wetten/Läufe, Test-Geld) *läuft* → B echte Sensoren + Anti-Cheat/Attestierung → C echtes Geld.

---

## 10. Umsetzungsstand (2026-07-21)

**Server gebaut & getestet:** echte Konten, Wallet (Test-Credits), Wetten anlegen/beitreten/aussteigen/auflösen, Lauf-Aufnahme mit einfachem Urteil, Pot-Ökonomie.

**Als Nächstes zu bauen (dieses Regelwerk):** 7-Tage-Anmeldefenster + Synchronstart + Mindestteilnehmer-Rückzahlung; Wochen-Checkpoint mit Auto-Ausstieg; Pensum-gekoppelte Auszahlung; entkoppelter Lauf-Abgleich + „alle passenden"-Schalter; Überlappungs-Deckel 3; anteiliges Einstiegs-Pensum; Erinnerung; danach die App-Screens anbinden. Ein-Lauf-Gnade später.

**Noch offen (Design):** Beiname für Bet Tier 3; Zustell-Form der Erinnerung im Web; Härtefall über die Ein-Lauf-Gnade hinaus; sanftere „Einsteiger"-Klausel; Produkt-Default des Abgleich-Schalters.
