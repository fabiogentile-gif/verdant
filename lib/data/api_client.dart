import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:verdant/data/product_repository.dart';
import 'package:verdant/l10n/i18n.dart';

/// A failed API call, with a message fit for the UI.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.status,
    this.code,
    this.fields = const {},
  });

  final String message;

  /// HTTP status; null when the server could not be reached.
  final int? status;
  final String? code;

  /// Errors of single form fields, by field name.
  final Map<String, String> fields;

  bool get isNetwork => status == null;

  @override
  String toString() => 'ApiException($status, $code, $message)';
}

/// JSON client for the Verdant API. Adds the session token to every call.
class ApiClient {
  ApiClient({required this.origin, http.Client? client})
    : _client = client ?? http.Client();

  final String origin;
  final http.Client _client;
  static const _timeout = Duration(seconds: 12);

  String? token;

  /// Called when the server rejects the current session.
  void Function()? onSessionExpired;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body);
  Future<dynamic> put(String path, Object? body) => _send('PUT', path, body);
  Future<dynamic> patch(String path, Object? body) =>
      _send('PATCH', path, body);
  Future<dynamic> delete(String path, [Object? body]) =>
      _send('DELETE', path, body);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final sentWith = token;
    final request = http.Request(method, Uri.parse('$origin/api$path'));
    request.headers['Accept'] = 'application/json';
    if (sentWith != null) request.headers['Authorization'] = 'Bearer $sentWith';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      ).timeout(_timeout);
    } on TimeoutException {
      throw ApiException('The greenhouse is taking too long to answer.'.tr);
    } on http.ClientException {
      throw ApiException(
        'We can’t reach the greenhouse. Check your connection.'.tr,
      );
    }

    final Object? json = _decode(response.body);
    final map = json is Map ? json : const {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return map['data'];
    }
    if (response.statusCode == 401 && sentWith != null && sentWith == token) {
      onSessionExpired?.call();
    }
    final fields = map['fields'];
    throw ApiException(
      I18n.server(
        map['message'] as String? ?? 'Something went wrong on our side.',
      ),
      status: response.statusCode,
      code: map['code'] as String?,
      fields: fields is Map
          ? {
              for (final e in fields.entries)
                '${e.key}': I18n.server('${e.value}'),
            }
          : const {},
    );
  }

  static Object? _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}

/// The API client shared by the app; non-final so tests can swap in a fake.
ApiClient api = ApiClient(origin: apiOrigin);
