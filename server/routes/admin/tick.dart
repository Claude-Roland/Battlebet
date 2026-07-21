import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/db.dart';

/// Zeit-Uebergaenge (Produktion: Cron; Test: manuell mit X-Admin-Token).
/// Schliesst faellige Anmeldefenster: >= Mindestteilnehmer -> Start (running),
/// sonst Absage (cancelled) + Rueckzahlung aller Einsaetze.
/// (Wochen-Checkpoint + Auto-Aufloesung folgen im naechsten Schritt.)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final token = context.request.headers['x-admin-token'];
  final expected = Platform.environment['ADMIN_TOKEN'] ?? 'dev-tick';
  if (token != expected) return fail('Forbidden.', status: 403);

  final due = await db.execute(
    'SELECT id FROM bets '
    'WHERE status = 0 AND entry_closes_at IS NOT NULL AND entry_closes_at <= now()',
  );
  final started = <String>[];
  final cancelled = <String>[];

  for (final row in due) {
    final betId = row.toColumnMap()['id'].toString();
    final outcome = await db.runTx((tx) async {
      final cntRes = await tx.execute(
        Sql.named('''
          SELECT count(*) FILTER (WHERE state = 0)::int AS active,
                 (SELECT min_participants FROM bets WHERE id = @id:uuid) AS minp
          FROM participations WHERE bet_id = @id:uuid
        '''),
        parameters: {'id': betId},
      );
      final m = cntRes.first.toColumnMap();
      final active = (m['active'] as num).toInt();
      final minp = (m['minp'] as num).toInt();
      if (active >= minp) {
        await tx.execute(
          Sql.named('UPDATE bets SET status = 1 WHERE id = @id:uuid'),
          parameters: {'id': betId},
        );
        return 'started';
      }
      final parts = await tx.execute(
        Sql.named('''
          SELECT user_id, stake_minor, currency FROM participations
          WHERE bet_id = @id:uuid AND state = 0
        '''),
        parameters: {'id': betId},
      );
      for (final p in parts) {
        final pm = p.toColumnMap();
        final puid = pm['user_id'].toString();
        final stake = (pm['stake_minor'] as num).toInt();
        final cur = (pm['currency'] as String).trim();
        final w = await tx.execute(
          Sql.named('''
            UPDATE wallets SET balance_minor = balance_minor + @amt, updated_at = now()
            WHERE user_id = @uid:uuid AND currency = @cur
            RETURNING balance_minor
          '''),
          parameters: {'amt': stake, 'uid': puid, 'cur': cur},
        );
        final bal = w.isEmpty ? 0 : (w.first.toColumnMap()['balance_minor'] as num).toInt();
        await tx.execute(
          Sql.named('''
            INSERT INTO ledger (user_id, kind, amount_minor, currency,
              balance_after_minor, bet_id, note)
            VALUES (@uid:uuid, 6, @amt, @cur, @bal, @id:uuid, 'refund (under minimum)')
          '''),
          parameters: {'uid': puid, 'amt': stake, 'cur': cur, 'bal': bal, 'id': betId},
        );
      }
      await tx.execute(
        Sql.named('UPDATE participations SET settled = true WHERE bet_id = @id:uuid'),
        parameters: {'id': betId},
      );
      await tx.execute(
        Sql.named('UPDATE bets SET status = 3, resolved_at = now() WHERE id = @id:uuid'),
        parameters: {'id': betId},
      );
      return 'cancelled';
    });
    (outcome == 'started' ? started : cancelled).add(betId);
  }

  return ok({'started': started, 'cancelled': cancelled});
}
