# Statisches Ausliefern des Flutter-Web-Bundles hinter dem Edge-Caddy.
# Erwartet, dass VORHER `flutter build web --release --dart-define=BB_API=...`
# lief (siehe .github/workflows/build-web.yml). Interner Port 80.
FROM caddy:2-alpine
COPY web.Caddyfile /etc/caddy/Caddyfile
COPY build/web /srv
