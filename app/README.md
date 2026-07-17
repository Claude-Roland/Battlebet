# BattleBet — App (Flutter)

Erster sichtbarer Durchstich: die **Bets-Liste** (`BetsListScreen`).

## Was hier liegt
Echter Flutter-Quellcode. Aufbau (siehe `Element_Katalog_MVP.md` im Projektordner):

```
lib/
  main.dart                    App-Start, Theme, Startseite
  theme/app_theme.dart         Farben & Design-Tokens
  models/bet.dart              Datenmodell "Bet"
  data/sample_bets.dart        lokale Beispieldaten (kein Backend)
  widgets/top_nav.dart         TopNav (obere Leiste)
  widgets/bet_row.dart         BetRow (eine Wett-Zeile)
  screens/bets_list_screen.dart  BetsListScreen (die Seite)
```

## Bauen / starten (auf einem Rechner mit Flutter)
```
flutter create .        # erzeugt einmalig die Plattform-Ordner (android/ios/web)
flutter pub get
flutter run -d chrome   # oder -d ios / -d android
```

> Die Plattform-Ordner (`android/`, `ios/`, `web/`) und `build/` sind **nicht** eingecheckt — sie werden mit `flutter create .` erzeugt.

## Hinweis zur Vorschau
Die Cloud-Sandbox von Claude darf Googles Artefakt-Server (`storage.googleapis.com`) nicht erreichen, wo Flutter sein Dart-SDK/Engine holt — dort lässt sich Flutter also **nicht** bauen. Die Screenshots, die Roland während der Entwicklung sieht, sind deshalb **originalgetreue HTML-Vorschauen** desselben Screens; der ausgelieferte Code ist echtes Flutter und baut auf einem normalen Rechner/CI regulär.
