# Rahmenbedingungen und Zielarchitektur — BattleBet

**Version:** 1.2
**Stand:** 2026-07-17
**Status:** lebendes Dokument (wächst mit den Entscheidungen)

---

## 1. Zweck

Dieses Dokument hält die **Leitplanken für die Endausbaustufe** von BattleBet fest —
Rahmenbedingungen, die erst spät in der App sichtbar werden, aber schon **jetzt beim
Bauen mitgedacht** werden müssen, damit späteres Nachrüsten billig bleibt. Es ergänzt
die bestehenden Specs (SOCKS/Ranking, Navigation, Element-Katalog) um die
*nicht-funktionalen* Rahmenbedingungen — also nicht „welcher Screen zeigt was", sondern
„nach welchen Grundregeln ist die App gebaut".

## 2. Leitprinzip

> **Architektonisch offen, funktional minimal.**

Wir halten dort etwas offen, wo Nachrüsten sonst teuer würde, und lassen dort weg, wo
Nachrüsten billig ist. Der MVP bleibt schlank; die Endstufe wird nicht verbaut. Konkret
unterscheiden sich die Rahmenbedingungen stark darin, *wie früh* sie mitgedacht werden
müssen:

- **Mehrsprachigkeit** — jetzt billig, später teuer → Mechanik ab sofort mitführen.
- **Währungen** — ein kleiner Samen heute genügt, der Rest kommt später.
- **Server + App + Admin** — fast reine Zukunft, prägt aber die Architektur am stärksten.
- **Laufkontrolle (Streckenmesser)** — das technische Kernstück; das Konzept muss vor
  allem anderen stehen, die Umsetzung folgt gestuft über die Pot-Ligen.

## 3. Getroffene Grundsatz-Entscheidungen (2026-07-17)

1. **Grundsprache Englisch.** Englisch ist die Basissprache (passt zu den englischen
   Code-IDs); **Deutsch** ist die erste Übersetzung. Weitere Sprachen folgen später.
