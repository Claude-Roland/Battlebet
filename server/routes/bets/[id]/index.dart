import 'package:dart_frog/dart_frog.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/bets.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return fail('Method not allowed', status: 405);
  }
  final me = await authed(context);
  final meId = me?['id']?.toString() ?? zeroUuid;
  final detail = await fetchBetDetail(id, meId);
  if (detail == null) return fail('Bet not found.', status: 404);
  return ok(detail);
}
