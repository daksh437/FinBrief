import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// Standard failure codes surfaced in the `error` field of an API response.
/// Callers can compare against these instead of matching on message strings.
class ApiError {
  ApiError._();

  static const timeout = 'REQUEST_TIMEOUT';
  static const network = 'NETWORK_UNAVAILABLE';
  static const server = 'SERVER_ERROR';
}

// Single source of truth for talking to the backend — every other service
// (news, ai, watchlist, billing) goes through here so the base URL, auth
// header, timeouts and error handling only need to change in one place.
//
// Every method returns a decoded map and never throws for network/timeout
// failures: on failure it returns {success: false, error: <ApiError code>,
// message: <friendly text>}. Existing callers already branch on
// `success != true`, so they degrade gracefully without any changes.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<Map<String, String>> _headers({String? idempotencyKey}) async {
    final token = await AuthService.instance.idToken;
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    if (idempotencyKey != null) headers['X-Idempotency-Key'] = idempotencyKey;
    return headers;
  }

  /// Runs a request with a timeout and converts transport-level failures into
  /// the standard error map rather than letting them escape as exceptions.
  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    try {
      final res = await request().timeout(_timeout);
      return _decode(res);
    } on TimeoutException {
      return {
        'success': false,
        'error': ApiError.timeout,
        'message': 'The server took too long to respond. Please try again.',
      };
    } on SocketException {
      return {
        'success': false,
        'error': ApiError.network,
        'message': 'Can\'t reach the server. Check your connection and try again.',
      };
    } on http.ClientException {
      return {
        'success': false,
        'error': ApiError.network,
        'message': 'Can\'t reach the server. Check your connection and try again.',
      };
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final headers = await _headers();
    return _send(() => http.get(_uri(path, query), headers: headers));
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final headers = await _headers(idempotencyKey: idempotencyKey);
    return _send(() => http.post(_uri(path), headers: headers, body: jsonEncode(body ?? {})));
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final headers = await _headers();
    return _send(() => http.patch(_uri(path), headers: headers, body: jsonEncode(body ?? {})));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _headers();
    return _send(() => http.delete(_uri(path), headers: headers));
  }

  Map<String, dynamic> _decode(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'error': ApiError.server, 'message': 'Unexpected response from server.'};
    } catch (_) {
      // Non-JSON response (e.g. an HTML error page from an outdated/misrouted
      // backend, or a network gateway error) — surface as a normal API
      // failure instead of letting an uncaught FormatException crash the app.
      return {
        'success': false,
        'error': ApiError.server,
        'message': 'Server error (HTTP ${res.statusCode}). Please try again.',
      };
    }
  }
}
