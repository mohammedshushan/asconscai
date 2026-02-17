import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  final http.Client _inner;

  LoggingClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();
    final requestId = startTime.millisecondsSinceEpoch.toString().substring(7);

    developer.log(
      '🚀 [REQUEST] [$requestId] ${request.method} ${request.url}',
      name: 'Network',
    );

    if (request is http.Request && request.body.isNotEmpty) {
      _logData('📦 [PAYLOAD] [$requestId]', request.body);
    }

    try {
      final response = await _inner.send(request);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      final bytes = await response.stream.toBytes();
      final responseBody = utf8.decode(bytes);

      developer.log(
        '✅ [RESPONSE] [$requestId] ${response.statusCode} (${duration}ms) ${request.url}',
        name: 'Network',
      );

      _logData('📄 [RESPONSE BODY] [$requestId]', responseBody);

      return http.StreamedResponse(
        http.ByteStream.fromBytes(bytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      developer.log(
        '❌ [ERROR] [$requestId] ${request.url}\nError: $e',
        name: 'Network',
        error: e,
      );
      rethrow;
    }
  }

  void _logData(String label, String data) {
    try {
      final dynamic jsonObject = json.decode(data);
      final prettyString = const JsonEncoder.withIndent(
        '  ',
      ).convert(jsonObject);
      developer.log('$label\n$prettyString', name: 'Network');
    } catch (_) {
      developer.log('$label: $data', name: 'Network');
    }
  }
}
