# BattleBet — Element-Katalog (MVP: Wetten)

**Status:** v1.0 · 11. Juli 2026
**Zweck:** Gemeinsame Sprache zwischen **Roland** (Produkt, Design, Entscheidungen) und **Claude** (Umsetzung). Jedes Element hat einen **Katalog-Namen** (deutsch — so reden wir), eine **Code-ID** (englisch — so heißt es im Code) und einen **Beispiel-Verweis**, wo es zu sehen ist. Wenn du sagst „ändere die *Wett-Zeile*", weiß ich: `BetRow`.

**Geltungsbereich:** MVP = **nur Wetten** (Onboarding, Wette erstellen, Fortschritt verfolgen). Gamification (SOCKS, Batches, Rankings, Shop, Messages), echtes GPS und echtes Geld sind **nicht** im MVP. Solche Elemente stehen unten mit 🔒 „später" — ihre Datenfelder werden aber schon reserviert, damit die nächsten Stufen sauber andocken.

**Rahmen-Entscheidungen (11.07.2026):**
- **Stack: Flutter** (ein Codebase iOS/Android/Web, pixelgenaue Custom-UI, wenig Abhängigkeits-Wildwuchs).
- **Bezeichner:** deutsche Asset-Dateinamen bleiben; Code-IDs englisch; dieser Katalog ist die Brücke.
- **Erster Durchstich lokal** (kein Backend; Daten im Gerät). Backend ab Vorversion.
- **Bewegungsdaten simuliert** (kein echtes GPS im MVP) — über ein Dev-Element „Aktivität simulieren".

**Legende MVP-Spalte:** ✅ im MVP · ✅sim simuliert · 🔒 später (Platz reservieren).
Beispiel-SVGs liegen unter `SVGs/BattleBet31Jan2019_2_<N>_1.svg`, hier kurz als `_<N>` notiert. Assets unter `Einzelteile/`.

---

## A. Screens (Seiten)

