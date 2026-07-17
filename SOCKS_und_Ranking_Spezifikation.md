# BattleBet — SOCKS- & Ranking-Spezifikation

**Status:** Athletenseitig implementierungsreif · **v1.0**
**Datum:** 11. Juli 2026
**Quelle:** Zusammengeführt aus den Arbeitsentwürfen `socks Kopie.xlsx` und `socks-Value Kopie.xlsx` (Nov. 2018; inzwischen aussortiert). Dieses Dokument ist die maßgebliche Grundlage.
**Zweck:** Erfüllt die im Briefing geforderte Auftraggeber-Lieferung *„mathematisches Modell für ‚Socken'"* sowie die *„Regel zur Verteilung der Batches"*.

> **Änderungen ggü. v0.2:** BATCHES-Regel bestätigt (Abschnitt 2.1). Damit ist die gesamte **athletenseitige** Logik (SOCKS → laurels → BATCHES) entschieden und implementierungsreif. Offen bleiben nur bewusst zurückgestellte, gambler-seitige Punkte (Manager-Kennzahl, Manager-Pins, NEEDLES).

---

## 0. Überblick — drei Fortschritts-Systeme

| System | Seite | Was es misst | Mündet in |
|---|---|---|---|
| **SOCKS** | Athlet | Laufende Belohnungs-„Währung": Distanz × Häufigkeit | Anzeige in Bet-Cards & Profil, Shop/Order |
| **Achievements (Sterne)** | Athlet | Einmal-Bestleistungen (max. Distanz) → *laurels* | **laurels → BATCHES**, „World ranking athlete" |
| **Sport-Manager-Level** | Gambler | Aktivität als Wett-Ersteller/-Manager | „World ranking gambler", Manager-Pins |

**Anknüpfung an das App-Datenmodell (Briefing-Schema):** Settings `show SOCKS` / `show LAURELS`; DB `User Ranking` (*World ranking gambler / athlete, unlocked NEEDLE and SOCKS*); DB `BATCHES` (*laurels > unlocked BATCHES*); Server *„weist BATCHES nach def. Kriterien zu"* → **die Kriterien liefert dieses Dokument.**

---

## 1. SOCKS — die Lauf-Belohnungswährung

SOCKS verdient man fortlaufend fürs Laufen. Sie steigen in **sechs Material-Stufen** auf.

### 1.1 Material-Stufen und Wert  ✅ entschieden

Basiseinheit = **paper**. Ein Sock höherer Stufe entspricht einer festen Anzahl paper:

| Stufe | Material | Wert (in paper) | Umrechnung |
|---|---|---:|---|
| 1 | paper | 1 | Basiseinheit (1 paper = 1 km im Grundfall) |
| 2 | jute | 9 | 9 paper = 1 jute |
| 3 | cotton | 15 | 15 paper = 1 cotton |
| 4 | linen | 23 | 23 paper = 1 linen |
| 5 | silk | 35 | 35 paper = 1 silk |
| 6 | cashmere | 55 | 55 paper = 1 cashmere |

Der akkumulierte paper-Stand wird zur Anzeige „gierig" von oben in Materialien zerlegt (z. B. 70 paper = 1 silk + 1 jute + 6 paper).

### 1.2 Effort-Faktor (belohnt Wochen-Häufigkeit)  ✅ entschieden

`k` = der wievielte qualifizierende Lauf dieser Woche.

| Lauf der Woche `k` | 1 | 2 | 3 | 4 | 5 | 6 | 7+ |
|---|---:|---:|---:|---:|---:|---:|---:|
| Effort-Faktor | 0,0 | 0,1 | 0,2 | 0,4 | 0,6 | 0,8 | 1,0 |

Ab dem 7. Lauf der Woche bleibt der Faktor bei 1,0.

### 1.3 Verdienst-Formel — **pro Einzellauf**  ✅ entschieden

```
paper(Lauf) = Distanz_km × (1 + Effort-Faktor(k))
```

Jeder abgeschlossene Lauf wird **sofort** gutgeschrieben (passt zum Recorder). `k` ergibt sich aus der Zahl der bereits absolvierten Läufe in der laufenden Woche.

**Rechenbeispiele (Woche mit vier 5-km-Läufen):**

| Lauf | `k` | Effort | paper = 5 × (1+Effort) |
|---|---:|---:|---:|
| Mo | 1 | 0,0 | 5,0 |
| Mi | 2 | 0,1 | 5,5 |
| Fr | 3 | 0,2 | 6,0 |
| So | 4 | 0,4 | 7,0 |
| **Summe Woche** | | | **23,5 paper → 1 linen + 0,5 paper** |

> **Woche = Kalenderwoche (Mo–So).** Alternative „rollierende 7 Tage" ist fairer, aber aufwändiger — für Start Kalenderwoche. (Kleine Restfrage, blockiert nichts.)

*Die ursprüngliche „Sock Level"-Lookup-Tabelle aus `socks-Value` wurde verworfen — SOCKS werden ausschließlich über die Formel oben berechnet.*

---

## 2. Athleten-Achievements (Sterne) → laurels → BATCHES

Einmalige Distanz-Bestleistungen schalten Sterne frei: **sechs Kategorien × fünf Stufen** (★ … ★★★★★). Jede Stufe wird durch **eine einzelne** Laufdistanz erreicht (nicht kumuliert).

