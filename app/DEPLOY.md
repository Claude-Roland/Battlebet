# BattleBet Web — Build & Deploy

Das Flutter-Web-Frontend wird als statisches Bundle gebaut und hinter dem
Edge-Reverse-Proxy ausgeliefert.

## Bauen (lokal)

    cd app
    flutter build web --release --dart-define=BB_API=https://api.battlebet.app

Ergebnis: `app/build/web/` (statisches Bundle). Die API-Adresse wird zur
**Bauzeit** fest eingebacken (`BB_API`, Standard `http://localhost:8081`).

## Routing

- App: `https://battlebet.app`  (dieses Bundle)
- API: `https://api.battlebet.app`  (Dart-Frog-Backend, gleiche Instanz)

CORS ist backend-seitig offen (`*`), Cross-Origin App↔API funktioniert.

## Container / CI

`.github/workflows/build-web.yml` baut bei Push unter `app/**` das Bundle,
verpackt es via `app/Dockerfile` (schlanker Caddy-Static-Server auf Port 80)
und pusht `ghcr.io/claude-roland/battlebet-web:latest`. Der Edge-Proxy leitet
`battlebet.app` auf diesen Container, `api.battlebet.app` auf das Backend.
