# Infrastruktur-Evaluation — BattleBet

**Version:** 1.0
**Stand:** 2026-07-17
**Status:** Bestandsaufnahme + Bedarf + Lücken + Stufenplan (Grundlage für Beschaffungs- und Bau-Entscheidungen)

---

## 1. Kernaussage

Dein vorhandener Stack ist ein **Webseiten-/E-Commerce-/Automations-Stack** (Webflow +
Snipcart + n8n + Hetzner-Static-Host + Cloudinary), gebaut fürs **Verkaufen von Kunst**.
BattleBet ist etwas anderes: ein **echtes App-Produkt mit Backend** (API + Datenbank +
Konten + Hintergrundjobs), plus **App-Store-Vertrieb**, und — in der Endstufe — **echtes
Geld-Handling**.

Ergebnis in einem Satz: **Ein Teil deiner Infrastruktur trägt real** (der Hetzner-Server
als Backend-Host, GitHub, der Mac, Bitwarden, teilweise n8n und Cloudinary), **das
Herzstück — ein App-Backend — und der App-Vertrieb sind neu**, und **Snipcart trägt für
Wett-Pötte/Auszahlungen NICHT**. Gute Nachricht: Für die **nächsten sichtbaren
Bau-Schritte brauchst du nichts davon** — die Lücken blockieren erst den Sprung von
„lokaler Prototyp" zu „echtes Mehrbenutzer-Produkt".

## 2. Was die App am Ende braucht (aus Spec v1.3 abgeleitet)

- **Mobile App (Flutter)** — bauen wir (existiert als lokaler Prototyp).
- **Zentraler Server / API** — die „einzige Wahrheit" (Konten, Wetten, Pots, Läufe, Urteil).
- **Datenbank** — dauerhafte Speicherung all dessen.
- **Echte Konten / Anmeldung** — Ablösung des heutigen lokalen Login-Platzhalters.
- **Lauf-Datenaufnahme + serverseitiges Urteil** — inkl. Anomalie-Erkennung & Audit.
- **Geräte-Attestierung** — Apple App Attest / Google Play Integrity (unser Baustein B0).
- **App-Vertrieb** — Testverteilung (TestFlight / Play-intern) und Stores, inkl. Signierung.
- **Build-/CI-Pfad** — Flutter-Code → installierbare App (die Sandbox kann das nicht).
- **Admin-Oberfläche (Web)** — fürs Personal (Wetten anbieten, moderieren, Audits).
- **Geld-Schicht** — Ein-/Auszahlung, Wallet, KYC, Regulatorik (Endstufe).
- Mehrsprachigkeit & Währung — steckt im App-Code, ist **kein** Infrastruktur-Thema.

## 3. Bestand → Bedarf (was trägt, was teilweise, was fehlt)

| Ressource | Heute wofür | Für BattleBet | Verdikt |
|---|---|---|---|
| **Hetzner-Server** | statischer Download-Host (assets.augustmond.com, scp/nginx) | kann das **App-Backend + Datenbank** hosten — es ist ein Linux-Server, den du per SSH betreibst | ✅ **Trägt** (Kern-Asset; Specs prüfen, ggf. größerer/zweiter Server bei Wachstum) |
| **GitHub** | Code + Versionierung (Battlebet-Repo) | Code + **Auslöser für den Build** (GitHub Actions macOS-Runner oder Codemagic bauen aus dem Repo) | ✅ **Trägt** |
| **Mac (mac-fritz-box)** | Dev-Maschine, git-Zugang | **Pflicht für iOS-Builds & Signierung** (Xcode); lokaler Flutter-Build | ✅ **Trägt** (für iOS unverzichtbar) |
| **Bitwarden** | Passwort-/Credential-Store | Backend-Secrets & API-Schlüssel sicher ablegen | ✅ **Trägt** |
| **Cloudinary** | öffentliche Bild-URLs | Profilbilder, Badges, Assets | ✅ **Trägt** (Nebenrolle) |
| **DevOps-Routine** (SSH, TLS/Zertifikate, Deploys) | für den Static-Host | direkt übertragbar auf den Backend-Betrieb | ✅ **Trägt** (Erfahrung/Verfahren) |
| **n8n** | Automations-Workflows (Snipcart→Prodigi, CMS-Lookups) | **Ops-Glue**: Webhooks, Benachrichtigungen, getriggerte Audits, Admin-Automatik — **nicht** das App-Backend | ⚠️ **Teilweise** (Helfer, nicht Kern) |
| **Webflow** | Marketing-Site/CMS (augustmond.com) | evtl. BattleBet-Landingpage/Marketing; **nicht** die Admin-App | ⚠️ **Teilweise** (nur Marketing) |
| **Snipcart** | Cart-Checkout für Kunstverkauf | Wett-Pötte / Guthaben / **Auszahlungen** an Gewinner — dafür nicht gebaut | ❌ **Trägt nicht** (falsches Werkzeug) |

## 4. Was neu dazukommen muss (die echten Lücken)

