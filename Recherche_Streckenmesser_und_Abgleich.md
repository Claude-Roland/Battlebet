# Recherche & Abgleich: Streckenmesser — Best Practice vs. unsere Annahmen

**Version:** 1.0
**Stand:** 2026-07-17
**Status:** Rechercheergebnis + Bewertung; Grundlage für ein Spec-Update (v1.3)
**Methode:** Tiefenrecherche über 5 Suchrichtungen, 20 Quellen, 93 extrahierte Aussagen,
davon 25 gegnerisch geprüft → **17 bestätigt, 8 aktiv widerlegt**. Quellen unten.

---

## 1. Kurzfazit

Reale Geld-Fitness-Apps lösen „zuverlässig messen + fälschungssicher" **nicht über perfekte
Sensorik**, sondern über einen **mehrschichtigen Vertrauens-Stack**: erzwungene Anbindung an
einen echten Tracker (statt manueller Eingabe) + serverseitige Anomalie-/ML-Erkennung +
**Audits mit Nachweispflicht** (der Verdächtige muss Beweise liefern) + **harte Konsequenz**
(Ausschluss ohne Rückerstattung). Das **bestätigt unsere Kern-Architektur** (Sensor-Fusion,
Server-Urteil über signierte Rohdaten, Geräte-Attestierung, gestufte Prüfung), schärft sie
aber an drei Stellen:

1. **Menschliche Audits mit Beweislast beim Nutzer + Abschreckung** sind ein eigener Pfeiler,
   den wir bislang unterbewertet haben.
2. Unsere **Pot-Ligen-Idee** (Prüftiefe nach Auszahlungshöhe) fand **keinen dokumentierten
   Branchen-Präzedenzfall** — plausibel, aber unbewiesen und mit Komplexitätskosten.
3. GPS ist im Alltag **metergenau, nicht sub-metergenau** — Regeln brauchen Toleranzbänder.

## 2. Was die Praxis zeigt (belegte Best Practices)

**Wie reale Apps urteilen**
- **StepBet:** erzwingt Tracker-Anbindung (Fitbit / Apple Health / Google Fit / Garmin) statt
  manueller Eingabe; „aktives Monitoring" + Flagging; **Null-Toleranz: Ausschluss ohne
  Rückerstattung**; Geflaggte müssen Zusatzdaten nachreichen. [1]
- **HealthyWage:** Audits **zufällig UND algorithmisch** getriggert; Nachweis = **Screenshot**
  der Schritte (synchronisiert) bzw. Tagesfotos des Displays neben einer Zeitung (nicht
  synchronisiert). [2]
- **Strava** (Referenzfall für Integrität): entfernt geflaggte Aktivitäten automatisch aus den
  Leaderboards; setzt **primär supervised-ML** auf jahrelang community-gelabelten Daten ein
  (nicht bloß Fixregeln); zielt auf Transportmittel-Betrug (Auto / E-Bike / Rad-als-Lauf);
  **gibt Grenzen offen zu** (Drafting, Rückenwind, Velodrom nicht zuverlässig erkennbar). Feb
  2026 entfernte Strava 2,3 Mio E-Bike- und 1,6 Mio Fahrzeug-Aktivitäten. [3][4]

**Technische Bausteine**
- **On-Device allein reicht nicht.** Standard-Schrittzähler sind trivial mechanisch täuschbar
  (Fahrrad-Kurbel, Hund, Ventilator, Pendel, Vibration). Wirksam ist die **Quervalidierung
  GPS-Geschwindigkeit × Beschleunigungs-Kadenz** — der Angreifer muss beide Ströme konsistent
  fälschen. [5]
- **Mock-Location-Checks sind Standard, aber begrenzt.** Android API 31+: `Location.isMock`
  (löst das veraltete `isFromMockProvider` ab); SDKs prüfen Fake-GPS-Apps, Mock-Einstellung,
  Root/Jailbreak. Erfassen aber **nur** Spoofing über die offizielle Mock-API — nicht
  Hardware-Injection oder API-Level-Manipulation. [6]
