import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Every request the mock client saw, in order.
class RecordedRequests {
  final List<http.Request> all = [];

  http.Request get last => all.last;

  int get length => all.length;
}

/// Builds a client whose transport is a fake, so tests never leave the process.
FoPost fakeClient(
  Future<http.Response> Function(http.Request request) handler, {
  RecordedRequests? recorder,
  String apiKey = 'fp_test_key',
  String baseUrl = 'https://api.fopost.com/v1',
  int maxRetries = 3,
  String? userAgent,
}) {
  return FoPost(
    apiKey: apiKey,
    baseUrl: baseUrl,
    maxRetries: maxRetries,
    userAgent: userAgent,
    // Keeps the retry tests instant; the production default is 500ms.
    retryBaseDelay: Duration.zero,
    httpClient: MockClient((request) async {
      recorder?.all.add(request);
      return handler(request);
    }),
  );
}

/// A `200` carrying the `{"data": ...}` envelope most endpoints answer with.
http.Response jsonOk(Object? data, {Map<String, String> headers = const {}}) =>
    http.Response(
      jsonEncode({'data': data}),
      200,
      headers: {'content-type': 'application/json', ...headers},
    );

/// A bare `200`, for the endpoints that answer without an envelope.
http.Response jsonBare(Object? body, {int status = 200, Map<String, String> headers = const {}}) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json', ...headers},
    );

/// A non-2xx carrying the `{"error": ..., "message": ...}` envelope.
http.Response jsonError(
  int status,
  String code,
  String message, {
  Map<String, Object?> extra = const {},
  Map<String, String> headers = const {},
}) =>
    http.Response(
      jsonEncode({'error': code, 'message': message, ...extra}),
      status,
      headers: {'content-type': 'application/json', ...headers},
    );
