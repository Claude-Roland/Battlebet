import 'package:dart_frog/dart_frog.dart';

import 'package:battlebet_server/src/api.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return fail('Method not allowed', status: 405);
  }
  final me = await authed(context);
  if (me == null) return fail('Not authenticated.', status: 401);
  return ok(profileJson(me));
}
