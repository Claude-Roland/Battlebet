# BattleBet — Offene Aufgaben

Lebendes Dokument. Erledigtes wird abgehakt und wandert nach unten in „Erledigt-Archiv";
neue Aufgaben kommen dazu. Reihenfolge innerhalb der Blöcke ≈ Priorität.
(Stand: 2026-07-22)

## 1 · Kurzfristig — Live-Betrieb festigen

- [ ] **Live-Stand verifizieren:** Liefert battlebet.app wirklich den neuesten grünen
  Web-Build (`17da744`) aus? Auto-Pull-Mechanik der Container klären (zieht der Server
  neue GHCR-Images selbst, oder muss man anstoßen?) und im Runbook festhalten.
- [ ] **End-to-end-Test im Live-Betrieb:** Registrieren → Wette anlegen → Beitreten →
  Lauf aufnehmen → Wochen-Checkpoint/Auszahlung — einmal komplett auf battlebet.app
  durchspielen (nicht nur lokal).
- [ ] **Code-Verifikation Regelwerk:** Sind anteiliges Einstiegs-Pensum offener Pots und
  der „alle passenden"-Schalter (entkoppelter Lauf-Abgleich) in `890c59d` enthalten?
  Ergebnis in `wett_oekonomie` nachtragen.
- [ ] **Erinnerungs-Banner (In-App):** „Diese Woche fehlen dir noch X Läufe, Frist in
  2 Tagen" — 2 Tage vor Wochenende, wenn Pensum unerfüllt. (Echte Push erst mit
  Mobil-App + Apple/Google-Konten.)
- [ ] **RAM des CPX22 beobachten** (4 GB, trägt jetzt Augustmond-Prod UND BattleBet).
  Bei Druck oder vor echtem Traffic: eigenen kleinen Hetzner-Server für BattleBet erwägen.

## 2 · Spielregeln — Rest aus der Wett-Ökonomie

- [ ] **Ein-Lauf-Gnade:** jetzt nur Datenplatz anlegen (Joker-Zähler, „erhalten am /
  nächster am", Kontinuitäts-Uhr, Profil-Anzeige); Bau des Verhaltens später.
- [ ] **Härtefall-Design:** Was passiert bei Verletzung > 1 Lauf? (offen, Design-Frage)
- [ ] **„Einsteiger"-Klausel:** sanfterer Erst-Einstieg für Neue (offen, Design-Frage)
- [ ] **Beiname für Tier 3:** UI sagt inzwischen „Unlimited" — bestätigen oder besseren
  Namen finden.

## 3 · Stufe B — Sensoren, Anti-Cheat, Admin

- [ ] **Echte Bewegungsdaten:** GPS/Sensoren statt Simulation (mobile App nötig);
  Recorder liefert echtes signiertes Rohdaten-Bündel.
- [ ] **Anti-Cheat / Streckenmesser verfeinern:** Server-Urteil nach
  `Recherche_Streckenmesser_und_Abgleich.md` ausbauen (Sensor-Fusion, Anomalie-Erkennung,
  Toleranzband, Vertrauensanker Tracker, Android-Mock-Location).
- [ ] **Attestierung (B0):** App-Integrität Apple/Google — hängt an den Entwicklerkonten.
- [ ] **Audit + Beweislast + Verwirkung (B7):** Verdachtsfall-Workflow (Nutzer muss
  nachweisen; unbewiesen = kein Gewinn; Betrug = Ausschluss + Einsatz verwirkt).
- [ ] **Admin-Ausbau:** Staff-Console v1 erweitern (Nutzer-/Wetten-Verwaltung,
  Verdachtsfälle, Kennzahlen).

## 4 · App & Design

- [ ] **Konto-Verwaltung: Passwort ändern** (in der App, für das eigene Konto; Anlass:
  Staff-Konto Alexander_Hotz wurde 2026-07-22 mit im Chat geteiltem Passwort angelegt).
  Später dazu: „Passwort vergessen"-Reset (braucht E-Mail o. ä. — Weg offen).
- [ ] **l10n einführen:** EN = Basis, DE = erste Übersetzung; DE/EN sauber übers
  l10n-System; Language-Einstellung im Profil scharf schalten (Deutsch aktivierbar).
- [ ] **Belohnungssystem SOCKS/Ranking:** `evaluateRewards(run)` mit Leben füllen
  (Spec: `SOCKS_und_Ranking_Spezifikation.md`); live Socken/Lorbeeren im Recorder.
- [ ] **Batch-Metall-Stufen** vervollständigen; **NEEDLES** = Rang-Pins (Roland
  recherchiert noch).
- [ ] **Echte 3D-Fortschritts-Rinne** (aktueller Stand ist kein echter 3D-Effekt).
- [ ] **Daumenmenü** (radiales Thumb-Menü) — erst wenn seine Ziele existieren
  (local bets, socks, batches, gifts …).
- [ ] **Weitere Sportarten** (Wählrad wächst mit); **echte SVG-Assets** statt Platzhalter.
- [ ] **global/lokal (Globus / local bets):** bewusst zurückgestellt.
- [ ] **Manager-Kennzahl:** zurückgestellt.

## 5 · Infrastruktur & Konten

- [ ] **Apple-Entwicklerkonto** (~99 $/Jahr, als Organisation) + **Google Play**
  (25 $ einmalig) beschaffen — FRÜH, Attestierung und Push hängen daran.
- [ ] **Mobile Build-CI:** iOS-/Android-Builds (Mac oder GitHub-Actions-macOS/Codemagic);
  iOS-Signierung über den Mac.
- [ ] **Push-Benachrichtigungen** (Server-Job → APNs/FCM) — nach Mobil-App + Konten.
- [ ] **Excel-Quellen in `Code/_zum_loeschen/`** — Roland löscht selbst.

## 6 · Zuletzt — echtes Geld (Stufe C)

- [ ] **Geld-Schicht:** Payment + Payout + echtes Wallet + KYC +
  Glücksspiel-Regulatorik + juristischer Rat. Bewusst der LETZTE Schritt —
  mehr Recht als Technik.

## Erledigt-Archiv

- [x] Stufe A komplett: Server-Backbone (Dart Frog + Postgres), Konten, Wallet
  (Test-Credits), Wetten, Läufe (2026-07-21)
- [x] Spielregeln serverseitig: Einstieg-Lebenszyklus (Anmeldefenster, Synchronstart,
  Min-3, Überlappungs-Deckel) + Wochen-Checkpoint + Pensum-gekoppelte Auszahlung +
  entkoppelter Lauf-Abgleich (2026-07-21)
- [x] App vollständig an den Server angebunden (Liste, Anlegen, Beitreten, My Bets,
  Recorder) (2026-07-21)
- [x] Auto-Login („30 Tage merken"), Bookmarks, Auto-Namen, Admin-Konsole v1 (2026-07-21)
- [x] Deploy: battlebet.app + api.battlebet.app live (CPX22, Docker `/opt/battlebet`,
  CI → GHCR) (2026-07-21)
