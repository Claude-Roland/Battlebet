import 'package:dart_frog/dart_frog.dart';

import 'package:battlebet_server/src/admin_page.dart';

/// Liefert die schlanke Personal-Oberflaeche (Admin) als HTML aus.
/// Lokal erreichbar unter GET /admin; in Produktion zusaetzlich am Root von
/// admin.battlebet.app (siehe routes/index.dart, Host-Weiche).
Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }
  return Response(
    body: adminHtml,
    headers: {'Content-Type': 'text/html; charset=utf-8'},
  );
}
