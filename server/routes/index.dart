import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
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
      ],
    },
  );
}
