import 'dart:convert';

import 'package:http/http.dart' as http;

/// The per-key, per-minute budget the API reports on every response.
class RateLimit {
  /// Creates a rate-limit snapshot.
  const RateLimit({this.limit, this.remaining, this.reset});

  /// Reads the `X-RateLimit-*` headers, if the response carried them.
  factory RateLimit.fromHeaders(Map<String, String> headers) {
    return RateLimit(
      limit: int.tryParse(headers['x-ratelimit-limit'] ?? ''),
      remaining: int.tryParse(headers['x-ratelimit-remaining'] ?? ''),
      reset: _resetAt(headers['x-ratelimit-reset']),
    );
  }

  /// Requests allowed in the window.
  final int? limit;

  /// Requests left in the current window.
  final int? remaining;

  /// When the window rolls over.
  final DateTime? reset;

  static DateTime? _resetAt(String? raw) {
    final seconds = int.tryParse(raw?.trim() ?? '');
    if (seconds == null) return null;
    // The API sends a unix timestamp; tolerate a delta from a proxy.
    if (seconds > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    }
    return DateTime.now().toUtc().add(Duration(seconds: seconds));
  }

  @override
  String toString() =>
      'RateLimit(limit: $limit, remaining: $remaining, reset: $reset)';
}

/// The base class for everything this SDK throws.
///
/// Every non-2xx response becomes one of the subclasses below. A request that
/// never reached the API becomes a [FoPostConnectionException].
class FoPostException implements Exception {
  /// Creates an exception. Prefer [FoPostException.fromResponse].
  FoPostException(
    this.message, {
    this.statusCode = 0,
    this.code,
    this.body,
    this.rateLimit,
  });

  /// Builds the exception matching [response]'s status.
  factory FoPostException.fromResponse(
    http.Response response,
    String decodedBody,
  ) {
    final status = response.statusCode;
    final body = _tryDecode(decodedBody);
    final envelope = body is Map<String, dynamic> ? body : const {};
    final code = envelope['error'] is String ? envelope['error'] as String : null;
    final message = envelope['message'] is String && (envelope['message'] as String).isNotEmpty
        ? envelope['message'] as String
        : (code ?? response.reasonPhrase ?? 'HTTP $status');
    final rateLimit = RateLimit.fromHeaders(response.headers);

    switch (status) {
      case 400:
      case 422:
        return FoPostValidationException(message,
            statusCode: status, code: code, body: body, rateLimit: rateLimit);
      case 401:
        return FoPostAuthenticationException(message,
            statusCode: status, code: code, body: body, rateLimit: rateLimit);
      case 402:
        return FoPostPaymentRequiredException(message,
            statusCode: status, code: code, body: body, rateLimit: rateLimit);
      case 403:
        return FoPostPermissionDeniedException(message,
            statusCode: status, code: code, body: body, rateLimit: rateLimit);
      case 404:
        return FoPostNotFoundException(message,
            statusCode: status, code: code, body: body, rateLimit: rateLimit);
      case 429:
        return FoPostRateLimitException(message,
            statusCode: status,
            code: code,
            body: body,
            rateLimit: rateLimit,
            retryAfter: parseRetryAfter(response.headers['retry-after']));
      default:
        if (status >= 500) {
          return FoPostServerException(message,
              statusCode: status, code: code, body: body, rateLimit: rateLimit);
        }
        return FoPostException(message,
            statusCode: status, code: code, body: body, rateLimit: rateLimit);
    }
  }

  /// The human-readable explanation the API sent.
  final String message;

  /// The HTTP status, or `0` when the request never got a response.
  final int statusCode;

  /// The machine-readable error code, e.g. `subscription_required`.
  final String? code;

  /// The decoded response body, for fields this type does not model.
  ///
  /// A JSON object arrives as a `Map<String, dynamic>`; anything else arrives
  /// as the raw text.
  final Object? body;

  /// The rate-limit headers that came with the response.
  final RateLimit? rateLimit;

