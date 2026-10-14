import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

const secret = 'whsec_test_secret';

final body = jsonEncode({
  'event': 'article.published',
  'data': {
    'id': 'art_1',
    'title': 'Hello',
    'slug': 'hello',
    'bodyMarkdown': '# Hello',
    'bodyHtml': '<h1>Hello</h1>',
    'featuredImage': {'mediaId': 'med_1', 'url': 'https://x/y.jpg', 'alt': 'a'},
    'images': <Object>[],
    'tags': ['news'],
    'keyword': null,
    'wordCount': 1,
    'publishedAt': '2026-10-11T09:00:00.000Z',
    'publishedUrl': 'https://yourbrand.com/blog/hello',
  },
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
    'X-FoPost-Event': 'article.published',
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

    expect(envelope.event, 'article.published');
    expect(envelope.deliveryId, 'dlv_1');
    expect(envelope.timestamp, DateTime.utc(2026, 10, 11, 9));
    final article = BlogArticlePublished.fromJson(envelope.data);
    expect(article.slug, 'hello');
    expect(article.featuredImage?.mediaId, 'med_1');
    expect(article.publishedUrl, 'https://yourbrand.com/blog/hello');
  });

  test('a tampered body fails', () {
    final tampered = body.replaceFirst('hello', 'hacked');

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
    expect(envelope.event, 'article.published');

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
