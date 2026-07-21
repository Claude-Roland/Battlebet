import 'package:dart_frog/dart_frog.dart';

import 'package:battlebet_server/src/admin_page.dart';

Response onRequest(RequestContext context) {
  // Auf admin.battlebet.app die Personal-Oberflaeche am Root ausliefern;
  // auf battlebet.app (und lokal) wie bisher das Service-JSON.
  final host = context.request.headers['host'] ?? '';
  if (host.startsWith('admin.')) {
    return Response(
      body: adminHtml,
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    );
  }
  return Response.json(
    body: {
      'service': 'battlebet_server',
      'status': 'ok',
      'endpoints': [
        'POST /auth/register',
        'POST /auth/login',
        'GET /me',
        'POST /me/display-name',
        'POST /wallet/deposit',
        'POST /wallet/withdraw',
        'GET /admin',
        'POST /admin/bets',
      ],
    },
  );
}