2. **Eine Wette = eine Währung** („einwährungsrein"). Kein Mischen verschiedener
   Währungen im selben Pot. Unterstützt werden mindestens **EUR und USD**.
3. **BattleBet wird ein „Server + App + Admin"-Produkt.** Ein zentraler Server ist die
   einzige Wahrheit; die Handy-App ist die Nutzerseite; eine separate Admin-Oberfläche
   dient dem Personal (Wetten anbieten, sponsern, moderieren).
4. **Laufkontrolle/Streckenmesser ist das Kernstück.** GPS-basierte Messung (ob / wie
   weit / wie schnell), zuverlässig **und** fälschungssicher. Grundsatz: absolute
   Manipulationssicherheit ist mit Consumer-Handys nicht erreichbar; Ziel ist, Betrug
   *unlohnend* zu machen (ein Regler, kein Ja/Nein). Umgesetzt über **Pot-Ligen**
   (Abschnitt 8): Die Prüftiefe koppelt an den maximal möglichen **Einzel-Gewinn**,
   nicht an den Einsatz; jeder Pot ist ein bei Erstellung fixierter, typisierter Vertrag.
5. **iOS zuerst.** Entwicklungs- und Launch-Priorität liegt auf iOS (deutlich schwerer
   zu täuschen als Android, s. 4.4); Android folgt danach. Das betrifft die *Reihenfolge*
   des Bauens/Ausrollens — die Plattform-Zulassung je Liga (8.4) bleibt davon unberührt.
6. Diese Leitplanken werden hier festgehalten und mitgepflegt.

---

## 4. Die Rahmenbedingungen im Detail

### 4.1 Mehrsprachigkeit (i18n)

**Ziel:** Die App funktioniert in mehreren Sprachen; zunächst Englisch (Basis) und
Deutsch.

**Haltung:** Das Teure an Mehrsprachigkeit ist nicht das Übersetzen, sondern dass Texte
sonst über den ganzen Code verstreut sind. Deshalb liegen Texte **nicht direkt im
Screen**, sondern werden über einen Schlüssel referenziert; die echten Worte stehen in
**einer Datei pro Sprache** (Flutters eingebautes l10n-System). Lokalisierung ist mehr
als Worte: Zahlen-/Datumsformate (DE „1.234,56" vs. EN „1,234.56"), Mehrzahlformen
(„1 activity" / „2 activities"), und deutscher Text ist länger → das Layout muss atmen.
Zusammengesetzte Sätze (z. B. der „I bet …"-Satz beim Anlegen) werden **nicht aus
Bausteinen** gebaut, sondern pro Sprache als ganzer Satz mit Platzhaltern hinterlegt,
weil Grammatik je Sprache anders ist.

**Jetzt (Samen):** Neuen Text ab sofort über das Sprachsystem führen; Grundsprache
Englisch festlegen; den heutigen DE/EN-Mischmasch schrittweise auf die Basissprache
vereinheitlichen.

**Später:** Weitere Sprachen; vollständige Übersetzung aller Screens; ggf.
Rechts-nach-links-Sprachen.

### 4.2 Währungen

**Ziel:** Wetten in unterschiedlichen Währungen, mindestens EUR und USD.

**Haltung:** Jede Wette ist in **genau einer** Währung ausgeschrieben. Wer beitritt,
zahlt und kassiert in dieser Währung — der Pot bleibt einwährungsrein. Damit entfällt
das Mischen von Währungen in einem Topf und das damit verbundene Wechselkurs-Risiko
(Kurs bewegt sich zwischen Beitritt und Auszahlung). Geld wird **nie als bloße
Kommazahl** behandelt, sondern immer als **Betrag + Währung**, intern in der kleinsten
Einheit (Cent) und mit ISO-Währungscode (EUR, USD). Das vermeidet Rundungsfehler und
macht die zweite Währung zu einer kleinen Ergänzung statt zu einer Migration.

**Jetzt (Samen):** Ein „Money"-Begriff (Betrag in Cent + Währung) statt des heutigen
`double`-Preises. Vorerst nur eine Währung real im Einsatz, aber sauber vorbereitet.

**Später:** Zweite Währung aktiv; Zahlungsdienstleister (z. B. Stripe); Anzeige-/Format-
Regeln je Sprache/Region.

**Wichtiger Hinweis (außerhalb der Technik):** Echtes Geld auf Wetten ist ein
**regulierter** Bereich, und die Regeln unterscheiden sich stark je Land — „welche
Währungen" heißt letztlich „welche Länder" heißt „welche Lizenzen/Auflagen". Vor echtem
Geldfluss gehört fachlicher (juristischer) Rat dazu. Im MVP (simuliert, kein echtes
Geld) ist das noch kein Thema.

### 4.3 Server + App + Admin (Rollen, Mitarbeiter-Wetten, Moderation)

**Ziel:** Mitarbeiter können Wetten anbieten (inkl. Sponsoring, Batches) und in der App
moderieren.

**Haltung:** Das setzt drei Dinge voraus, die es heute noch nicht gibt:
- **Rollen** — normaler Nutzer vs. Mitarbeiter/Admin (Berechtigungen).
- **Herkunft/Typ einer Wette** — nutzergemacht vs. offiziell/gesponsert. Erster Samen
  ist bereits gelegt (`BetTag.sponsored`, Beispiel „adidas Summerrun").
- **Moderation** — Wetten prüfen, freigeben, entfernen; Meldungen bearbeiten.

Moderation und mitarbeiter-angebotene Wetten ergeben nur mit einem **zentralen Server
als einziger Wahrheit** Sinn — man kann nichts moderieren, was nur auf einem einzelnen
Handy liegt. Das jetzige Login ist ein lokaler Platzhalter und wird später durch echte,
serverseitige Konten ersetzt. Das Personal arbeitet in einer **separaten
Admin-Oberfläche** (in der Regel eine Web-Seite, nicht die Handy-App).

**Jetzt (Samen):** Datenmodell bewusst so halten, dass eine Wette einen **Urheber/eine
Herkunft** hat und Nutzer später **Rollen** bekommen — ohne die Mechanik schon zu bauen.

**Später:** Echter Server, serverseitige Konten/Anmeldung, Rollen & Rechte,
Admin-Oberfläche, Moderations-Werkzeuge.

### 4.4 Laufkontrolle (Streckenmesser) — Messung & Fälschungssicherheit

**Ziel:** Per GPS zuverlässig erfassen, **ob, wie weit und wie schnell** jemand läuft —
und das **fälschungssicher**, weil am Pot echtes Geld hängt. Das technische Kernstück
des ganzen Programms.

**Grundhaltung (unbequem, aber ehrlich):** „Manipulationssicher" im absoluten Sinn ist
mit einem Consumer-Handy **nicht** erreichbar — das Gerät gehört dem potenziellen
Betrüger. Ziel ist deshalb, **Betrug so aufwändig und entdeckbar zu machen, dass er sich
gegenüber dem möglichen Gewinn nicht lohnt** — ein Regler, dessen Stellung zur Höhe des
maximal möglichen Einzel-Gewinns passt (→ Pot-Ligen, Abschnitt 8).

Es sind eigentlich **zwei Probleme**:

- **Messen (funktioniert es?):** GPS allein ist zu unscharf (5–10 m, schlechter in
  Stadt/Wald; Rauschen verlängert Strecken tendenziell). Lösung: **Sensor-Fusion** —
  GPS/GNSS + Beschleunigung (Schrittrhythmus) + Barometer (Höhe) + Schrittzähler +
  OS-Fitness-Schnittstellen (Apple HealthKit, Android Health Connect).
- **Fälschungssicherheit (Anti-Betrug):** **Verteidigung in Schichten** — kein
  Einzelmittel genügt (Bausteine s. 8.2): Geräte-Attestierung, Sensor-Fusion +
  Physik-Plausibilität, **Server als einzige Wahrheit** (das Handy schickt rohe,
  signierte, zeitgestempelte Sensordaten; der Server urteilt — nie „ich bin 7 km
  gelaufen, glaub mir"), serverseitige Anomalie-Erkennung, optional Puls-Wearable und
  Liveness/Ident-Checks, dazu wirtschaftliche/Design-Bremsen.

**Zwei Realitäten, die man kennen muss:**
- **Plattform-Asymmetrie:** iOS ist deutlich schwerer zu täuschen als Android
  (Mock-Location ist auf Android quasi eingebaut). **Entschieden: iOS zuerst**
  (Entwicklung + Launch), Android folgt danach.
- **Identitätslücke:** Selbst perfekte *Geräte*-Messung beweist nicht, dass *die Person*
  (kein Stellvertreter) gelaufen ist. Ein Geräte-Fingerabdruck entsperrt das Handy,
  beweist aber nicht die laufende Person; näher dran sind Gesichts-Liveness (ans Konto
  gebunden) oder ein am Körper getragenes Wearable.

**Jetzt (Samen):** Ein Lauf ist konzeptionell ein **Bündel roher, signierter
Sensordaten**, das serverseitig bewertet wird — nie eine fertige Zahl aus der App.
Datenmodell heute schon so anlegen (auch wenn simuliert), damit der Wechsel
„simuliert → echt gemessen und geprüft" nur ein Austausch der Datenquelle ist, kein Umbau.

**Später:** echte Sensor-Erfassung, Geräte-Attestierung, Server-Adjudikation,
Wearable-/Liveness-Integration, Anomalie-Modelle.

---

## 5. Zielarchitektur (Gesamtbild)

```
                 ┌─────────────────────────────────────┐
                 │   SERVER  (Single Source of Truth)   │
                 │   Nutzer · Konten · Rollen ·         │
                 │   Wetten · Pots · Läufe · Urteil     │
                 └───────────────┬─────────────────────┘
                     ┌───────────┴────────────┐
        ┌────────────┴───────────┐   ┌─────────┴───────────────┐
        │  MOBILE APP (Flutter)  │   │  ADMIN-OBERFLÄCHE (Web)  │
        │  Nutzerseite:          │   │  Personal:               │
        │  wetten · beitreten ·  │   │  Wetten anbieten ·       │
        │  laufen (Sensoren) ·   │   │  sponsern · moderieren   │
        │  Fortschritt sehen     │   │                          │
        └────────────────────────┘   └──────────────────────────┘

  Der Server bewertet die (signierten) Sensordaten jedes Laufs — der Client urteilt nie
  selbst. Später angedockt: Zahlungsdienstleister (EUR/USD) · Regulatorik/Lizenzen.
```

Heute existiert nur die **Mobile App**, und zwar rein **lokal** (kein Server,
simulierte Bewegungsdaten). Der Server ist der nächste große Architekturschritt; er ist
die Voraussetzung für Punkt 4.3 (Mitarbeiter/Moderation) und für 4.4 (fälschungssichere
Laufkontrolle).

## 6. Was das fürs aktuelle Bauen heißt (die Samen)

Kleine, billige Vorkehrungen, die den MVP **nicht** ausbremsen, aber ein späteres
Nachrüsten stark verbilligen:

1. **Geld** als Betrag (in Cent) + Währung statt nackter `double`-Zahl.
2. **Texte** ab sofort durch das Sprachsystem führen; Grundsprache Englisch; den
   DE/EN-Mix vereinheitlichen.
3. **Modell** so halten, dass eine Wette einen Urheber/Typ hat und Nutzer Rollen
   bekommen können (Samen `BetTag` ist da).
4. **Lauf** als Bündel roher (später signierter) Sensordaten modellieren, nicht als
   fertige Zahl; der Pot trägt ein Feld **Liga/Prüfprofil** plus die wirtschaftlichen
   Parameter (Deckel etc.), fixiert bei Erstellung.

Alles Schwere — Wechselkurse, Zahlungen, Rollen-Mechanik, Admin-Oberfläche, Moderation,
Sensor-Erfassung, Attestierung, der Server selbst — bleibt bewusst Zukunft.

## 7. Bewusst später / offen

- Echter Server & serverseitige Konten (Ablösung des lokalen Login-Platzhalters).
- Zweite Währung aktiv + Zahlungsdienstleister.
- Regulatorik/Lizenzen für echtes Geld (länderabhängig; juristischer Rat nötig).
- Rollen, Rechte, Admin-Oberfläche, Moderations-Werkzeuge.
- Streckenmesser: echte Sensor-Erfassung, Geräte-Attestierung, Server-Adjudikation,
  Wearable-/Liveness-Integration, Anomalie-Modelle.
- Gamification (SOCKS, Batches, Nadeln) — siehe eigene Spec; im MVP ausgelassen.

---

## 8. Pot-Ligen (Verifikations- und Wirtschafts-Katalog)

**Kerngedanke:** Nicht der einzelne Läufer bestimmt, wie viel im Pot liegt — viele kleine
Einsätze ergeben einen großen Topf, und harte Ziele konzentrieren die Auszahlung auf
wenige. Der Anreiz zu betrügen richtet sich nach dem **maximal möglichen Einzel-Gewinn**
(≈ Pot ÷ erwartete Durchhalter), nicht nach dem Einsatz. Genau daran koppelt die
Prüftiefe. Umgesetzt wird das über eine kleine Zahl fester **Ligen**; jeder Pot gehört zu
genau einer.

### 8.1 Prinzipien (invariant)

1. **Prüftiefe ∝ maximal möglicher Einzel-Gewinn** — nicht Einsatz.
2. Ein Pot ist ein **typisierter Vertrag**, bei Erstellung fixiert und **unveränderlich**;
   die Liga ist vor Beitritt sichtbar und wird ausdrücklich akzeptiert.
3. Jede Liga bündelt drei Dinge: **Wirtschaft** (Währung, Einsatzspanne, Deckel auf den
   Einzel-Gewinn, Auszahlung, Fee) · **Zutritt** (Vertrauensstufe, Plattform,
   Geräte-/Wearable-Pflicht) · **Prüfregime** (welche Anti-Betrugs-Bausteine Pflicht sind).
4. **Deckel = Sicherheits-Bremse:** Er hält den maximal möglichen Einzel-Gewinn *unter*
   dem Aufwand, die Prüfung dieser Liga zu überwinden. Also keine primär wirtschaftliche,
   sondern eine **Sicherheitsregel**.
5. **Kein heimliches Aufsteigen:** Wächst ein Pot an seinen Deckel, wird er **geschlossen**
   (keine neuen Teilnehmer). Ein Pot kann nicht unter leichten Regeln zu einem großen Ziel
   anwachsen — größere Pötte müssen als höhere Liga *starten*.
6. **Wer welche Liga anlegen darf, knüpft an Rollen** (Nutzer vs. Mitarbeiter) — s. 4.3.
7. Die **Zahlenwerte** unten sind Erst-Vorschläge und tunebar; **fest** ist die Struktur.

### 8.2 Prüf-Bausteine (Menü, aus dem Ligen zusammengesetzt werden)

- **B0 — Basis (immer):** Geräte-Attestierung (Apple App Attest / Google Play Integrity)
  + Server-Urteil über rohe, signierte Sensordaten.
- **B1 — Sensor-Fusion + Physik-Plausibilität:** GPS ↔ Schrittrhythmus ↔ Höhe;
  menschliche Tempo-/Beschleunigungsgrenzen; keine Teleports, kein „durch Gebäude/Wasser".
- **B2 — Anomalie-/Verhaltensprüfung (serverseitig, immer):** unplausible Leistungs-
  sprünge, bekannte Trickmuster, korrelierte Konten/Geräte/Orte.
- **B3 — Puls-Wearable Pflicht:** Herzfrequenz-Kurve korreliert mit Tempo/Kadenz.
- **B4 — Liveness/Ident-Checks im Lauf:** Gesichts-Liveness (ans Konto gebunden);
  Fingerabdruck als leichtere Variante (mit bekannter Grenze).
- **B5 — Erhöhte Identitätssicherung:** verifizierte Identität (KYC-artig) für hohe Pötte.
- **B6 — Auszahlungs-Prüffenster + Stichproben-Tiefprüfung + Community-Meldungen.**

### 8.3 Vertrauensstufen

Neue Konten starten niedrig und steigen mit sauberer Historie. Höhere Ligen verlangen eine
**Mindest-Vertrauensstufe**. Das begrenzt Einsteiger-Missbrauch und Wegwerf-Konten.

### 8.4 Die Ligen (Erst-Katalog — Zahlen tunebar)

| Liga | Deckel (max. Einzel-Gewinn) | Einsatz | Plattform | Prüfregime (Pflicht) | Anlegbar von |
|------|------|------|------|------|------|
| **Bronze — „Einstieg"** | ~50 € | klein | iOS + Android | B0 · B1 · B2 | jeder Nutzer (ab Grund-Vertrauensstufe); Stellvertreter-Restrisiko bewusst akzeptiert |
| **Silber — „Ambitioniert"** | mittel | mittel | iOS + attestiertes Android | B0 · B1 · B2 · **B3 (Wearable)** · B6 | Nutzer ab höherer Vertrauensstufe |
| **Obsidian — „High-Performer"** | hoch/offen | höher | iOS + Wearable | B0 · B1 · B2 · B3 · **B4 (Liveness)** · **B5 (Ident)** · B6 | nur Mitarbeiter |

Die Metall-Namen knüpfen an die vorhandene Batch-Bildsprache an; weitere Stufen sind
denkbar (z. B. eine geldlose „Papier/Jute"-Sozialstufe ganz unten oder eine „Gold"-Stufe
zwischen Silber und Obsidian). Endgültige Zuordnung mit der SOCKS-/Batch-Spec abstimmen.

### 8.5 Bewusst offen / zu tunen

- Konkrete Deckel-/Einsatz-Zahlen und Fee je Liga.
- Genaue Zuordnung der Metall-Namen zu Ligen (Abstimmung mit SOCKS/Batch-Spec).
- Ob Silber ein Wearable **verpflichtet** oder nur stärker gewichtet.
- Android-Politik (ganz zulassen / nur attestiert / nur niedrige Ligen).
- Fingerabdruck vs. Gesichts-Liveness als Standard-Ident-Check.

---

## 9. Änderungshistorie

- **v1.2 (2026-07-17):** Entscheidung **iOS zuerst** (Entwicklungs-/Launch-Priorität)
  aufgenommen (3.5 + 4.4).
- **v1.1 (2026-07-17):** Vierte Rahmenbedingung **Laufkontrolle/Streckenmesser** (4.4)
  und **Pot-Ligen-Katalog** (Abschnitt 8) ergänzt; Entscheidung 4 (Streckenmesser als
  Kernstück) aufgenommen; vierter Samen (Lauf = signiertes Sensordaten-Bündel, Pot trägt
  Liga/Prüfprofil) ergänzt.
- **v1.0 (2026-07-17):** Erstfassung. Vier Grundsatz-Entscheidungen festgehalten
  (Grundsprache Englisch; eine Wette = eine Währung, EUR+USD; „Server + App +
  Admin"-Produkt; dieses Dokument angelegt).
