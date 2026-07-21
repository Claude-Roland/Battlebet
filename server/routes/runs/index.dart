import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/ticker.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _myRuns(context),
    HttpMethod.post => _record(context),
    _ => fail('Method not allowed', status: 405),
  };
}

Future<Response> _myRuns(RequestContext context) async {
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final uid = me['id'].toString();
  final res = await db.execute(
    Sql.named('''
      SELECT id, sport, activity, distance_meters, source, total_meters,
             total_seconds, avg_pace, recorded_at
      FROM runs WHERE user_id = @uid:uuid ORDER BY recorded_at DESC LIMIT 200
    '''),
    parameters: {'uid': uid},
  );
  final runs = res.map((row) {
    final r = row.toColumnMap();
    return {
      'id': r['id'].toString(),
      'sport': (r['sport'] as num).toInt(),
      'activity': (r['activity'] as num).toInt(),
      'distanceMeters': (r['distance_meters'] as num).toInt(),
      'source': (r['source'] as num).toInt(),
      'totalMeters': (r['total_meters'] as num).toInt(),
      'totalSeconds': (r['total_seconds'] as num).toInt(),
      'avgPace': (r['avg_pace'] as num).toInt(),
      'recordedAt': (r['recorded_at'] as DateTime).toUtc().toIso8601String(),
    };
  }).toList();
  return ok({'runs': runs});
}

/// Ein Lauf ist eigenstaendig (nicht an eine Wette gekoppelt). Er wird gespeichert
/// und der Server meldet zurueck, welche der aktiven Wetten des Nutzers er erfuellt.
/// Der Wochen-Checkpoint (Ticker) wertet ihn spaeter gegen alle passenden Wetten aus.
Future<Response> _record(RequestContext context) async {
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final uid = me['id'].toString();
  final body = await readJson(context);
  final sport = (body['sport'] as num?)?.toInt() ?? 0;
  final source = (body['source'] as num?)?.toInt() ?? 0;
  final totalMeters = (body['totalMeters'] as num?)?.toInt() ?? 0;
  final totalSeconds = (body['totalSeconds'] as num?)?.toInt() ?? 0;
  final avgPace = (body['avgPace'] as num?)?.toInt() ?? 0;
  final samples = body['samples'];
  if (totalMeters <= 0) return fail('A run needs a distance.');
  final activity = classifyPace(avgPace);

  final ins = await db.execute(
    Sql.named('''
      INSERT INTO runs (user_id, source, sport, activity, distance_meters,
        total_meters, total_seconds, avg_pace, qualifying_meters, samples)
      VALUES (@uid:uuid, @src, @sport, @act, @dm, @tm, @ts, @ap, @dm, @samples:jsonb)
      RETURNING id, recorded_at
    '''),
    parameters: {
      'uid': uid, 'src': source, 'sport': sport, 'act': activity, 'dm': totalMeters,
      'tm': totalMeters, 'ts': totalSeconds, 'ap': avgPace,
      'samples': samples == null ? null : jsonEncode(samples),
    },
  );
  final row = ins.first.toColumnMap();

  final matched = await db.execute(
    Sql.named('''
      SELECT b.id, b.name FROM bets b
      JOIN participations p ON p.bet_id = b.id AND p.user_id = @uid:uuid AND p.state = 0
      WHERE b.status = 1
        AND @dm:int4 >= round(b.distance_km * 1000)
        AND ( (b.sport IN (0, 1, 5)
                AND @act:int4 >= CASE b.sport WHEN 1 THEN 2 WHEN 0 THEN 1 WHEN 5 THEN 0 ELSE 1 END)
              OR (b.sport NOT IN (0, 1, 5) AND b.sport = @sport:int4) )
    '''),
    parameters: {'uid': uid, 'dm': totalMeters, 'act': activity, 'sport': sport},
  );
  final matchedBets = matched.map((r) {
    final m = r.toColumnMap();
    return {'id': m['id'].toString(), 'name': m['name']};
  }).toList();

  return ok({
    'id': row['id'].toString(),
    'sport': sport,
    'activity': activity,
    'distanceMeters': totalMeters,
    'matchedBets': matchedBets,
    'recordedAt': (row['recorded_at'] as DateTime).toUtc().toIso8601String(),
  }, status: 201);
}