  /// The body as a map, or an empty map when it was not a JSON object.
  Map<String, dynamic> get bodyMap =>
      body is Map<String, dynamic> ? body as Map<String, dynamic> : const {};

  @override
  String toString() {
    final label = code == null ? '$statusCode' : '$statusCode $code';
    return 'FoPost: $label: $message';
  }

  static Object? _tryDecode(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }
}

/// Reads `Retry-After` in either of its forms: delta-seconds or an HTTP date.
Duration? parseRetryAfter(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  final seconds = double.tryParse(value);
  if (seconds != null) {
    if (seconds <= 0) return Duration.zero;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  final target = _parseHttpDate(value);
  if (target == null) return null;
  final wait = target.difference(DateTime.now().toUtc());
  return wait.isNegative ? Duration.zero : wait;
}

DateTime? _parseHttpDate(String value) {
  // RFC 1123, e.g. "Wed, 21 Oct 2026 07:28:00 GMT".
  final match = RegExp(
    r'^\w{3},\s+(\d{2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s+GMT$',
  ).firstMatch(value);
  if (match == null) return null;
  const months = <String, int>{
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };
  final month = months[match.group(2)];
  if (month == null) return null;
  return DateTime.utc(
    int.parse(match.group(3)!),
    month,
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6)!),
  );
}

/// A `400` or `422` — the request body did not pass validation.
class FoPostValidationException extends FoPostException {
  /// Creates a validation error.
  FoPostValidationException(super.message,
      {super.statusCode, super.code, super.body, super.rateLimit});
}

/// A `401` — the API key is missing, invalid, or expired.
class FoPostAuthenticationException extends FoPostException {
  /// Creates an authentication error.
  FoPostAuthenticationException(super.message,
      {super.statusCode, super.code, super.body, super.rateLimit});
}

/// A `402` — no active subscription, or AI credits are exhausted.
class FoPostPaymentRequiredException extends FoPostException {
  /// Creates a payment-required error.
  FoPostPaymentRequiredException(super.message,
      {super.statusCode, super.code, super.body, super.rateLimit});

  /// Where to send the user to lift the block, when the API named one.
  String? get upgradeUrl {
    final value = bodyMap['upgrade_url'] ?? bodyMap['upgradeUrl'];
    return value is String ? value : null;
  }
}

/// A `403` — the key is valid but lacks the scope or workspace access.
class FoPostPermissionDeniedException extends FoPostException {
  /// Creates a permission error.
  FoPostPermissionDeniedException(super.message,
      {super.statusCode, super.code, super.body, super.rateLimit});
}

/// A `404` — no such resource, or it is outside the key's reach.
class FoPostNotFoundException extends FoPostException {
  /// Creates a not-found error.
  FoPostNotFoundException(super.message,
      {super.statusCode, super.code, super.body, super.rateLimit});
}

/// A `429` — over the plan's per-minute ceiling.
///
/// The client retries these on its own; the exception only surfaces once the
/// attempts are used up.
class FoPostRateLimitException extends FoPostException {
  /// Creates a rate-limit error.
  FoPostRateLimitException(super.message,
      {super.statusCode,
      super.code,
      super.body,
      super.rateLimit,
      this.retryAfter});

  /// The wait the API asked for, when it sent `Retry-After`.
  final Duration? retryAfter;
}

/// A `5xx` — the API failed to handle the request.
class FoPostServerException extends FoPostException {
  /// Creates a server error.
  FoPostServerException(super.message,
      {super.statusCode, super.code, super.body, super.rateLimit});
}

/// The request never reached the API: a socket error, a DNS failure, or the
/// per-request timeout running out.
class FoPostConnectionException extends FoPostException {
  /// Creates a transport error.
  FoPostConnectionException(super.message, {this.cause});

  /// The underlying error, when there was one.
  final Object? cause;

  @override
  String toString() => 'FoPost: $message';
}
