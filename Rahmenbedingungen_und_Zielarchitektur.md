# Rahmenbedingungen und Zielarchitektur — BattleBet

**Version:** 1.3
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
  allem anderen stehen, die Umsetzung folgt gestuft.

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
   *unlohnend* zu machen (ein Regler, kein Ja/Nein). Umgesetzt über ein **Server-Urteil**
   über signierte Rohdaten und (vorerst) **eine Standard-Prüfstufe** (Abschnitt 8).
5. **Keine Plattform-Priorität.** Die frühere Festlegung „iOS zuerst" ist nach der
   Best-Practice-Recherche (s. `Recherche_Streckenmesser_und_Abgleich.md`) **verworfen**:
   Ein belastbarer Sicherheitsvorsprung von iOS ließ sich nicht belegen. iOS + Android
   gleichrangig; die Android-spezifische Schwäche (Mock-Location) wird **serverseitig**
   abgefangen (isMock, Attestierung, Quervalidierung) — nicht durch die Plattformwahl.
6. **Audit + Beweislast + Verwirkung** (belegte Best Practice, StepBet/HealthyWage): Bei
   Verdacht (zufällig oder algorithmisch getriggert) muss **der Nutzer** den Lauf
   nachweisen; unbewiesen = **kein Gewinn**; nachgewiesener Betrug = **Ausschluss +
   Einsatz verwirkt** (Abschreckung).
