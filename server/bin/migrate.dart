import 'dart:io';

import 'package:postgres/postgres.dart';

/// Wendet alle migrations/*.sql der Reihe nach an (fuer Deploy/Neuaufsetzen).
Future<void> main() async {
  final env = Platform.environment;
  final conn = await Connection.open(
    Endpoint(
      host: env['PGHOST'] ?? 'localhost',
      port: int.tryParse(env['PGPORT'] ?? '') ?? 5432,
      database: env['PGDATABASE'] ?? 'battlebet_dev',
      username: env['PGUSER'] ?? 'battlebet',
      password: env['PGPASSWORD'] ?? 'battlebet_dev_pw',
    ),
    settings: ConnectionSettings(
      sslMode: env['PGSSL'] == 'require' ? SslMode.require : SslMode.disable,
    ),
  );
  final files = Directory('migrations')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final f in files) {
    stdout.writeln('applying ${f.uri.pathSegments.last}');
    await conn.execute(f.readAsStringSync(), queryMode: QueryMode.simple);
  }
  await conn.close();
  stdout.writeln('migrations done (${files.length} file(s))');
}
