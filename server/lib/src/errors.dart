/// Fehler mit HTTP-Status, den Handler in eine JSON-Fehlerantwort uebersetzen.
/// Innerhalb von db.runTx geworfen -> rollt die Transaktion zurueck.
class HttpError implements Exception {
  HttpError(this.message, {this.status = 400});
  final String message;
  final int status;
  @override
  String toString() => message;
}
