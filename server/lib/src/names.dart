// Auto-Namen fuer von NUTZERN angelegte Wetten (Roland 2026-07-21).
//
// Themen-Schema nach Sportart:
//   Rennen  (running,  sport 1) -> Vogel  + Zahl   (fliegen = am schnellsten)
//   Wandern (hiking,   sport 5) -> Berg   + Zahl   (erklimmen)
//   Joggen  (jogging,  sport 0) -> Saeugetier + Zahl
//   (alle anderen Sportarten fallen auf Saeugetier zurueck; im MVP nicht anlegbar)
//
// Namen englisch (UI-Basis Englisch), Einzelwoerter fuer sauberes "Wort Zahl".
// Die Zahl ist im Gamer-Tag-Stil zufaellig; die Eindeutigkeit wird gegen die
// bets-Tabelle geprueft (bei Kollision neu gewuerfelt). Kuratierte/Admin-Wetten
// bekommen KEINEN Auto-Namen, sondern behalten ihren Sondernamen.

import 'dart:math';

import 'package:postgres/postgres.dart';

const _birds = <String>[
  'Falcon', 'Eagle', 'Hawk', 'Osprey', 'Kestrel', 'Merlin', 'Harrier', 'Condor',
  'Vulture', 'Owl', 'Raven', 'Magpie', 'Jay', 'Robin', 'Sparrow', 'Finch',
  'Wren', 'Lark', 'Swallow', 'Swift', 'Starling', 'Thrush', 'Kingfisher',
  'Heron', 'Egret', 'Crane', 'Stork', 'Ibis', 'Flamingo', 'Pelican',
  'Albatross', 'Gull', 'Tern', 'Puffin', 'Petrel', 'Gannet', 'Swan', 'Mallard',
  'Grouse', 'Pheasant', 'Quail', 'Woodpecker', 'Kite', 'Buzzard', 'Peregrine',
  'Goshawk',
];

const _mountains = <String>[
  'Matterhorn', 'Everest', 'Eiger', 'Denali', 'Kilimanjaro', 'Fuji', 'Rainier',
  'Elbrus', 'Aconcagua', 'Olympus', 'Etna', 'Vesuvius', 'Snowdon', 'Zugspitze',
  'Jungfrau', 'Watzmann', 'Grossglockner', 'Ortler', 'Shasta', 'Whitney',
  'Logan', 'Vinson', 'Teide', 'Ararat', 'Damavand', 'Kazbek', 'Triglav',
  'Makalu', 'Lhotse', 'Annapurna', 'Manaslu', 'Dhaulagiri', 'Nevis', 'Cervino',
  'Hood', 'Baker', 'Adams', 'Aoraki', 'Kosciuszko', 'Toubkal', 'Kenya', 'Meru',
];

const _mammals = <String>[
  'Wolf', 'Fox', 'Bear', 'Lion', 'Tiger', 'Panther', 'Leopard', 'Cheetah',
  'Jaguar', 'Cougar', 'Lynx', 'Bison', 'Moose', 'Elk', 'Stag', 'Ibex',
  'Gazelle', 'Antelope', 'Impala', 'Oryx', 'Boar', 'Otter', 'Badger',
  'Wolverine', 'Hare', 'Stallion', 'Mustang', 'Bronco', 'Buffalo', 'Rhino',
  'Panda', 'Lemur', 'Gibbon', 'Baboon', 'Orca', 'Dolphin', 'Seal', 'Narwhal',
  'Kangaroo', 'Dingo', 'Coyote', 'Jackal', 'Meerkat', 'Marmot', 'Chamois',
  'Kudu', 'Springbok',
];

List<String> _poolForSport(int sport) => switch (sport) {
      1 => _birds, // running
      5 => _mountains, // hiking / wandern
      _ => _mammals, // jogging (0) + Rueckfall fuer alle anderen
    };

final Random _rng = Random();

/// Erzeugt einen eindeutigen Auto-Namen ("Falcon 274") fuer eine Nutzer-Wette.
/// Prueft die bets-Tabelle in DERSELBEN Transaktion und wuerfelt bei Kollision
/// neu. Fallback nach vielen Versuchen: groessere Zahl fuer mehr Entropie.
Future<String> generateBetName(TxSession tx, int sport) async {
  final pool = _poolForSport(sport);
  for (var attempt = 0; attempt < 40; attempt++) {
    final word = pool[_rng.nextInt(pool.length)];
    final number = 1 + _rng.nextInt(999);
    final candidate = '$word $number';
    final hit = await tx.execute(
      Sql.named('SELECT 1 FROM bets WHERE name = @n LIMIT 1'),
      parameters: {'n': candidate},
    );
    if (hit.isEmpty) return candidate;
  }
  final word = pool[_rng.nextInt(pool.length)];
  return '$word ${1000 + _rng.nextInt(9000)}';
}