1. **App-Backend — der größte Posten.** API + Datenbank (z. B. PostgreSQL) + Anmeldung +
   Hintergrundjobs. Zwei Wege:
   - **(a) Selbst hosten auf Hetzner** (z. B. Docker + PostgreSQL): volle Kontrolle,
     kostenkontrolliert, nutzt vorhandene Infra — dafür mehr eigener Betrieb.
     Sprach-Option: ein **Dart-Backend** (Serverpod / Dart Frog) teilt die Sprache mit der
     Flutter-App.
   - **(b) Managed Backend** (Supabase, Firebase): schneller startklar, weniger Betrieb —
     dafür laufende Kosten und weniger Kontrolle.
   → **Entscheidungspunkt.**
2. **Entwickler-Konten + App-Vertrieb (unumgänglich, extern):**
   - **Apple Developer Program — ~99 $/Jahr** (Pflicht für iOS, TestFlight **und** App
     Attest-Attestierung).
   - **Google Play Console — 25 $ einmalig** (Pflicht für Android, Play Integrity).
     Achtung: neue **Privat**-Konten müssen vor der Veröffentlichung eine geschlossene
     Testphase mit **≥ 12 Testern über 14 Tage** durchlaufen — deshalb besser als
     **Organisation** anmelden und früh starten.
   - Wir brauchen beide **früh**, weil die Attestierung (Baustein B0) daran hängt.
3. **Build-/CI-Pfad** (Flutter → installierbare App): auf dem **Mac** (Xcode + Flutter)
   oder über **Cloud-CI** (Codemagic / GitHub Actions mit macOS). Klein, aber nötig —
   die Cloud-Sandbox kann Flutter nicht bauen.
4. **Admin-Oberfläche (Web)** fürs Personal (Wetten anbieten/moderieren, Audits bearbeiten):
   ein eigener kleiner Web-Build; kommt später. n8n kann anfangs Übergangs-Werkzeuge liefern.
5. **Geld-Schicht (Endstufe, der dickste Brocken — mehr Recht als Technik):**
   Zahlungsdienstleister mit **Auszahlungen/Wallet** (z. B. Stripe Connect o. ä. — Achtung:
   viele Anbieter schränken Glücksspiel-nahe Nutzung ein), **KYC** (Identitätsprüfung) und
   **Glücksspiel-/Regulatorik-Compliance** je Land + **juristischer Rat**. Snipcart deckt
   davon nichts ab.

## 5. Stufenplan — was wann nötig ist

- **Stufe 0 — jetzt (lokaler Prototyp):** **braucht nichts Neues.** Wir bauen App-UI und
  -Logik lokal weiter (bet-Knopf, Money-Typ, Screens). Alle Lücken oben sind hier
  irrelevant.
- **Stufe A — Server-Durchstich** (erstes echtes Mehrbenutzer-Fundament, **noch kein echtes
  Geld**): Backend (Hetzner oder Managed) + echte Konten + Wetten/Läufe serverseitig
  (Bewegung noch simuliert, aber **vom Server geurteilt**) + Build-CI + Apple/Google-Konten
  → erste **installierbare Testversion**. Nutzt vor allem vorhandene Infra + die zwei
  Entwickler-Konten.
- **Stufe B — echte Sensoren + Anti-Cheat:** Sensor-Aufnahme in der App, Attestierung
  (braucht die Konten aus A), Server-Anomalie/Audit, Admin-Oberfläche. Neubau auf demselben
  Backend.
- **Stufe C — echtes Geld:** Payment/Payout/Wallet + KYC + Regulatorik + Legal. Größter
  externer und rechtlicher Schritt.

## 6. Empfehlung & Entscheidungspunkte

- **Ungebremst weiterbauen:** Stufe 0 läuft ohne jede Beschaffung — die Infra-Lücken halten
  die nächsten sichtbaren Schritte **nicht** auf.
- **Bald entscheiden (für Stufe A):** Backend **selbst auf Hetzner** vs. **Managed
  (Supabase/Firebase)** — Kontrolle & Kosten gegen Tempo.
- **Früh & günstig beschaffen:** **Apple-** (~99 $/J) und **Google-Entwicklerkonto** (25 $
  einmalig) — als **Organisation** (Verifizierung + Tester-Regel), weil Attestierung und
  Tests daran hängen und die Anmeldung Vorlauf hat.
- **Rechtzeitig extern klären (kein Technik-Thema):** Geld & Regulatorik — vor jeder echten
  Auszahlung juristischen Rat einholen.
- **Zu bestätigen:** die konkreten Specs deines Hetzner-Servers (CPU/RAM/OS) — damit wir
  wissen, ob er Backend + Datenbank trägt oder ein zweiter/größerer Server sinnvoll ist.

## Quellen

- Apple Developer Program — Mitgliedschaft & Kosten: https://developer.apple.com/programs/whats-included/ , https://developer.apple.com/support/compare-memberships/
- Google Play Console — Einstieg & Gebühr: https://support.google.com/googleplay/android-developer/answer/6112435 ; 25-$-Gebühr + 12-Tester-Regel: https://www.iconikai.com/blog/google-play-developer-account-fee-2026
