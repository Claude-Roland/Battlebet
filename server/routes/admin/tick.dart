import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import 'package:battlebet_server/src/api.dart';
import 'package:battlebet_server/src/ticker.dart';

/// Zeit-Uebergaenge (Produktion: Cron; Test: manuell mit X-Admin-Token):
/// Anmeldefenster schliessen, Wochen-Checkpoints, faellige Wetten aufloesen.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return fail('Method not allowed', status: 405);
  }
  final token = context.request.headers['x-admin-token'];
  final expected = Platform.environment['ADMIN_TOKEN'] ?? 'dev-tick';
  if (token != expected) return fail('Forbidden.', status: 403);
  return ok(await runTicker());
}