7. **Pot-Ligen vereinfacht.** Heute: **eine solide Standard-Prüfstufe für alle Pots +
   harte Deckel** als primäre Bremse. Gestufte Prüftiefe bleibt als **Option** offen
   (die Architektur hält das Feld „Prüfprofil" bereit), wird aber **nur bei Bedarf**
   eingeführt — bewusste eigene Hypothese ohne dokumentierten Branchen-Präzedenz.
8. Diese Leitplanken werden hier festgehalten und mitgepflegt.

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

> **Belegt durch Praxis-Recherche (2026-07-17):** Die folgende Haltung ist gegen reale
> Geld-Fitness-Apps (StepBet, HealthyWage, Strava) und GNSS-Fachliteratur geprüft; Details
> und Quellen in `Recherche_Streckenmesser_und_Abgleich.md`.

**Grundhaltung (unbequem, aber ehrlich):** „Manipulationssicher" im absoluten Sinn ist
mit einem Consumer-Handy **nicht** erreichbar — das Gerät gehört dem potenziellen
Betrüger. (Bestätigt ausgerechnet vom Marktführer: Strava gibt offen zu, bestimmte
Täuschungen prinzipiell nicht zu erkennen.) Ziel ist deshalb, **Betrug so aufwändig und
entdeckbar zu machen, dass er sich gegenüber dem möglichen Gewinn nicht lohnt** — ein
Regler, dessen Stellung zur Höhe des maximal möglichen Einzel-Gewinns passt.

Es sind eigentlich **zwei Probleme**:

- **Messen (funktioniert es?):** GPS allein ist zu unscharf. **Mess-Realität:** Roh-GPS
  auf Smartphones ist **metergenau, nicht sub-metergenau** (realistische Fusion ~1,6–4,7 m;
  Dezimeter nur mit Speziallabor-Verfahren). Konsequenz: **Wett-Regeln mit Toleranzband**
  denken (z. B. „≥ 7 km" mit Puffer), keine zentimetergenauen Ziele. **Dual-Frequency
  (L1/L5)**-Geräte sind der beste Consumer-Hebel. Grundmethode: **Sensor-Fusion** —
  GPS/GNSS + Beschleunigung (Schrittrhythmus) + Barometer + Schrittzähler +
  OS-Fitness-Schnittstellen (Apple HealthKit, Android Health Connect).
- **Fälschungssicherheit (Anti-Betrug):** **Verteidigung in Schichten** — kein
  Einzelmittel genügt (Bausteine s. 8.2). Kern:
  1. **Server als einzige Wahrheit** — das Handy schickt rohe, signierte, zeitgestempelte
     Sensordaten; der Server urteilt (nie „ich bin 7 km gelaufen, glaub mir"). Reine
     Client-Prüfung ist umgehbar (Standort lässt sich auf API-Ebene fälschen).
  2. **Vertrauensanker echter Tracker** — Anbindung an Apple Health / Health Connect /
     Fitbit / Garmin statt manueller Eingabe; dabei **Herkunfts-/Quell-App-Attribution**
     (keine manuell eingetragenen Workouts akzeptieren, denn in HealthKit/Health Connect
     lassen sich gefälschte Workouts schreiben).
  3. **Sensor-Fusion + Physik-Plausibilität** (GPS-Tempo × Kadenz; Höchstgeschwindigkeit,
     Teleport-/Sprung-Erkennung).
  4. **Geräte-Attestierung** (Apple App Attest / Google Play Integrity) — eine **Hürde,
     kein Wall**: hebt den Aufwand deutlich, ist aber selbst umgehbar; nicht über-vertrauen.
  5. **Serverseitige Anomalie-/Verhaltensprüfung** (wird mit Daten besser — genau Stravas
     Ansatz mit lernenden Modellen).
  6. **Audit + Beweislast + Verwirkung** — bei Flag muss **der Nutzer** nachweisen;
     unbewiesen = kein Gewinn; Betrug = Ausschluss + Einsatz verwirkt.

**Zwei Realitäten, die man kennen muss:**
- **Plattform-Asymmetrie:** iOS ist tendenziell schwerer zu täuschen (Mock-Location ist
  auf Android quasi eingebaut). **Aber:** Die Recherche konnte **keinen belastbaren
  Sicherheitsvorsprung** von iOS belegen → **keine Plattform-Priorität**; die
  Android-Schwäche wird serverseitig abgefangen, nicht durch die Plattformwahl.
- **Identitätslücke:** Selbst perfekte *Geräte*-Messung beweist nicht, dass *die Person*
  (kein Stellvertreter) gelaufen ist. Ein Geräte-Fingerabdruck entsperrt das Handy,
  beweist aber nicht die laufende Person; näher dran sind Gesichts-Liveness (ans Konto
  gebunden) oder ein am Körper getragenes Wearable.

**Jetzt (Samen):** Ein Lauf ist konzeptionell ein **Bündel roher, signierter
Sensordaten**, das serverseitig bewertet wird — nie eine fertige Zahl aus der App.
Datenmodell heute schon so anlegen (auch wenn simuliert), damit der Wechsel
„simuliert → echt gemessen und geprüft" nur ein Austausch der Datenquelle ist, kein Umbau.

**Später:** echte Sensor-Erfassung, Geräte-Attestierung, Server-Adjudikation,
Anomalie-Modelle, Audit-Werkzeuge; optionale höhere Prüfstufen (Wearable/Liveness).

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
   fertige Zahl; der Pot trägt ein Feld **Prüfprofil** (vorerst EINE Standardstufe; Feld
   bleibt für spätere Staffelung offen) plus die wirtschaftlichen Parameter (Deckel etc.),
   fixiert bei Erstellung. Wett-Regeln von Anfang an mit **Toleranzband** denken.

Alles Schwere — Wechselkurse, Zahlungen, Rollen-Mechanik, Admin-Oberfläche, Moderation,
Sensor-Erfassung, Attestierung, der Server selbst — bleibt bewusst Zukunft.

## 7. Bewusst später / offen

- Echter Server & serverseitige Konten (Ablösung des lokalen Login-Platzhalters).
- Zweite Währung aktiv + Zahlungsdienstleister.
- Regulatorik/Lizenzen für echtes Geld (länderabhängig; juristischer Rat nötig).
- Rollen, Rechte, Admin-Oberfläche, Moderations-Werkzeuge.
- Streckenmesser: echte Sensor-Erfassung, Geräte-Attestierung, Server-Adjudikation,
  Anomalie-Modelle, Audit-Werkzeuge.
- **Gestufte Prüftiefe (Pot-Ligen)** — nur bei Bedarf; Architektur hält das
  Prüfprofil-Feld offen.
- **iOS-Attest-/DeviceCheck-Praxis** und iOS-Mock-Situation gezielt nachrecherchieren
  (in dieser Runde unbelegt).
- **Gegenmaßnahmen gegen gefälschte Workouts** in HealthKit/Health Connect (Provenance)
  vertiefen.
- Gamification (SOCKS, Batches, Nadeln) — siehe eigene Spec; im MVP ausgelassen.

---

## 8. Pot-Ökonomie & Prüfstufen

**Kerngedanke:** Nicht der einzelne Läufer bestimmt, wie viel im Pot liegt — viele kleine
Einsätze ergeben einen großen Topf, und harte Ziele konzentrieren die Auszahlung auf
wenige. Der Anreiz zu betrügen richtet sich nach dem **maximal möglichen Einzel-Gewinn**
(≈ Pot ÷ erwartete Durchhalter), nicht nach dem Einsatz.

**Heutiger Ansatz (vereinfacht):** **EINE solide Standard-Prüfstufe für alle Pots +
harte Deckel** auf den maximal möglichen Einzel-Gewinn als primäre Bremse. Die früher
skizzierte Staffelung nach Auszahlungshöhe (Ligen Bronze/Silber/Obsidian) fand **keinen
dokumentierten Branchen-Präzedenzfall** — sie bleibt eine **offene Option**, kein
gebautes Feature. Die Architektur hält das Feld „Prüfprofil" am Pot bereit, sodass wir
bei Bedarf jederzeit tiefere Stufen einführen können, ohne umzubauen.

### 8.1 Prinzipien (invariant)

1. **Deckel = Sicherheits-Bremse:** Er hält den maximal möglichen **Einzel-Gewinn** unter
   dem Aufwand, die Standard-Prüfung zu überwinden. Primär eine Sicherheits-, keine
   Wirtschaftsregel.
2. **Kein heimliches Aufsteigen:** Wächst ein Pot an seinen Deckel, wird er **geschlossen**
   (keine neuen Teilnehmer).
3. Ein Pot ist ein **typisierter Vertrag**, bei Erstellung fixiert und **unveränderlich**;
   das Prüfprofil ist vor Beitritt sichtbar und wird akzeptiert.
4. **Falls** später gestaffelt wird: Prüftiefe ∝ maximal möglicher Einzel-Gewinn.
5. **Wer welchen Pot-Typ anlegen darf, knüpft an Rollen** (Nutzer vs. Mitarbeiter, s. 4.3).

### 8.2 Standard-Prüfprofil (heute die eine Stufe)

Pflicht für jeden Geld-Pot:
- **B0 — Basis:** Geräte-Attestierung (App Attest / Play Integrity, als **Hürde, nicht
  Wall**) + **Vertrauensanker echter Tracker** mit Herkunfts-/Quell-App-Attribution (keine
  manuell eingetragenen Workouts) + **Server-Urteil** über rohe, signierte Sensordaten.
- **B1 — Sensor-Fusion + Physik-Plausibilität:** GPS-Tempo × Kadenz; menschliche
  Tempo-/Beschleunigungsgrenzen; keine Teleports/„durch Gebäude".
- **B2 — Anomalie-/Verhaltensprüfung** (serverseitig, lernend).
- **B7 — Audit + Beweislast + Verwirkung:** Flag (zufällig oder algorithmisch) → **Nutzer**
  muss nachweisen; unbewiesen = kein Gewinn; Betrug = Ausschluss + Einsatz verwirkt.
- **Harte Deckel** auf den maximal möglichen Einzel-Gewinn.

### 8.3 Zusatz-Bausteine (Menü für optionale höhere Stufen — später bei Bedarf)

- **B3 — Puls-Wearable Pflicht** (HF-Kurve korreliert mit Tempo/Kadenz).
- **B4 — Liveness/Ident-Checks im Lauf** (Gesichts-Liveness ans Konto gebunden;
  Fingerabdruck als leichtere Variante, mit bekannter Grenze).
- **B5 — Erhöhte Identitätssicherung** (verifizierte Identität / KYC-artig) für hohe Pötte.
- **B6 — Auszahlungs-Prüffenster + Stichproben-Tiefprüfung + Community-Meldungen.**
- **Vertrauensstufen:** Neue Konten starten niedrig, steigen mit sauberer Historie.

### 8.4 Optionale Eskalationsstufen (Skizze — NICHT heute gebaut)

Falls sich zeigt, dass eine einzige Stufe nicht reicht, ist dies die vorgedachte Leiter
(Metall-Namen ~ Batch-Bildsprache):

| Stufe | Deckel (max. Einzel-Gewinn) | Zusätzlich zum Standard | Anlegbar von |
|---|---|---|---|
| **Bronze** (= heutiger Standard) | niedrig | — | jeder Nutzer |
| **Silber** | mittel | B3 (Wearable) · B6 (Prüffenster) | Nutzer ab höherer Vertrauensstufe |
| **Obsidian** | hoch/offen | B3 · B4 (Liveness) · B5 (Ident) · B6 | nur Mitarbeiter |

### 8.5 Bewusst offen / zu tunen

- Konkrete Deckel-/Einsatz-Zahlen und Fee.
- Ob und wann eine Staffelung überhaupt eingeführt wird (Hypothese ohne Präzedenz).
- Genaue Nachweis-Form beim Audit (Screenshot, Foto, Rohdaten-Nachlieferung).
- Fingerabdruck vs. Gesichts-Liveness als Ident-Check (falls je nötig).

---

## 9. Änderungshistorie

- **v1.3 (2026-07-17):** Nach Best-Practice-Recherche (`Recherche_Streckenmesser_und_Abgleich.md`):
  **„iOS zuerst" verworfen** (kein belegter Sicherheitsvorsprung) → keine Plattform-Priorität;
  **Audit + Beweislast + Verwirkung** als Kern-Pfeiler (B7); Attestierung als **Hürde, nicht
  Wall** präzisiert; **Vertrauensanker echter Tracker + Herkunfts-Attribution** (B0); **Pot-Ligen
  vereinfacht** auf eine Standard-Prüfstufe + harte Deckel, Staffelung nur als offene Option;
  Mess-Realität **metergenau → Toleranzbänder**.
- **v1.2 (2026-07-17):** Entscheidung **iOS zuerst** aufgenommen. *(In v1.3 wieder verworfen.)*
- **v1.1 (2026-07-17):** Vierte Rahmenbedingung **Laufkontrolle/Streckenmesser** (4.4) und
  **Pot-Ligen-Katalog** (Abschnitt 8) ergänzt; Entscheidung 4 (Streckenmesser als Kernstück)
  aufgenommen; vierter Samen (Lauf = signiertes Sensordaten-Bündel, Pot trägt Prüfprofil) ergänzt.
- **v1.0 (2026-07-17):** Erstfassung. Vier Grundsatz-Entscheidungen festgehalten
  (Grundsprache Englisch; eine Wette = eine Währung, EUR+USD; „Server + App +
  Admin"-Produkt; dieses Dokument angelegt).