| Kategorie | ★ | ★★ | ★★★ | ★★★★ | ★★★★★ |
|---|---|---|---|---|---|
| **tin star** | started | ≥ 1 km | ≥ 2,5 km | ≥ 5 km | ≥ 7 km |
| **bronze star** | ≥ 10 km | ≥ 12 km | ≥ 13 km | ≥ 14 km | ≥ 15 km |
| **silver star** | ≥ 20 km | ≥ 22 km | ≥ 23 km | ≥ 24 km | ≥ 25 km |
| **gold star** | ≥ 30 km | ≥ 32 km | ≥ 33 km | ≥ 34 km | ≥ 35 km |
| **sapphire star** | ≥ 40 km | ≥ 42 km | ≥ 43 km | ≥ 44 km | ≥ 45 km |
| **obsidian star** | ≥ 50 km | ≥ 60 km | ≥ 70 km | ≥ 80 km | ≥ 90 km |

Jeder freigeschaltete Stern = **1 laurel**.

### 2.1 laurels → BATCHES  ✅ entschieden

Zwei Wege zu einem BATCH:

1. **Kategorie-BATCH** — wer alle 5 Sterne einer Kategorie voll hat, dessen 5 laurels verschmelzen zu **1 BATCH dieser Kategorie** (tin-BATCH … obsidian-BATCH). Max. 6 Stück. Selbsterklärend: „Kategorie gemeistert".
2. **„by heart"-BATCH** — wer eine komplette Wette erfolgreich durchzieht, erhält das Schild-Abzeichen aus dem Vollversions-Schema. Kern-Auszeichnung fürs Durchhalten, unabhängig von Sternen.

---

## 3. Sport-Manager-Level (Gambler-Seite)

Fortschritt als Wett-Ersteller/-Manager. Bestimmt aus **Anzahl gemanagter Wetten** (Spalten) × **Manager-Kennzahl** (Zeilen).

| Manager-Kennzahl | 1 bet | ≥ 2 bets | ≥ 5 bets | ≥ 10 bets |
|---:|---|---|---|---|
| **0,1** | novice | novice | novice | experienced |
| **0,5** | novice | novice | experienced | experienced |
| **1,0** | experienced | experienced | influencer | influencer |
| **1,5** | influencer | influencer | whisperer | whisperer |
| **2,5** | whisperer | whisperer | elite | elite |
| **7,5** | elite | elite | puppet masters | puppet masters |

Rangfolge: **novice → experienced → influencer → whisperer → elite → puppet masters**.

> 🟠 **ZURÜCKGESTELLT — Manager-Kennzahl (0,1 … 7,5):** In der Quelltabelle stand links eine unbeschriftete Zahlenspalte. Sie bestimmt zusammen mit der Wett-Anzahl den Rang, aber niemand hat notiert, *was* sie misst — vermutlich das gemanagte Einsatz-/Pot-Volumen. Wird festgelegt, wenn die Gambler-Seite gebaut wird (nach MVP). Nicht startkritisch.

### 3.1 Manager-Pins  🟠 ZURÜCKGESTELLT

Gegenstück zu den Athleten-Sternen auf der Manager-Seite; in der Quelle nur angefangen (Silver-Pin fehlt, Distanz-Kriterien wirken versehentlich von den Sternen kopiert). **Nach MVP** neu zu definieren — für den Start nicht wichtig.

---

## 4. Abbildung auf das App-Datenmodell

| Spezifikations-Element | DB / Feld im Briefing | Version ab |
|---|---|---|
| SOCKS-Stand & Material | `User's bets` / `All bets` → *SOCKS*; Settings `show SOCKS` | Vollversion (Anzeige teils früher) |
| Bewegungs-Rohdaten (Distanz, Timestamps, `k`) | `Bewegungsdaten` (Timestamps, Distances, Iteration/Week, Motion Control) | ab Vorversion (MVP: „hard coded") |
| Sterne / laurels | `User Ranking` (*World ranking athlete*) | Grund-/Vollversion |
| BATCHES | `BATCHES` (*laurels > unlocked BATCHES*); Server *„weist BATCHES … zu"* | Vollversion |
| Manager-Level & Pins | `User Ranking` (*World ranking gambler*); `Rankings` | Grund-/Vollversion |
| Order (Kauf NEEDLES/SOCKS/BATCHES) | `Order` | Vollversion |

---

## 5. Status der offenen Punkte

**Entschieden (11.07.2026):**
- **1** paper = 1 km (Basiseinheit, kein „PP" mehr) ✅
- **2** Effort-Faktor verbindlich ✅
- **3** Abrechnung **pro Einzellauf**, Effort über Lauf-Index der Woche ✅
- **4** Formel nutzen, Lookup-Tabelle verworfen ✅
- **5** BATCHES-Regel: Kategorie-BATCH + „by heart"-BATCH (Abschnitt 2.1) ✅
- **6/8** Schreibweisen normiert: *sapphire, obsidian, laurels, whisperer* ✅

**Bewusst zurückgestellt (nach MVP / recherchiert Roland):**
- **7** Bedeutung der Manager-Kennzahl (0,1 … 7,5).
- **9** Manager-Pins vervollständigen.
- **NEEDLES** — Definition & Erwerb (Roland klärt).
- Kleinigkeit: Wochenfenster Kalenderwoche vs. rollierende 7 Tage.

---

## 6. Herkunft & Konsolidierungs-Entscheidungen

- Zusammengeführt aus zwei Arbeitsentwürfen (Nov. 2018), die nicht von Roland stammten; `socks-Value` war die klarere Basis, `socks Kopie` (mit `#DIV/0!` und verrutschten Bezügen) nur zur Gegenprüfung. Beide Dateien sind aussortiert; ihr Inhalt ist hier vollständig aufgegangen.
- Wo sich die Quellen widersprachen, wurde eine Logik gewählt und der Konflikt transparent gemacht.
- **v1.0-Stand:** Die athletenseitige SOCKS-/laurels-/BATCHES-Logik ist entschieden und implementierungsreif. Die gambler-seitigen Punkte (7, 9, NEEDLES) reifen bis nach dem MVP nach.
