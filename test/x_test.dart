import 'dart:convert';

import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('follow and unfollow post the user id and read the result', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (request) async => jsonBare({
              'account_id': 'acc_1',
              'user_id': '2244994945',
              'following': request.url.path.endsWith('/follow'),
            }),
        recorder: seen);

    final followed =
        await client.accounts.followXUser('acc_1', userId: '2244994945');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/accounts/acc_1/x/follow');
    expect(jsonDecode(seen.last.body), {'user_id': '2244994945'});
    expect(followed.accountId, 'acc_1');
    expect(followed.userId, '2244994945');
    expect(followed.following, isTrue);

    final unfollowed =
        await client.accounts.unfollowXUser('acc_1', userId: '2244994945');
    expect(seen.last.url.path, '/v1/accounts/acc_1/x/unfollow');
    expect(jsonDecode(seen.last.body), {'user_id': '2244994945'});
    expect(unfollowed.following, isFalse);
    client.close();
  });

  test('post lookup sends the account and reads the post', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'id': '1700000000000000000',
              'text': 'Hello from X',
              'permalink': 'https://x.com/yourbrand/status/1700000000000000000',
              'author_name': 'Your Brand',
              'author_handle': 'yourbrand',
              'author_avatar_url': null,
              'author_followers': 1200,
              'conversation_id': '1700000000000000000',
              'parent_external_id': null,
              'likes': 4,
              'replies': 1,
              'reposts': 2,
              'quotes': 0,
              'platform_created_at': '2026-10-18T09:00:00.000Z',
            }),
        recorder: seen);

    final post = await client.accounts
        .getXPost('1700000000000000000', accountId: 'acc_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/x/posts/1700000000000000000');
    expect(seen.last.url.queryParameters['account_id'], 'acc_1');
    expect(post.id, '1700000000000000000');
    expect(post.authorHandle, 'yourbrand');
    expect(post.authorFollowers, 1200);
    expect(post.reposts, 2);
    expect(post.parentExternalId, isNull);
    expect(post.platformCreatedAt, DateTime.utc(2026, 10, 18, 9));
    client.close();
  });

  test('search passes the query through and reads the cursor', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              'data': [
                {'id': '1', 'text': 'first'},
                {'id': '2', 'text': 'second'},
              ],
              'meta': {'next_token': 'b26v89c19zqg8o3fpdx'},
            }),
        recorder: seen);

    final page = await client.accounts.searchXPosts(
      'fopost -is:retweet',
      accountId: 'acc_1',
      maxResults: 50,
      nextToken: 'prev',
    );

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/x/search');
    expect(seen.last.url.queryParameters, {
      'q': 'fopost -is:retweet',
      'account_id': 'acc_1',
      'max_results': '50',
      'next_token': 'prev',
    });
    expect(page.posts.map((p) => p.id), ['1', '2']);
    expect(page.nextToken, 'b26v89c19zqg8o3fpdx');
    expect(page.hasMore, isTrue);
    client.close();
  });

  test('search omits unset paging and reports the last page', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonBare({
              'data': <Object>[],
              'meta': {'next_token': null},
            }),
        recorder: seen);

    final page =
        await client.accounts.searchXPosts('fopost', accountId: 'acc_1');

    expect(seen.last.url.queryParameters.keys, ['q', 'account_id']);
    expect(page.posts, isEmpty);
    expect(page.hasMore, isFalse);
    client.close();
  });
}