| Katalog-Name | Code-ID | Zweck | Beispiel | MVP |
|---|---|---|---|---|
| Splash / Titel | `SplashScreen` | Startbild beim App-Start | `_1` | ✅ |
| Registrierung / Login | `AuthScreen` | Konto — MVP nur Username + Passwort | (kein eigener Entwurf; minimal) | ✅ |
| Bets-Liste („Hauptseite Bets") | `BetsListScreen` | Liste offener Wetten, sortiert nach Distanz | `_2` | ✅ |
| Bet-Detail („Unterseite Bet-Card") | `BetDetailScreen` | Detail einer Wette (Pot, Intervall, Kurve) | `_12` | ✅ |
| Wette anlegen („Create Bet") | `CreateBetScreen` | Wette per Walzen zusammenstellen | `_5` | ✅ |
| Bestätigung („Bestätigungsseite") | `ConfirmBetScreen` | „You are about to place a bet …" · place/back | Storyboard Durchlauf 2 | ✅ |
| Meine Wetten („My Bets") | `MyBetsScreen` | eigene Wetten mit Fortschritt/Countdown | `_3` / `_18` 🟠 gegenprüfen | ✅ |
| Recorder | `RecorderScreen` | Lauf-Aufzeichnung — **MVP: simuliert** | `_7` | ✅sim |
| Einstellungen | `SettingsScreen` | Profildaten + Anzeige-Schalter | `_16` | teils ✅ |
| Score / Auszahlung | `ScoreScreen` | Ergebnis + verdiente SOCKS/Badges | `_11` | 🔒 |
| Profil | `ProfileScreen` | Statistik, Ranglisten, Needles/Socks/Batches | `_14` | 🔒 |
| Shop / Order | `ShopScreen` | Needles/Socks/Batches kaufen | `_13` | 🔒 |
| Unlock-Nachricht | `MessageOverlay` | „You have unlocked …" | `_15` `_20` `_21` | 🔒 |

> 🟠 Hinweis: `_4` ist derzeit eine Titel-Dublette (Fehl-Export); der echte Screen 4 fehlt. SVG-Nummern für My Bets/Settings noch gegenzuprüfen.

---

## B. Wiederverwendbare Komponenten

| Katalog-Name | Code-ID | Beschreibung | Beispiel | MVP |
|---|---|---|---|---|
| Top-Navigation | `TopNav` | obere Leiste: bets · create bet · my bets · Profil | alle | ✅ |
| Daumen-Navigation | `ThumbNav` | runde Knöpfe unten, **kontextabhängig** | `_2` | ✅ |
| Wählwalze | `WheelPicker` | schieb-/ziehbare Zahlen-/Auswahlwalze | `_5` | ✅ |
| Wett-Zeile | `BetRow` | eine Zeile in der Bets-Liste | `_2` | ✅ |
| Wett-Karte | `BetCard` | aufklappende Detailkarte | `_12` | ✅ |
| Fortschrittsbalken | `ProgressBar` | „x % / next check" | `Einzelteile/Erfuellungsbalken.svg` | ✅ |
| Countdown / Timer | `Countdown` | „222d 23h 39m" bis nächster Check | `Einzelteile/Uhr.svg` | ✅ |
| Verlaufs-Kurve | `SportChart` | Sparkline auf der Bet-Card | `_12` | ✅ (einfach) |
| Primär-Knopf | `PrimaryButton` | „place bet", „bet" | `_5` | ✅ |
| Wett-Satz-Generator | `BetSentence` | „I bet 59,957$ that I will …" aus Walzenwerten | `_5` | ✅ |
| Tipp-/Hinweis-Overlay | `HintOverlay` | schließbare Tipp-Kästen | Storyboard | 🔒 |

---

## C. Atomare Elemente / Icons (Ordner `Einzelteile/`)

**MVP-relevant:**

| Datei | Code-ID | Verwendung | MVP |
|---|---|---|---|
| `Profil-Icon.svg` | `IconProfile` | Profil (Topnav rechts) | ✅ |
| `Sprinter-Icon.svg` | `IconSportRun` | Sportart-Marker Laufen | ✅ |
| `Langlaeufer.svg` | `IconSportSki` | Sportart Langlauf | ✅ |
| `Play-Knopf.svg` | `IconPlay` | Start/Play (Recorder/Nav) | ✅ |
| `Nochmal-Knopf.svg` | `IconRedo` | reload/nochmal (Daumennav) | ✅ |
| `Uhr.svg` | `IconClock` | Timer/Countdown | ✅ |
| `Ort.svg` | `IconPin` | Standort / local-Marker | ✅ |
| `Globus.svg` | `IconGlobe` | globale (world) Wette | ✅ |
| `Erfuellungsbalken.svg` | `ProgressBar` (Grafik) | Fortschritt | ✅ |
| `Schloss.svg` | `IconLock` | gesperrter Zustand (Wartezeit) | ✅ |
| `Bookmark-Icon.svg` | `IconBookmark` | Merken (Topnav links) | ✅ Anzeige / 🔒 Funktion |
| `BattleBet-Wasserzeichen.svg` | `Watermark` | dezentes Hintergrund-Logo | ✅ |

**Später (🔒):** `Verzweig-Knopf.svg`→`IconShare` · `Briefumschlag.svg`→`IconMessage` · `Box.svg`/`Kisten-Knopf.svg`→`IconGift`/`IconGiftButton`.

**Gamification-Assets (🔒 später, für die Ökonomie-Stufe):**
- Socken: `Socken-Papier/Jute/Baumwolle/Leinen/Seide/Kaschmir.svg` → `SockPaper … SockCashmere`
- Nadeln: `Nadel-Bronze/Silber/Gold/Rosa/Obsidian.svg` → `NeedleBronze … NeedleObsidian`
- Lorbeeren: `Lorbeer-1…5.svg` → `Laurel1 … Laurel5`
- Batches: `Batch-<Metall>-<0…5>.svg` → `Batch<Metal><N>` · Promos → `PromoBatchColdWar/ByHeart/SpeedOnCall`

---

## D. Daten-Entitäten (MVP)

Minimal gehalten, mit **reservierten Feldern** für spätere Stufen.

**`User`** — id · username · passwordHash · createdAt
🔒 später: name, surname, email, mobile, address, settings, ranking, needles

**`Bet`** — id · name · sport · distanceKm · iterationsPerWeek · durationWeeks · entryPrice · startDate · endDate · status *(open/running/won/lost)* · participantsCount
🔒 später: sponsors, gifts, socksReward, batchCriteria, isLocal, increaseInValuePct

**`Participation`** *(User nimmt an Bet teil)* — id · userId · betId · joinedAt · progressPercent · nextCheckAt · activitiesDone · state *(active/locked/passed/failed)*
🔒 später: betPerformancePct, earnedSocks, earnedBatches

**`Activity`** *(ein absolvierter Lauf)* — id · participationId · timestamp · distanceKm · durationSec · source *(im MVP immer `simulated`)*
🔒 später: source `gps`, pace, motionControl, route

---

## E. Konventionen

- Screens `…Screen` · Komponenten `PascalCase` · Icons `Icon…` · Datenfelder `camelCase`.
- **Design-Tokens** (Orange-Akzent, Dark-Theme, Abstände, Schrift-Ersatz für Corporate S Pro) ziehen wir beim Bau der ersten Komponente aus den SVGs in eine zentrale `theme`-Datei.
- Deutsche Asset-Dateinamen bleiben; im Code über eine zentrale Asset-Konstantenliste referenziert (nicht überall der rohe Pfad).

---

## F. Herkunft & offene Punkte

- Basiert auf: Screen-SVGs (`SVGs/`), Storyboard „Durchlauf 2", Einzelteile-Assets, MVP-Schema, `SOCKS_und_Ranking_Spezifikation.md`, `Navigation_und_Interaktion_Spezifikation.md`.
- 🟠 Genaue SVG-Nummern für My Bets / Settings / Messages gegenprüfen (Screen-4-Fehlexport beachten).
- Dieser Katalog ist ein **lebendes Dokument**: Wenn wir bauen, wächst er mit (neue Komponenten, finale Tokens). Er ist unsere gemeinsame Referenz — du zeigst mit den Katalog-Namen auf Dinge, ich setze sie unter der Code-ID um.
