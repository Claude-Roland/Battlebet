import 'package:postgres/postgres.dart';

/// Hoechste Zahl gleichzeitig aktiver Wetten je Nutzer (Ueberlappungs-Deckel).
/// Begrenzt, dass ein Trainingspensum viele Poette zugleich bedient. Nachjustierbar.
const int kMaxOverlappingBets = 3;

/// Zaehlt, in wie vielen laufenden/anmeldenden Wetten der Nutzer aktiver
/// Teilnehmer ist (Status gathering=0 oder running=1, Teilnahme aktiv=0).
Future<int> activeParticipationCount(TxSession tx, String userId) async {
  final res = await tx.execute(
    Sql.named('''
      SELECT count(*)::int AS n
      FROM participations p JOIN bets b ON b.id = p.bet_id
      WHERE p.user_id = @uid:uuid AND p.state = 0 AND b.status IN (0, 1)
    '''),
    parameters: {'uid': userId},
  );
  return (res.first.toColumnMap()['n'] as num).toInt();
}
