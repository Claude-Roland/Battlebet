import 'dart:io';

import 'package:postgres/postgres.dart';

/// Gemeinsamer Verbindungs-Pool zur Postgres-DB (prozessweiter Singleton).
/// Konfiguration aus Umgebungsvariablen; lokale Dev-Standardwerte als Rueckfall.
final db = Pool<void>.withEndpoints(
  [
    Endpoint(
      host: Platform.environment['PGHOST'] ?? 'localhost',
      port: int.tryParse(Platform.environment['PGPORT'] ?? '') ?? 5432,
      database: Platform.environment['PGDATABASE'] ?? 'battlebet_dev',
      username: Platform.environment['PGUSER'] ?? 'battlebet',
      password: Platform.environment['PGPASSWORD'] ?? 'battlebet_dev_pw',
    ),
  ],
  settings: PoolSettings(
    maxConnectionCount: 8,
    sslMode: Platform.environment['PGSSL'] == 'require'
        ? SslMode.require
        : SslMode.disable,
  ),
);
