import 'package:fopost/fopost.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('status mapping', () {
    final cases = <int, Type>{
      400: FoPostValidationException,
      422: FoPostValidationException,
      401: FoPostAuthenticationException,
      402: FoPostPaymentRequiredException,
      403: FoPostPermissionDeniedException,
      404: FoPostNotFoundException,
      429: FoPostRateLimitException,
      500: FoPostServerException,
      503: FoPostServerException,
    };

    cases.forEach((status, type) {
      test('$status becomes $type', () async {
        final client = fakeClient(
          (_) async => jsonError(status, 'some_code', 'something happened'),
          maxRetries: 1,
        );

        await expectLater(
          client.workspaces.list(),
          throwsA(predicate<FoPostException>(
            (e) => e.runtimeType == type && e.statusCode == status,
          )),
        );
        client.close();
      });
    });

    test('an unmapped 4xx stays on the base class', () async {
      final client = fakeClient(
        (_) async => jsonError(409, 'conflict', 'already published'),
        maxRetries: 1,
      );

      await expectLater(
        client.workspaces.list(),
        throwsA(predicate<FoPostException>(
          (e) => e.runtimeType == FoPostException && e.statusCode == 409,
        )),
      );
      client.close();
    });
  });

  group('error detail', () {
    test('carries the code, message and raw body', () async {
      final client = fakeClient(
        (_) async => jsonError(403, 'subscription_required', 'No active plan',
            extra: {'scope': 'posts'}),
        maxRetries: 1,
      );

      try {
        await client.workspaces.list();
        fail('expected a permission error');
      } on FoPostPermissionDeniedException catch (error) {
        expect(error.code, 'subscription_required');
        expect(error.message, 'No active plan');
        expect(error.bodyMap['scope'], 'posts');
        expect(error.toString(), contains('subscription_required'));
      }
      client.close();
    });

    test('a 402 exposes the upgrade URL', () async {
      final client = fakeClient(
        (_) async => jsonError(402, 'subscription_required', 'Upgrade to publish',
            extra: {'upgrade_url': 'https://app.fopost.com/settings/billing'}),
        maxRetries: 1,
      );

      try {
        await client.posts.publish('p_1');
        fail('expected a payment error');
      } on FoPostPaymentRequiredException catch (error) {
        expect(error.upgradeUrl, 'https://app.fopost.com/settings/billing');
      }
      client.close();
    });

    test('a 429 exposes the wait the API asked for', () async {
      final client = fakeClient(
        (_) async => jsonError(429, 'rate_limited', 'Slow down',
            headers: {'retry-after': '30'}),
        maxRetries: 1,
      );

      try {
        await client.workspaces.list();
        fail('expected a rate limit error');
      } on FoPostRateLimitException catch (error) {
        expect(error.retryAfter, const Duration(seconds: 30));
      }
      client.close();
    });

    test('surfaces the rate limit headers that came with the response',
        () async {
      final client = fakeClient(
        (_) async => jsonError(403, 'forbidden', 'nope', headers: {
          'x-ratelimit-limit': '100',
          'x-ratelimit-remaining': '0',
        }),
        maxRetries: 1,
      );

      try {
        await client.workspaces.list();
        fail('expected an error');
      } on FoPostException catch (error) {
        expect(error.rateLimit?.limit, 100);
        expect(error.rateLimit?.remaining, 0);
      }
      client.close();
    });

    test('falls back to the status when the body is not the usual envelope',
        () async {
      final client = fakeClient(
        (_) async => http.Response('<html>bad gateway</html>', 502),
        maxRetries: 1,
      );

      try {
        await client.workspaces.list();
        fail('expected a server error');
      } on FoPostServerException catch (error) {
        expect(error.code, isNull);
        expect(error.body, contains('bad gateway'));
        expect(error.message, isNotEmpty);
      }
      client.close();
    });
  });

  group('parseRetryAfter', () {
    test('reads delta-seconds', () {
      expect(parseRetryAfter('120'), const Duration(seconds: 120));
    });

    test('reads an HTTP date', () {
      final target = DateTime.now().toUtc().add(const Duration(seconds: 60));
      final header = _httpDate(target);
      final wait = parseRetryAfter(header);
      expect(wait, isNotNull);
      expect(wait!.inSeconds, inInclusiveRange(55, 61));
    });

    test('is null when the header is absent or unreadable', () {
      expect(parseRetryAfter(null), isNull);
      expect(parseRetryAfter('  '), isNull);
      expect(parseRetryAfter('soon'), isNull);
    });

    test('never asks for a wait in the past', () {
      expect(parseRetryAfter('-5'), Duration.zero);
    });
  });
}

String _httpDate(DateTime utc) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String two(int value) => value.toString().padLeft(2, '0');
  return '${days[utc.weekday - 1]}, ${two(utc.day)} ${months[utc.month - 1]} '
      '${utc.year} ${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} GMT';
}
