import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

const secret = 'whsec_test_secret';

final body = jsonEncode({
  'event': 'post.published',
  'data': {'id': 'post_1', 'status': 'published'},
  'timestamp': '2026-10-11T09:00:00.000Z',
});

String hmac(String message) =>
    'sha256=${Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(message))}';

final now = DateTime.utc(2026, 10, 11, 9, 0, 30);
final int sentAt = now.millisecondsSinceEpoch ~/ 1000 - 10;

Map<String, String> timestampedHeaders({int? at, String? body_}) {
  final stamp = at ?? sentAt;
  final raw = body_ ?? body;
  return {
    'X-FoPost-Event': 'post.published',
    'X-FoPost-Delivery': 'dlv_1',
    'X-FoPost-Timestamp': '$stamp',
    'X-FoPost-Signature-256': hmac('$stamp.$raw'),
    'X-FoPost-Signature': hmac(raw),
  };
}

void main() {
  test('a valid timestamped signature passes and yields the envelope', () {
    final envelope = verifyWebhook(
      rawBody: utf8.encode(body),
      headers: timestampedHeaders(),
      secret: secret,
      now: now,
    );

    expect(envelope.event, 'post.published');
    expect(envelope.deliveryId, 'dlv_1');
    expect(envelope.timestamp, DateTime.utc(2026, 10, 11, 9));
    expect(envelope.data['id'], 'post_1');
    expect(envelope.data['status'], 'published');
  });

  test('a tampered body fails', () {
    final tampered = body.replaceFirst('post_1', 'post_2');

    expect(
      () => verifyWebhook(
        rawBody: tampered,
        headers: timestampedHeaders(),
        secret: secret,
        now: now,
      ),
      throwsA(isA<FoPostWebhookSignatureException>()),
    );
  });

  test('a stale timestamp fails even with a matching signature', () {
    final stale = sentAt - 301;

    expect(
      () => verifyWebhook(
        rawBody: body,
        headers: timestampedHeaders(at: stale),
        secret: secret,
        now: now,
      ),
      throwsA(isA<FoPostWebhookSignatureException>()),
    );
  });

  test('the plain body signature is used only with no timestamp header', () {
    final envelope = verifyWebhook(
      rawBody: body,
      headers: {'x-fopost-signature': hmac(body)},
      secret: secret,
      now: now,
    );
    expect(envelope.event, 'post.published');

    // With a timestamp present the legacy header alone is not enough.
    expect(
      () => verifyWebhook(
        rawBody: body,
        headers: {
          'X-FoPost-Timestamp': '$sentAt',
          'X-FoPost-Signature': hmac(body),
        },
        secret: secret,
        now: now,
      ),
      throwsA(isA<FoPostWebhookSignatureException>()),
    );
  });
}
