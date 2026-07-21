import 'package:dart_frog/dart_frog.dart';

const _cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

/// Erlaubt der Web-App (anderer Port/Origin) den Zugriff und beantwortet
/// CORS-Preflight (OPTIONS) direkt.
Handler middleware(Handler handler) {
  return (context) async {
    if (context.request.method == HttpMethod.options) {
      return Response(statusCode: 204, headers: _cors);
    }
    final response = await handler(context);
    return response.copyWith(headers: {...response.headers, ..._cors});
  };
}