- **Deshalb Server + Attestierung.** Der Standort lässt sich auf API-Ebene fälschen (ein
  MITM-Proxy ändert Lat/Long oder IP, ohne das Gerät anzufassen); client-seitige Schutz-
  mechanismen sind umgehbar. Apple App Attest / Google Play Integrity sollen genau das
  schließen — sie **heben die Hürde deutlich, sind aber kein Wall** (die starke Aussage „nur
  verifizierte Apps erreichen das Backend" wurde in der Prüfung als überzogen widerlegt). [7][8]

**Mess-Physik (harte Grenzen)**
- Roh-GPS auf Smartphones hat eine **physikalische Obergrenze weit oberhalb von Zentimetern**:
  Selbst aufwändige RTK/INS-Fusion (jenseits dessen, was Consumer-Apps nutzen) erreicht im
  Stadt-Canyon nur ~0,38–0,42 m; realistische Consumer-Fusion eher **~1,6 m (Bestfall) bis
  ~4,7 m** über 20 Minuten Gehen. [9][10]
- **Dual-Frequency (L1/L5)** ist der wichtigste Consumer-Hebel (deutlich weniger Multipath:
  L5/E5a max ~3 m gegenüber L1/E1-Spitzen bis ~10 m). [10]
- **Sub-Meter-Alltagsgenauigkeit in der Stadt wurde aktiv widerlegt** — davon NICHT ausgehen.

## 3. Abgleich mit unseren v1.2-Annahmen

| Unsere Annahme (v1.2) | Verdikt | Befund |
|---|---|---|
| Absolute Sicherheit unmöglich → Betrug unlohnend machen (Regler) | ✅ Bestätigt | Selbst Strava (reifes ML) gibt harte Grenzen offen zu. |
| Server = einzige Wahrheit, urteilt über (signierte) Rohdaten | ✅ Bestätigt (stärkster Punkt) | Client-seitig allein unzureichend (API-Spoofing); Server + Attestierung ist der Standard. |
| Sensor-Fusion (GPS × Kadenz …) | ✅ Bestätigt | Einzelsensor nutzlos; GPS-Speed × Kadenz ist der genannte wirksame Hebel. |
| Serverseitige Anomalie-Erkennung, wird mit Daten besser | ✅ Bestätigt | Genau Stravas supervised-ML-auf-Community-Labels. |
| Geräte-Attestierung (App Attest / Play Integrity) | ✅ mit Einschränkung | Wichtiger Layer, aber **kein Wall** — nicht über-vertrauen. |
| Identitätslücke Gerät ≠ Person | ✅ Bestätigt | Geolokation beweist WO, nicht WER. |
| Deckel/Regler nach max. Einzel-Gewinn (Pot-Ligen) | ⚠️ Überdenken | Prinzip plausibel, aber **kein dokumentierter Branchen-Präzedenz** gefunden — unbewiesene (evtl. eigene) Innovation mit Komplexitätskosten. |
| iOS zuerst | ⚠️ Teils | Sinnvoll, aber der iOS-vs-Android-Vorsprung ist empirisch **nicht belegt** (Evidenz fast nur Android). iOS ≠ automatisch sicher. |
| Distanz implizit „genau genug" | ⚠️ Überdenken | GPS ist metergenau, nicht sub-meter → Regeln mit **Toleranzband**. |

**Lücken (was wir unterbewertet haben)**
1. **Audit-mit-Beweislast + Abschreckung als eigener Pfeiler.** Reale Apps entscheiden nicht
   rein automatisch: getriggerte/zufällige Audits, bei denen der **Verdächtige** Beweise
   liefern muss, plus **Ausschluss ohne Rückerstattung** als Abschreckung. Unser Baustein B6
   nennt Prüffenster/Stichprobe — wir sollten „Beweislast beim Geflaggten" + „Verwirkung des
   Einsatzes" zu einem Kern-Pfeiler erheben.
2. **Vertrauensanker echter Tracker.** Kein Zahlen-Tippen; Anbindung an Apple Health / Health
   Connect / Fitbit / Garmin als härtere Quelle. **Aber:** In HealthKit/Health Connect lassen
   sich gefälschte Workouts schreiben → **Herkunfts-/Quell-App-Attribution** und Ausschluss
   manuell eingetragener Daten nötig (in der Recherche unterbelegt, aber logische Gegenmaßnahme).
3. **Dual-Frequency-Geräte** als konkreter Mess-Hebel (evtl. später Geräte-Eignung je Liga).

## 4. Offene Fragen (von der Recherche NICHT beantwortet)

- **iOS-Seite konkret:** Mock-Situation ohne Jailbreak, reale App-Attest/DeviceCheck-Praxis — unbelegt.
- **Kopplung Prüftiefe ↔ Auszahlungshöhe:** kein Beleg, dass/wie Anbieter das tun — betrifft
  unsere Pot-Ligen direkt.
- **Stellvertreter/Account-Sharing:** wirksame Gegenmaßnahmen jenseits Foto/Screenshot — unterbelegt.
- **Gefälschte Workouts in HealthKit/Health Connect:** dokumentierte Gegenmaßnahmen (Provenance,
  Quell-App-Attribution) — unterbelegt.

## 5. Vorschlag: Änderungen an der Spec (v1.3)

1. In 4.4 einen Pfeiler **„Audit + Beweislast + Verwirkung"** ergänzen: Bei Flag muss der Nutzer
   nachweisen; unbewiesen = kein Gewinn; Betrug = Ausschluss + Einsatz verwirkt.
2. Baustein B0 präzisieren: **„Vertrauensanker echter Tracker" + Herkunfts-Attribution** (keine
   manuell eingetragenen Workouts; Quell-App prüfen).
