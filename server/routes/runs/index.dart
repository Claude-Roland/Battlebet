import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';
import 'package:battlebet_server/src/errors.dart';

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
      SELECT id, bet_id, source, total_meters, total_seconds, avg_pace,
             qualifying_meters, verdict, recorded_at
      FROM runs WHERE user_id = @uid:uuid ORDER BY recorded_at DESC LIMIT 200
    '''),
    parameters: {'uid': uid},
  );
  final runs = res.map((row) {
    final r = row.toColumnMap();
    return {
      'id': r['id'].toString(),
      'betId': r['bet_id']?.toString(),
      'source': (r['source'] as num).toInt(),
      'totalMeters': (r['total_meters'] as num).toInt(),
      'totalSeconds': (r['total_seconds'] as num).toInt(),
      'avgPace': (r['avg_pace'] as num).toInt(),
      'qualifyingMeters': (r['qualifying_meters'] as num).toInt(),
      'verdict': r['verdict'] == null ? null : (r['verdict'] as num).toInt(),
      'recordedAt': (r['recorded_at'] as DateTime).toUtc().toIso8601String(),
    };
  }).toList();
  return ok({'runs': runs});
}

Future<Response> _record(RequestContext context) async {
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  final uid = me['id'].toString();
  final body = await readJson(context);
  final betId = (body['betId'] as String?)?.trim();
  if (betId == null || betId.isEmpty) return fail('betId is required.');
  final source = (body['source'] as num?)?.toInt() ?? 0;
  final totalMeters = (body['totalMeters'] as num?)?.toInt() ?? 0;
  final totalSeconds = (body['totalSeconds'] as num?)?.toInt() ?? 0;
  final avgPace = (body['avgPace'] as num?)?.toInt() ?? 0;
  final qualifyingMeters = (body['qualifyingMeters'] as num?)?.toInt() ?? 0;
  final samples = body['samples'];

  try {
    final result = await db.runTx((tx) async {
      final pr = await tx.execute(
        Sql.named('''
          SELECT p.id AS pid, b.distance_km::float8 AS distance_km, b.status
          FROM participations p JOIN bets b ON b.id = p.bet_id
          WHERE p.bet_id = @bid:uuid AND p.user_id = @uid:uuid
        '''),
        parameters: {'bid': betId, 'uid': uid},
      );
      if (pr.isEmpty) throw HttpError('You are not in this bet.', status: 404);
      final p = pr.first.toColumnMap();
      if ((p['status'] as num).toInt() >= 2) {
        throw HttpError('This bet is closed.', status: 409);
      }
      final requiredMeters = ((p['distance_km'] as num).toDouble() * 1000).round();
      final verdict = qualifyingMeters >= requiredMeters ? 0 : 1;
      final pid = p['pid'].toString();

      final ins = await tx.execute(
        Sql.named('''
          INSERT INTO runs (participation_id, user_id, bet_id, source, total_meters,
            total_seconds, avg_pace, qualifying_meters, samples, verdict)
          VALUES (@pid:uuid, @uid:uuid, @bid:uuid, @src, @tm, @ts, @ap, @qm, @samples:jsonb, @verdict)
          RETURNING id, recorded_at
        '''),
        parameters: {
          'pid': pid, 'uid': uid, 'bid': betId, 'src': source,
          'tm': totalMeters, 'ts': totalSeconds, 'ap': avgPace, 'qm': qualifyingMeters,
          'samples': samples == null ? null : jsonEncode(samples), 'verdict': verdict,
        },
      );
      final row = ins.first.toColumnMap();
      return {
        'id': row['id'].toString(),
        'betId': betId,
        'verdict': verdict,
        'requiredMeters': requiredMeters,
        'qualifyingMeters': qualifyingMeters,
        'recordedAt': (row['recorded_at'] as DateTime).toUtc().toIso8601String(),
      };
    });
    return ok(result, status: 201);
  } on HttpError catch (e) {
    return fail(e.message, status: e.status);
  }
}
