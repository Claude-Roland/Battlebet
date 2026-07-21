import 'package:postgres/postgres.dart';

/// Loest einen Pot auf: zahlt die noch aktiven Teilnehmer (Durchhalter) aus
/// (Einsatz + Anteil am Aussteiger-Geld − Gebuehr), verbucht die Gebuehr ans Haus,
/// markiert die Wette als resolved. Setzt voraus, dass die Wochen-Checkpoints schon
/// gelaufen sind (state=0 = wirklich durchgehalten). Innerhalb einer Transaktion.
Future<Map<String, dynamic>> resolveBet(TxSession tx, String betId) async {
  final br = await tx.execute(
    Sql.named('SELECT stake_minor, fee_bps, currency, status FROM bets WHERE id = @id:uuid'),
    parameters: {'id': betId},
  );
  if (br.isEmpty) return {'betId': betId, 'skipped': 'not found'};
  final bet = br.first.toColumnMap();
  if ((bet['status'] as num).toInt() >= 2) {
    return {'betId': betId, 'skipped': 'already resolved'};
  }
  final stakeMinor = (bet['stake_minor'] as num).toInt();
  final feeBps = (bet['fee_bps'] as num).toInt();
  final currency = (bet['currency'] as String).trim();

  final parts = await tx.execute(
    Sql.named('SELECT user_id, state FROM participations WHERE bet_id = @id:uuid'),
    parameters: {'id': betId},
  );
  final rows = parts.map((r) => r.toColumnMap()).toList();
  final starters = rows.length;
  final dropouts = rows.where((r) => (r['state'] as num).toInt() == 1).length;
  final finishers = rows.where((r) => (r['state'] as num).toInt() == 0).toList();
  final forfeited = stakeMinor * dropouts;
  final fee = (forfeited * feeBps / 10000).round();
  final surplus = forfeited - fee;
  final perFinisher = finishers.isEmpty ? 0 : surplus ~/ finishers.length;
  final payout = stakeMinor + perFinisher;

  for (final fr in finishers) {
    final fuid = fr['user_id'].toString();
    final w = await tx.execute(
      Sql.named('''
        UPDATE wallets SET balance_minor = balance_minor + @amt, updated_at = now()
        WHERE user_id = @uid:uuid AND currency = @cur
        RETURNING balance_minor
      '''),
      parameters: {'amt': payout, 'uid': fuid, 'cur': currency},
    );
    final bal = w.isEmpty ? 0 : (w.first.toColumnMap()['balance_minor'] as num).toInt();
    await tx.execute(
      Sql.named('''
        INSERT INTO ledger (user_id, kind, amount_minor, currency,
          balance_after_minor, bet_id, note)
        VALUES (@uid:uuid, 3, @amt, @cur, @bal, @id:uuid, 'payout (finisher)')
      '''),
      parameters: {'uid': fuid, 'amt': payout, 'cur': currency, 'bal': bal, 'id': betId},
    );
    await tx.execute(
      Sql.named('''
        UPDATE participations SET state = 2, settled = true
        WHERE bet_id = @id:uuid AND user_id = @uid:uuid
      '''),
      parameters: {'id': betId, 'uid': fuid},
    );
  }
  await tx.execute(
    Sql.named('UPDATE participations SET settled = true WHERE bet_id = @id:uuid AND state = 1'),
    parameters: {'id': betId},
  );
  if (fee > 0) {
    await tx.execute(
      Sql.named('''
        INSERT INTO ledger (user_id, kind, amount_minor, currency,
          balance_after_minor, bet_id, note)
        SELECT id, 5, @fee, @cur, 0, @id:uuid, 'platform fee'
        FROM users WHERE username_lc = 'battlebet'
      '''),
      parameters: {'fee': fee, 'cur': currency, 'id': betId},
    );
  }
  await tx.execute(
    Sql.named('UPDATE bets SET status = 2, resolved_at = now() WHERE id = @id:uuid'),
    parameters: {'id': betId},
  );
  return {
    'betId': betId,
    'starters': starters,
    'dropouts': dropouts,
    'finishers': finishers.length,
    'stakeMinor': stakeMinor,
    'forfeitedMinor': forfeited,
    'feeMinor': fee,
    'payoutPerFinisherMinor': payout,
    'currency': currency,
  };
}