3. Attestierung explizit als **Hürde, nicht Wall** kennzeichnen.
4. In 4.4 die Mess-Realität festhalten: **metergenau → Regeln mit Toleranzband**; Dual-Frequency
   bevorzugt.
5. Pot-Ligen als **eigene Hypothese** markieren (kein Branchen-Präzedenz) — bewusst so wählen,
   mit offenem Blick auf die Komplexitätskosten.
6. „iOS zuerst" beibehalten, aber **nicht als Sicherheit auslegen**; iOS-Attest-Praxis später
   gezielt nachrecherchieren.

## Quellen

- [1] StepBet Support — „How do you prevent cheating" — https://stepbet-support.zendesk.com/hc/en-us/articles/35418653059355-How-do-you-prevent-cheating
- [2] HealthyWage — „Step Audits" — https://www.healthywage.com/rules/step-audits/
- [3] Strava Engineering — „Keeping Strava's Segment Leaderboards Fair" — https://stories.strava.com/articles/keeping-stravas-segment-leaderboards-fair-an-engineers-perspective
- [4] Strava Support — „How to Report Cheating on Strava" — https://support.strava.com/hc/en-us/articles/206522304-How-to-Report-Cheating-on-Strava
- [5] TestDevLab — „Testing fitness apps: can you cheat the algorithm" — https://www.testdevlab.com/blog/testing-fitness-apps-can-you-cheat-the-algorithm
- [6] Android API 31 Diff — `Location.isMock` — https://developer.android.com/sdk/api_diff/31/changes/android.location.Location
- [7] Approov — „Stop geo-spoofing…" — https://approov.io/blog/stop-geo-spoofing-with-secure-api-integration-for-mobile-application ; OWASP MASWE-0005 / Mobile Top 10 M7
- [8] Guardsquare — „App attestation on Android and iOS" — https://www.guardsquare.com/blog/android-and-ios-app-attestation ; Approov — „Limitations of Google Play Integrity API"
- [9] MDPI Sensors 2024, 24(18):5907 (RTK/INS-Fusion, Dezimeter im Stadt-Canyon) — https://doi.org/10.3390/s24185907
- [10] Inside GNSS — „Galileo Hits the Spot: dual-frequency with smartphones" — https://insidegnss.com/galileo-hits-the-spot-testing-gnss-dual-frequency-with-smartphones/
- ACGCS — „Geolocation Fraud and Proxy Betting" (Gerät ≠ Person) — https://www.acgcs.org/articles/geolocation-fraud-and-proxy-betting-challenges-for-sportsbooks
