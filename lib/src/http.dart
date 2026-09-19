import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'errors.dart';
import 'file.dart';
import 'json.dart';

/// The transport every resource sits on. Internal: reach it through
/// `FoPost.request` instead.
@internal
class FoPostHttp {
  /// Wires the transport. [FoPost] does this for you.
  FoPostHttp({
    required this.apiKey,
    required this.baseUrl,
    required http.Client httpClient,
    required this.ownsClient,
    required this.timeout,
    required this.maxRetries,
    required this.userAgent,
    required this.retryBaseDelay,
  }) : _client = httpClient;

  /// The longest the client waits between attempts.
  static const Duration maxRetryDelay = Duration(seconds: 60);

  /// The key sent as `X-API-Key`.
  final String apiKey;

  /// The API root, including its version prefix, with no trailing slash.
  final String baseUrl;

  /// Whether [close] should also close the underlying client.
  final bool ownsClient;

  /// The ceiling on a single attempt.
  final Duration timeout;

  /// Total attempts, so 3 means two retries.
  final int maxRetries;

  /// The `User-Agent` every request carries.
  final String userAgent;

  /// The first backoff step; doubles on each further attempt.
  final Duration retryBaseDelay;

  final http.Client _client;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'X-API-Key': apiKey,
        'User-Agent': userAgent,
      };

  Uri _uri(String path, Map<String, dynamic>? query) {
    final uri = Uri.parse('$baseUrl/${path.replaceFirst(RegExp('^/+'), '')}');
    final params = queryOf(query);
    if (params.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...params});
  }

  /// Sends a request and returns the decoded body exactly as it came.
  Future<dynamic> raw(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) {
    final uri = _uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);
    return _run(() {
      final request = http.Request(method.toUpperCase(), uri)
        ..headers.addAll(_headers);
      if (encoded != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = encoded;
      }
      return request;
    }, unwrap: false);
  }

  /// Sends a request and peels the `{"data": ...}` envelope off the response.
  Future<dynamic> json(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) {
    final uri = _uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);
    return _run(() {
      final request = http.Request(method.toUpperCase(), uri)
        ..headers.addAll(_headers);
      if (encoded != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = encoded;
      }
      return request;
    }, unwrap: true);
  }

  /// Sends a `multipart/form-data` upload, unwrapping the response envelope.
  Future<dynamic> multipart(
    String path, {
    required Map<String, String> fields,
    required List<FoPostFile> files,
    String fileField = 'files',
    Map<String, dynamic>? query,
  }) {
    final uri = _uri(path, query);
    return _run(() {
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers);
      fields.forEach((key, value) {
        if (value.isNotEmpty) request.fields[key] = value;
      });
      for (final file in files) {
        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          file.bytes,
          filename: file.filename.isEmpty ? 'upload' : file.filename,
        ));
      }
      return request;
    }, unwrap: true);
  }

  /// Unwrapped response as an object.
  Future<Map<String, dynamic>> object(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async =>
      asMap(await json(method, path, body: body, query: query));

  /// Unwrapped response as a list of objects.
  Future<List<Map<String, dynamic>>> objects(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final decoded = await json(method, path, body: body, query: query);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Sends a request whose response body is not needed.
  Future<void> discard(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    await raw(method, path, body: body, query: query);
  }

  /// Sends raw bytes to a presigned URL with exactly [headers].
  ///
  /// The URL carries its own authorisation, so no API key, `Accept` or
  /// `User-Agent` is attached. A non-2xx answer throws the matching
  /// [FoPostException].
  Future<void> putBytes(
    Uri url,
    Uint8List bytes, {
    required Map<String, String> headers,
  }) async {
    http.Response response;
    try {
      final request = http.Request('PUT', url)
        ..headers.addAll(headers)
        ..bodyBytes = bytes;
      response = await _once(request).timeout(timeout);
    } on Exception catch (error) {
      throw FoPostConnectionException(
        'the upload to ${url.host} did not complete: $error',
        cause: error,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw FoPostException.fromResponse(response, _text(response));
  }

  /// Releases the underlying client, when this transport owns it.
  void close() {
    if (ownsClient) _client.close();
  }

  Future<dynamic> _run(
    http.BaseRequest Function() build, {
    required bool unwrap,
  }) async {
    for (var attempt = 1;; attempt++) {
      http.Response response;
      try {
        response = await _once(build()).timeout(timeout);
      } on Exception catch (error) {
        if (attempt >= maxRetries) {
          throw FoPostConnectionException(
            'the request to $baseUrl did not complete: $error',
            cause: error,
          );
        }
        await Future<void>.delayed(_backoff(attempt));
        continue;
      }

      final text = _text(response);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decode(response.statusCode, text, unwrap: unwrap);
      }

      final failure = FoPostException.fromResponse(response, text);
      if (attempt >= maxRetries || !_retryable(response.statusCode)) {
        throw failure;
      }

      var wait = _backoff(attempt);
      if (failure is FoPostRateLimitException && failure.retryAfter != null) {
        final asked = failure.retryAfter!;
        wait = asked > maxRetryDelay ? maxRetryDelay : asked;
      }
      await Future<void>.delayed(wait);
    }
  }

  Future<http.Response> _once(http.BaseRequest request) async =>
      http.Response.fromStream(await _client.send(request));

  // The API answers JSON without a charset, and http defaults those to latin1.
  String _text(http.Response response) =>
      utf8.decode(response.bodyBytes, allowMalformed: true);

  dynamic _decode(int status, String text, {required bool unwrap}) {
    if (status == 204 || text.trim().isEmpty) return null;
    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      return text;
    }
    if (unwrap &&
        decoded is Map<String, dynamic> &&
        decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  bool _retryable(int status) => status == 429 || status >= 500;

  Duration _backoff(int attempt) {
    final millis = retryBaseDelay.inMilliseconds * math.pow(2, attempt - 1);
    final capped =
        math.min(millis.toDouble(), maxRetryDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: capped.round());
  }
}
