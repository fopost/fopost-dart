import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('post sends the draft and reads each platform verdict', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'ready': false,
              'platforms': [
                {
                  'platform': 'twitter',
                  'ready': false,
                  'issues': ['Text exceeds the limit'],
                  'score': 42,
                  'signals': [
                    {
                      'level': 'warn',
                      'code': 'over_length',
                      'message': 'Too long'
                    }
                  ],
                },
                {'platform': 'linkedin', 'ready': true, 'issues': []},
              ],
            }),
        recorder: seen);

    final result = await client.validate.post(
      content: 'Hello',
      media: const [
        ValidateMedia(
            url: 'https://cdn.example.com/a.png',
            mimeType: 'image/png',
            size: 1024),
      ],
      platforms: ['twitter', 'linkedin'],
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/validate/post');
    expect(jsonDecode(seen.last.body), {
      'content': 'Hello',
      'media': [
        {
          'url': 'https://cdn.example.com/a.png',
          'mime_type': 'image/png',
          'size': 1024
        }
      ],
      'platforms': ['twitter', 'linkedin'],
    });
    expect(result.ready, isFalse);
    expect(result.platforms, hasLength(2));
    expect(result.platforms.first.platform, 'twitter');
    expect(result.platforms.first.issues, ['Text exceeds the limit']);
    expect(result.platforms.first.score, 42);
    expect(result.platforms.first.signals.single.code, 'over_length');
    expect(result.platforms.last.ready, isTrue);
    expect(result.platforms.last.score, isNull);
    client.close();
  });

  test('length sends the text and reads each platform count', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'ok': true,
              'platforms': [
                {
                  'platform': 'twitter',
                  'length': 5,
                  'limit': 280,
                  'unit': 'chars',
                  'ok': true,
                  'signals': [],
                },
                {
                  'platform': 'linkedin',
                  'length': 5,
                  'limit': null,
                  'unit': 'chars',
                  'ok': true,
                },
              ],
            }),
        recorder: seen);

    final result = await client.validate
        .length(text: 'Hello', platforms: ['twitter', 'linkedin']);

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/validate/length');
    expect(jsonDecode(seen.last.body), {
      'text': 'Hello',
      'platforms': ['twitter', 'linkedin'],
    });
    expect(result.ok, isTrue);
    expect(result.platforms.first.length, 5);
    expect(result.platforms.first.limit, 280);
    expect(result.platforms.first.unit, 'chars');
    expect(result.platforms.last.limit, isNull);
    client.close();
  });

  test('media sends the url and reads the verdict', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'ok': false,
              'issues': ['File is too large'],
              'name': 'big.mp4',
              'size': 90000000,
            }),
        recorder: seen);

    final result =
        await client.validate.media(url: 'https://cdn.example.com/big.mp4');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/validate/media');
    expect(
        jsonDecode(seen.last.body), {'url': 'https://cdn.example.com/big.mp4'});
    expect(result.ok, isFalse);
    expect(result.issues, ['File is too large']);
    expect(result.name, 'big.mp4');
    expect(result.size, 90000000);
    expect(result.mimeType, isNull);
    expect(result.type, isNull);
    client.close();
  });
}
