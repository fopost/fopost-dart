import 'dart:async';

import 'package:fopost/fopost.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('retries', () {
    test('retries a 429 and returns the eventual success', () async {
      var calls = 0;
      final client = fakeClient((_) async {
        calls++;
        if (calls == 1) {
          return jsonError(429, 'rate_limited', 'Slow down',
              headers: {'retry-after': '0'});
        }
        return jsonOk([]);
      });

      await client.workspaces.list();

      expect(calls, 2);
      client.close();
    });

    test('waits the interval Retry-After asks for', () async {
      var calls = 0;
      final started = DateTime.now();
      final client = fakeClient((_) async {
        calls++;
        if (calls == 1) {
          return jsonError(429, 'rate_limited', 'Slow down',
              headers: {'retry-after': '0.25'});
        }
        return jsonOk([]);
      });

      await client.workspaces.list();

      // retryBaseDelay is zero in tests, so any wait here came from the header.
      expect(DateTime.now().difference(started).inMilliseconds,
          greaterThanOrEqualTo(200));
      expect(calls, 2);
      client.close();
    });

    test('retries a 500 up to the attempt ceiling', () async {
      var calls = 0;
      final client = fakeClient((_) async {
        calls++;
        if (calls < 3) return jsonError(500, 'internal_error', 'Boom');
        return jsonOk([]);
      });

      await client.workspaces.list();

      expect(calls, 3);
      client.close();
    });

    test('gives up once the attempts are used and throws the last error',
        () async {
      var calls = 0;
      final client = fakeClient((_) async {
        calls++;
        return jsonError(503, 'unavailable', 'Down for maintenance');
      });

      await expectLater(
        client.workspaces.list(),
        throwsA(isA<FoPostServerException>()
            .having((e) => e.statusCode, 'statusCode', 503)),
      );
      expect(calls, 3);
      client.close();
    });

    test('never retries a 400 — the request is the problem', () async {
      var calls = 0;
      final client = fakeClient((_) async {
        calls++;
        return jsonError(400, 'invalid_request', 'content is required');
      });

      await expectLater(
        client.workspaces.list(),
        throwsA(isA<FoPostValidationException>()),
      );
      expect(calls, 1);
      client.close();
    });

    test('never retries a 404', () async {
      var calls = 0;
      final client = fakeClient((_) async {
        calls++;
        return jsonError(404, 'not_found', 'No such post');
      });

      await expectLater(
        client.posts.get('p_missing'),
        throwsA(isA<FoPostNotFoundException>()),
      );
      expect(calls, 1);
      client.close();
    });

    test('retries a transport error, then surfaces it as a connection error',
        () async {
      var calls = 0;
      final client = fakeClient((_) async {
        calls++;
        throw http.ClientException('connection reset');
      });

      await expectLater(
        client.workspaces.list(),
        throwsA(isA<FoPostConnectionException>()
            .having((e) => e.statusCode, 'statusCode', 0)),
      );
      expect(calls, 3);
      client.close();
    });

    test('recovers when a transport error clears on a later attempt', () async {
      var calls = 0;
      final client = fakeClient((_) async {
        calls++;
        if (calls == 1) throw http.ClientException('connection reset');
        return jsonOk([]);
      });

      await client.workspaces.list();

      expect(calls, 2);
      client.close();
    });

    test('maxRetries: 1 disables retrying', () async {
      var calls = 0;
      final client = fakeClient(
        (_) async {
          calls++;
          return jsonError(500, 'internal_error', 'Boom');
        },
        maxRetries: 1,
      );

      await expectLater(
          client.workspaces.list(), throwsA(isA<FoPostServerException>()));
      expect(calls, 1);
      client.close();
    });

    test('a request that outruns the timeout is a connection error', () async {
      final client = FoPost(
        apiKey: 'fp_test_key',
        maxRetries: 1,
        timeout: const Duration(milliseconds: 40),
        retryBaseDelay: Duration.zero,
        httpClient: _SlowClient(),
      );

      await expectLater(
        client.workspaces.list(),
        throwsA(isA<FoPostConnectionException>()),
      );
      client.close();
    });
  });
}

class _SlowClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await Future<void>.delayed(const Duration(seconds: 5));
    return http.StreamedResponse(const Stream.empty(), 200);
  }
}
