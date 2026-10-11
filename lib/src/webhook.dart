import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'errors.dart';
import 'json.dart';

/// The header carrying the HMAC-SHA256 of the raw body.
const String webhookSignatureHeader = 'x-fopost-signature';

/// The header carrying the HMAC-SHA256 of `<timestamp>.<raw body>`.
const String webhookTimestampedSignatureHeader = 'x-fopost-signature-256';

/// The header carrying the unix-seconds timestamp the delivery was signed at.
const String webhookTimestampHeader = 'x-fopost-timestamp';

/// The header naming the event.
const String webhookEventHeader = 'x-fopost-event';

/// The header carrying the delivery id.
const String webhookDeliveryHeader = 'x-fopost-delivery';

/// How far a delivery's timestamp may sit from the receiver's clock.
const Duration webhookSignatureTolerance = Duration(seconds: 300);

/// A delivery whose signature did not check out.
class FoPostWebhookSignatureException extends FoPostException {
  /// Creates a signature error.
  FoPostWebhookSignatureException(super.message)
      : super(code: 'invalid_signature');

  @override
  String toString() => 'FoPost: $message';
}

/// The envelope every FoPost webhook delivers.
class WebhookEnvelope {
  /// Creates an envelope.
  const WebhookEnvelope({
    required this.event,
    required this.data,
    this.timestamp,
    this.deliveryId,
  });

  /// The event name, e.g. `article.published`.
  final String event;

  /// The event-specific body. Read an `article.published` one with
  /// `BlogArticlePublished.fromJson(envelope.data)`.
  final Map<String, dynamic> data;

  /// When the event happened.
  final DateTime? timestamp;

  /// The `X-FoPost-Delivery` value, when the header was present.
  final String? deliveryId;

  @override
  String toString() => 'WebhookEnvelope($event)';
}

/// Checks a webhook delivery's signature and returns its envelope.
///
/// [rawBody] is the request body exactly as received: the bytes, or the body
/// as a string before anything parsed it. Re-serialised JSON will not verify.
/// [headers] are the request headers; names are matched without regard to
/// case. [secret] is the webhook's signing secret, or the blog's website
/// secret for the website target.
///
/// The timestamped signature (`X-FoPost-Signature-256`) is preferred and is
/// refused when the timestamp sits more than [tolerance] from now. Only a
/// delivery with no timestamp header at all falls back to the plain body
/// signature (`X-FoPost-Signature`).
///
/// Throws [FoPostWebhookSignatureException] when the delivery does not check
/// out, and [FormatException] when a verified body is not a JSON object.
///
/// ```dart
/// final envelope = verifyWebhook(
///   rawBody: request.bodyBytes,
///   headers: request.headers,
///   secret: secret,
/// );
/// if (envelope.event == 'article.published') {
///   final article = BlogArticlePublished.fromJson(envelope.data);
/// }
/// ```
WebhookEnvelope verifyWebhook({
  required Object rawBody,
  required Map<String, String> headers,
  required String secret,
  Duration tolerance = webhookSignatureTolerance,
  DateTime? now,
}) {
  if (secret.isEmpty) {
    throw FoPostWebhookSignatureException('a webhook secret is required');
  }
  final bytes = _bytes(rawBody);
  final lower = <String, String>{
    for (final entry in headers.entries) entry.key.toLowerCase(): entry.value,
  };
  final key = utf8.encode(secret);

  final timestamp = lower[webhookTimestampHeader]?.trim();
  if (timestamp != null) {
    final seconds = int.tryParse(timestamp);
    if (seconds == null) {
      throw FoPostWebhookSignatureException(
          'the timestamp header is not a number');
    }
    final at = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    final skew = (now ?? DateTime.now()).toUtc().difference(at).abs();
    if (skew > tolerance) {
      throw FoPostWebhookSignatureException(
          'the delivery timestamp is outside the tolerance');
    }
    final signed = <int>[...utf8.encode('$timestamp.'), ...bytes];
    _check(lower[webhookTimestampedSignatureHeader], key, signed);
  } else {
    _check(lower[webhookSignatureHeader], key, bytes);
  }

  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map) {
    throw const FormatException('the webhook body is not a JSON object');
  }
  final body = Map<String, dynamic>.from(decoded);
  return WebhookEnvelope(
    event: asString(body['event']) ?? lower[webhookEventHeader] ?? '',
    data: asMap(body['data']),
    timestamp: asDate(body['timestamp']),
    deliveryId: lower[webhookDeliveryHeader],
  );
}

List<int> _bytes(Object rawBody) {
  if (rawBody is List<int>) return rawBody;
  if (rawBody is String) return utf8.encode(rawBody);
  throw ArgumentError.value(rawBody, 'rawBody', 'expected bytes or a String');
}

void _check(String? header, List<int> key, List<int> message) {
  final presented = header?.trim();
  if (presented == null || presented.isEmpty) {
    throw FoPostWebhookSignatureException('the signature header is missing');
  }
  final hex =
      presented.startsWith('sha256=') ? presented.substring(7) : presented;
  final expected = Hmac(sha256, key).convert(message).toString();
  if (!_constantTimeEquals(hex.toLowerCase(), expected)) {
    throw FoPostWebhookSignatureException('the signature does not match');
  }
}

/// Compares every byte regardless of where the first difference is, so timing
/// does not reveal how much of a guess was right. The length is not a secret.
bool _constantTimeEquals(String a, String b) {
  final left = utf8.encode(a);
  final right = utf8.encode(b);
  if (left.length != right.length) return false;
  var diff = 0;
  for (var i = 0; i < left.length; i++) {
    diff |= left[i] ^ right[i];
  }
  return diff == 0;
}
