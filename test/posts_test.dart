import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> postJson({
  String id = 'p_1',
  String status = PostStatus.draft,
  String text = 'Hello from Dart',
}) =>
    {
      'id': id,
      'workspace_id': 'ws_1',
      'status': status,
      'content_type': 'post',
      'content': [
        {'text': text, 'media': <Object>[]}
      ],
      'accounts': [
        {
          'id': 'acc_1',
          'platform': 'bluesky',
          'username': 'yourbrand',
          'publish_status': DeliveryStatus.pending,
        }
      ],
      'labels': <Object>[],
      'created_at': '2026-08-30T10:00:00.000Z',
    };

void main() {
  group('create', () {
    test('creates a single-block post from a string', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(postJson()), recorder: seen);

      final post = await client.posts.create(
        workspaceId: 'ws_1',
        accounts: ['acc_1'],
        content: 'Hello from Dart',
      );

      expect(seen.last.method, 'POST');
      expect(seen.last.url.path, '/v1/posts');
      expect(jsonDecode(seen.last.body), {
        'workspace_id': 'ws_1',
        'accounts': ['acc_1'],
        'content': [
          {'text': 'Hello from Dart'}
        ],
      });

      expect(post.id, 'p_1');
      expect(post.status, PostStatus.draft);
      expect(post.text, 'Hello from Dart');
      expect(post.accounts.single.platform, 'bluesky');
      expect(post.createdAt, DateTime.utc(2026, 8, 30, 10));
      client.close();
    });

    test('targets an account group without an accounts list', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(postJson()), recorder: seen);

      await client.posts.create(
        workspaceId: 'ws_1',
        accountGroupId: 'grp_1',
        content: 'Hello from Dart',
      );

      expect(jsonDecode(seen.last.body), {
        'workspace_id': 'ws_1',
        'account_group_id': 'grp_1',
        'content': [
          {'text': 'Hello from Dart'}
        ],
      });
      client.close();
    });

    test('creates a thread from a list of blocks, media and all', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(postJson()), recorder: seen);

      await client.posts.create(
        workspaceId: 'ws_1',
        accounts: ['acc_1'],
        content: [
          'First in the thread',
          const ContentBlock(
            text: 'Second, with an image',
            media: [
              MediaItem(
                type: 'image',
                name: 'chart.png',
                url: 'https://cdn.example.com/chart.png',
              ),
            ],
          ),
        ],
      );

      final body = jsonDecode(seen.last.body) as Map<String, dynamic>;
      expect(body['content'], [
        {'text': 'First in the thread'},
        {
          'text': 'Second, with an image',
          'media': [
            {
              'type': 'image',
              'name': 'chart.png',
              'url': 'https://cdn.example.com/chart.png',
            }
          ],
        },
      ]);
      client.close();
    });

    test('sends a scheduled post as ISO 8601 UTC', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonOk(postJson(status: PostStatus.scheduled)),
        recorder: seen,
      );

      await client.posts.create(
        workspaceId: 'ws_1',
        accounts: ['acc_1'],
        content: 'Scheduled with the SDK',
        status: PostStatus.scheduled,
        scheduleAt: DateTime.utc(2026, 9, 1, 10),
      );

      final body = jsonDecode(seen.last.body) as Map<String, dynamic>;
      expect(body['status'], 'scheduled');
      expect(body['schedule_at'], '2026-09-01T10:00:00.000Z');
      client.close();
    });

    test('rejects content that is not text or blocks', () {
      final client = fakeClient((_) async => jsonOk(postJson()));
      expect(
        () => client.posts.create(
          workspaceId: 'ws_1',
          accounts: ['acc_1'],
          content: 42,
        ),
        throwsArgumentError,
      );
      client.close();
    });
  });

  group('publish', () {
    test('queues delivery and reads back the per-account records', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonOk({
          'post': {'id': 'p_1', 'status': 'publishing'},
          'post_status': 'publishing',
          'deliveries': [
            {'id': 'd_1', 'accountId': 'acc_1', 'status': 'queued'}
          ],
          'healthWarnings': [
            {
              'accountId': 'acc_2',
              'platform': 'linkedin',
              'healthStatus': 'degraded',
              'message': 'Token expires soon',
            }
          ],
        }),
        recorder: seen,
      );

      final result = await client.posts.publish('p_1');

      expect(seen.last.url.path, '/v1/posts/p_1/publish');
      expect(result.dryRun, isFalse);
      expect(result.postStatus, 'publishing');
      expect(result.deliveries.single.status, DeliveryStatus.queued);
      expect(result.healthWarnings.single.platform, 'linkedin');
      client.close();
    });

    test('a dry run asks for one and reaches no platform', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonOk({
          'dryRun': true,
          'accounts': [
            {'accountId': 'acc_1', 'platform': 'bluesky'}
          ],
        }),
        recorder: seen,
      );

      final result = await client.posts
          .publish('p_1', accountIds: ['acc_1'], dryRun: true);

      expect(jsonDecode(seen.last.body), {
        'accountIds': ['acc_1'],
        'options': {'dryRun': true},
      });
      expect(result.dryRun, isTrue);
      expect(result.deliveries, isEmpty);
      expect(result.accounts.single.platform, 'bluesky');
      client.close();
    });
  });

  group('pagination', () {
    test('decodes the snake_case meta block', () async {
      final client = fakeClient((_) async => jsonBare({
            'data': [postJson(), postJson(id: 'p_2')],
            'meta': {
              'current_page': 2,
              'per_page': 30,
              'total': 61,
              'last_page': 3,
              'from': 31,
              'to': 60,
            },
          }));

      final page = await client.posts.list(page: 2);

      expect(page.length, 2);
      expect(page.data.last.id, 'p_2');
      expect(page.meta.currentPage, 2);
      expect(page.meta.perPage, 30);
      expect(page.meta.total, 61);
      expect(page.meta.lastPage, 3);
      expect(page.meta.from, 31);
      expect(page.meta.to, 60);
      expect(page.meta.hasMore, isTrue);
      client.close();
    });

    test('stream walks every page and stops at the last one', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (request) async {
          final page = int.parse(request.url.queryParameters['page']!);
          return jsonBare({
            'data': [postJson(id: 'p_$page')],
            'meta': {
              'current_page': page,
              'per_page': 1,
              'total': 3,
              'last_page': 3
            },
          });
        },
        recorder: seen,
      );

      final ids =
          await client.posts.stream(perPage: 1).map((p) => p.id).toList();

      expect(ids, ['p_1', 'p_2', 'p_3']);
      expect(seen.length, 3);
      client.close();
    });

    test('stream stops on a short page when the API sends no last_page',
        () async {
      var calls = 0;
      final client = fakeClient((_) async {
        calls++;
        return jsonBare({
          'data': [postJson()],
          'meta': <String, Object>{},
        });
      });

      final ids =
          await client.posts.stream(perPage: 30).map((p) => p.id).toList();

      expect(ids, ['p_1']);
      expect(calls, 1);
      client.close();
    });
  });

  test('preflight reports blockers and advisory signals', () async {
    final client = fakeClient((_) async => jsonOk({
          'ready': false,
          'post': {'id': 'p_1', 'status': 'draft'},
          'accounts': [
            {
              'accountId': 'acc_1',
              'platform': 'bluesky',
              'ready': false,
              'issues': ['content exceeds the platform limit'],
              'score': 42.5,
              'signals': [
                {'level': 'warn', 'code': 'no_media', 'message': 'Add an image'}
              ],
            }
          ],
        }));

    final result = await client.posts.preflight('p_1');

    expect(result.ready, isFalse);
    expect(result.accounts.single.issues, hasLength(1));
    expect(result.accounts.single.signals.single.code, 'no_media');
    expect(result.accounts.single.score, 42.5);
    client.close();
  });
}
