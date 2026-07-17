# Rahmenbedingungen und Zielarchitektur — BattleBet

**Version:** 1.0
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
unterscheiden sich die drei Rahmenbedingungen stark darin, *wie früh* sie mitgedacht
werden müssen:

- **Mehrsprachigkeit** — jetzt billig, später teuer → Mechanik ab sofort mitführen.
- **Währungen** — ein kleiner Samen heute genügt, der Rest kommt später.
- **Server + App + Admin** — fast reine Zukunft, prägt aber die Architektur am stärksten.

## 3. Getroffene Grundsatz-Entscheidungen (2026-07-17)

1. **Grundsprache Englisch.** Englisch ist die Basissprache (passt zu den englischen
   Code-IDs); **Deutsch** ist die erste Übersetzung. Weitere Sprachen folgen später.
2. **Eine Wette = eine Währung** („einwährungsrein"). Kein Mischen verschiedener
   Währungen im selben Pot. Unterstützt werden mindestens **EUR und USD**.
3. **BattleBet wird ein „Server + App + Admin"-Produkt.** Ein zentraler Server ist die
   einzige Wahrheit; die Handy-App ist die Nutzerseite; eine separate Admin-Oberfläche
   dient dem Personal (Wetten anbieten, sponsern, moderieren).
4. Diese Leitplanken werden hier festgehalten und mitgepflegt.

---

## 4. Die drei Rahmenbedingungen im Detail

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

---

## 5. Zielarchitektur (Gesamtbild)

```
                 ┌─────────────────────────────────────┐
                 │   SERVER  (Single Source of Truth)   │
                 │   Nutzer · Konten · Rollen ·         │
                 │   Wetten · Pots · Fortschritt        │
                 └───────────────┬─────────────────────┘
                     ┌───────────┴────────────┐
        ┌────────────┴───────────┐   ┌─────────┴───────────────┐
        │  MOBILE APP (Flutter)  │   │  ADMIN-OBERFLÄCHE (Web)  │
        │  Nutzerseite:          │   │  Personal:               │
        │  wetten · beitreten ·  │   │  Wetten anbieten ·       │
        │  Fortschritt sehen     │   │  sponsern · moderieren   │
        └────────────────────────┘   └──────────────────────────┘

        Später angedockt: Zahlungsdienstleister (EUR/USD) · Regulatorik/Lizenzen
```

Heute existiert nur die **Mobile App**, und zwar rein **lokal** (kein Server,
simulierte Bewegungsdaten). Der Server ist der nächste große Architekturschritt; er ist
die Voraussetzung für Punkt 4.3 (Mitarbeiter/Moderation) und für echtes, geteiltes
Wett-Geschehen.

## 6. Was das fürs aktuelle Bauen heißt (die drei Samen)

Kleine, billige Vorkehrungen, die den MVP **nicht** ausbremsen, aber ein späteres
Nachrüsten stark verbilligen:

1. **Geld** als Betrag (in Cent) + Währung statt nackter `double`-Zahl.
2. **Texte** ab sofort durch das Sprachsystem führen; Grundsprache Englisch; den
   DE/EN-Mix vereinheitlichen.
3. **Modell** so halten, dass eine Wette einen Urheber/Typ hat und Nutzer Rollen
   bekommen können (Samen `BetTag` ist da).

Alles Schwere — Wechselkurse, Zahlungen, Rollen-Mechanik, Admin-Oberfläche, Moderation,
der Server selbst — bleibt bewusst Zukunft.

## 7. Bewusst später / offen

- Echter Server & serverseitige Konten (Ablösung des lokalen Login-Platzhalters).
- Zweite Währung aktiv + Zahlungsdienstleister.
- Regulatorik/Lizenzen für echtes Geld (länderabhängig; juristischer Rat nötig).
- Rollen, Rechte, Admin-Oberfläche, Moderations-Werkzeuge.
- Gamification (SOCKS, Batches, Nadeln) — siehe eigene Spec; im MVP ausgelassen.

## 8. Änderungshistorie

- **v1.0 (2026-07-17):** Erstfassung. Vier Grundsatz-Entscheidungen festgehalten
  (Grundsprache Englisch; eine Wette = eine Währung, EUR+USD; „Server + App +
  Admin"-Produkt; dieses Dokument angelegt).
