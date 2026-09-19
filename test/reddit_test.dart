import 'dart:convert';

import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('subreddits come back with the default and posting rights marked',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {
                'name': 'webdev',
                'title': 'Web Development',
                'subscribers': 2000000,
                'over18': false,
                'canPost': true,
                'flairEnabled': true,
                'iconUrl': null,
                'isDefault': true,
              }
            ]),
        recorder: seen);

    final subreddits = await client.accounts.redditSubreddits('acc_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/accounts/acc_1/reddit/subreddits');
    expect(subreddits.single.name, 'webdev');
    expect(subreddits.single.canPost, isTrue);
    expect(subreddits.single.isDefault, isTrue);
    client.close();
  });

  test('rules and flairs unwrap the subreddit envelope', () async {
    final seen = RecordedRequests();
    var calls = 0;
    final client = fakeClient((_) async {
      calls++;
      return calls == 1
          ? jsonOk({
              'subreddit': 'webdev',
              'rules': [
                {
                  'name': 'No self promotion',
                  'description': 'Keep it useful',
                  'appliesTo': 'link',
                }
              ],
            })
          : jsonOk({
              'subreddit': 'webdev',
              'flairs': [
                {'id': 'flair_1', 'text': 'Showoff Saturday', 'editable': false}
              ],
            });
    }, recorder: seen);

    final rules = await client.accounts.redditSubredditRules('acc_1', 'webdev');
    expect(seen.last.url.path,
        '/v1/accounts/acc_1/reddit/subreddits/webdev/rules');
    expect(rules.single.appliesTo, 'link');

    final flairs = await client.accounts.redditFlairs('acc_1', 'webdev');
    expect(seen.last.url.path, '/v1/accounts/acc_1/reddit/flairs');
    expect(seen.last.url.queryParameters['subreddit'], 'webdev');
    expect(flairs.single.id, 'flair_1');
    expect(flairs.single.editable, isFalse);
    client.close();
  });

  test('a null default subreddit is sent explicitly', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk({'subreddit': 'u_someone'}),
        recorder: seen);

    final now = await client.accounts.setRedditDefaultSubreddit('acc_1', null);

    expect(seen.last.method, 'PUT');
    expect(seen.last.url.path, '/v1/accounts/acc_1/reddit/default-subreddit');
    expect(jsonDecode(seen.last.body), {'subreddit': null});
    expect(now, 'u_someone');
    client.close();
  });

  test('a vote sends its direction and reads the vote back', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'id': 'item_1',
              'vote': 'down',
              'canVote': true,
              'liked': false,
            }),
        recorder: seen);

    final item = await client.inbox.vote('item_1', 'down');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/inbox/item_1/vote');
    expect(jsonDecode(seen.last.body), {'direction': 'down'});
    expect(item.vote, 'down');
    expect(item.canVote, isTrue);
    expect(item.liked, isFalse);
    client.close();
  });

  test('the subreddit check passes the account and name as query params',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'subreddit': 'webdev',
              'exists': true,
              'can_post': false,
              'over_18': false,
              'flair_enabled': true,
              'ok': false,
            }),
        recorder: seen);

    final result =
        await client.validate.subreddit(accountId: 'acc_1', name: 'webdev');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/validate/subreddit');
    expect(seen.last.url.queryParameters['account_id'], 'acc_1');
    expect(seen.last.url.queryParameters['name'], 'webdev');
    expect(result.exists, isTrue);
    expect(result.canPost, isFalse);
    expect(result.ok, isFalse);
    client.close();
  });
}
