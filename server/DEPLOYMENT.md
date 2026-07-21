# BattleBet Backend – Deployment

Gebaut per GitHub Actions (`.github/workflows/build-backend.yml`) und als
Container-Image nach GHCR gepusht: `ghcr.io/claude-roland/battlebet-backend:latest`.

Betrieb: Hetzner CPX22 (188.245.56.104), isolierter Docker-Stack `/opt/battlebet`
(eigene PostgreSQL 16, hinter dem bestehenden Caddy). Vollständige Anleitung:
`../Server-Einrichtung/03_Runbook_Deployment.md`.
