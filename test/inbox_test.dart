import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

Map<String, dynamic> itemJson({String state = InboxItemState.unread}) => {
      'id': 'in_1',
      'workspaceId': 'ws_1',
      'platform': 'facebook',
      'type': 'comment',
      'state': state,
      'direction': 'inbound',
      'authorName': 'Ada Example',
      'authorHandle': 'ada',
      'text': 'Love this',
      'attachments': [
        {
          'kind': 'image',
          'url': 'https://api.fopost.com/v1/inbox/in_1/attachments/0'
        }
      ],
      'postExternalId': 'fb_post_9',
      'platformCreatedAt': '2026-09-18T09:00:00.000Z',
      'createdAt': '2026-09-18T09:01:00.000Z',
      'canReply': true,
      'hidden': false,
      'postContext': {'externalId': 'fb_post_9', 'isOwn': true},
      'account': {
        'id': 'acc_1',
        'platform': 'facebook',
        'username': 'yourbrand'
      },
    };

void main() {
  test('list sends the snake_case filters and reads the camelCase page',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonBare({
        'data': [itemJson()],
        'meta': {'page': 2, 'perPage': 25, 'total': 60},
      }),
      recorder: seen,
    );

    final page = await client.inbox.list(
      workspaceId: 'ws_1',
      type: InboxItemType.comment,
      state: InboxItemState.unread,
      postExternalId: 'fb_post_9',
      sort: InboxSort.unanswered,
      page: 2,
      perPage: 25,
    );

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/inbox');
    expect(seen.last.url.queryParameters, {
      'workspace_id': 'ws_1',
      'type': 'comment',
      'state': 'unread',
      'post_external_id': 'fb_post_9',
      'sort': 'unanswered',
      'page': '2',
      'per_page': '25',
    });

    expect(page.meta.currentPage, 2);
    expect(page.meta.perPage, 25);
    expect(page.meta.total, 60);
    expect(page.meta.lastPage, 3);
    expect(page.meta.hasMore, isTrue);

    final item = page.data.single;
    expect(item.id, 'in_1');
    expect(item.type, InboxItemType.comment);
    expect(item.authorHandle, 'ada');
    expect(item.attachments.single.kind, 'image');
    expect(item.platformCreatedAt, DateTime.utc(2026, 9, 18, 9));
    expect(item.postContext?.isOwn, isTrue);
    expect(item.account?.username, 'yourbrand');
    client.close();
  });

  test('threads and conversations hit their own paths', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => jsonBare({
        'data': [
          if (request.url.path.endsWith('/posts'))
            {
              'accountId': 'acc_1',
              'postExternalId': 'fb_post_9',
              'commentCount': 4,
              'unreadCount': 1,
              'post': {'externalId': 'fb_post_9', 'text': 'Launch day'},
            }
          else
            {
              'accountId': 'acc_1',
              'conversationId': 'conv_1',
              'messageCount': 3,
              'lastMessageOutbound': false,
              'participant': {'name': 'Ada Example', 'handle': 'ada'},
            }
        ],
        'meta': {'page': 1, 'perPage': 25, 'total': 1},
      }),
      recorder: seen,
    );

    final threads =
        await client.inbox.threads(workspaceId: 'ws_1', kind: 'mentions');
    expect(seen.last.url.path, '/v1/inbox/posts');
    expect(seen.last.url.queryParameters['kind'], 'mentions');
    expect(threads.data.single.commentCount, 4);
    expect(threads.data.single.post?.text, 'Launch day');

    final conversations = await client.inbox.conversations(workspaceId: 'ws_1');
    expect(seen.last.url.path, '/v1/inbox/conversations');
    expect(conversations.data.single.conversationId, 'conv_1');
    expect(conversations.data.single.participant?.handle, 'ada');
    expect(conversations.meta.hasMore, isFalse);
    client.close();
  });

  test('unreadCount reads the bare count', () async {
    final client = fakeClient((_) async => jsonBare({'count': 7}));
    expect(await client.inbox.unreadCount(workspaceId: 'ws_1'), 7);
    client.close();
  });

  test('markThreadRead posts a snake_case body and returns the count',
      () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonOk({'updated': 3}), recorder: seen);

    final updated = await client.inbox.markThreadRead(
      workspaceId: 'ws_1',
      accountId: 'acc_1',
      postExternalId: 'fb_post_9',
    );

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/inbox/read');
    expect(jsonDecode(seen.last.body), {
      'workspace_id': 'ws_1',
      'account_id': 'acc_1',
      'post_external_id': 'fb_post_9',
    });
    expect(updated, 3);
    client.close();
  });

  test('refresh reads the poll summary', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonOk({
        'accountsPolled': 2,
        'newItems': 5,
        'rateLimited': 0,
        'dmReconnect': [
          {'platform': 'instagram', 'account': 'yourbrand'}
        ],
      }),
      recorder: seen,
    );

    final result = await client.inbox.refresh(workspaceId: 'ws_1');
    expect(seen.last.url.path, '/v1/inbox/refresh');
    expect(jsonDecode(seen.last.body), {'workspace_id': 'ws_1'});
    expect(result.newItems, 5);
    expect(result.dmReconnect.single.platform, 'instagram');
    client.close();
  });

  test('update patches state in camelCase', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk(itemJson(state: InboxItemState.snoozed)),
        recorder: seen);

    final item = await client.inbox.update(
      'in_1',
      state: InboxItemState.snoozed,
      snoozedUntil: DateTime.utc(2026, 9, 20, 8),
    );

    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/inbox/in_1');
    expect(jsonDecode(seen.last.body), {
      'state': 'snoozed',
      'snoozedUntil': '2026-09-20T08:00:00.000Z',
    });
    expect(item.state, InboxItemState.snoozed);
    client.close();
  });

  test('reply sends the text and reads where it landed', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonOk({
        'item': itemJson(state: InboxItemState.read),
        'reply': {
          'externalId': 'fb_c_2',
          'externalUrl': 'https://yourbrand.com/r'
        },
      }),
      recorder: seen,
    );

    final result = await client.inbox.reply('in_1', 'Thanks!');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/inbox/in_1/reply');
    expect(jsonDecode(seen.last.body), {'text': 'Thanks!'});
    expect(result.item.state, InboxItemState.read);
    expect(result.reply.externalId, 'fb_c_2');
    client.close();
  });

  test('hide, unhide and delete address the item', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => request.method == 'DELETE'
          ? jsonOk({'deleted': true})
          : jsonOk(itemJson()),
      recorder: seen,
    );

    await client.inbox.hide('in_1');
    expect(seen.last.url.path, '/v1/inbox/in_1/hide');
    await client.inbox.unhide('in_1');
    expect(seen.last.url.path, '/v1/inbox/in_1/unhide');
    await client.inbox.delete('in_1');
    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/inbox/in_1');
    client.close();
  });

  test('approvals list, approve with replacement text, and reject', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => request.method == 'GET'
          ? jsonOk([
              {
                'id': 12,
                'workspaceId': 'ws_1',
                'source': 'agent',
                'reply': 'Glad you like it',
                'createdAt': '2026-09-18T10:00:00.000Z',
              }
            ])
          : jsonOk({
              'id': 12,
              'outcome': request.url.path.endsWith('/approve')
                  ? 'approved'
                  : 'rejected',
            }),
      recorder: seen,
    );

    final approvals = await client.inbox.listApprovals(workspaceId: 'ws_1');
    expect(seen.last.url.path, '/v1/inbox/approvals');
    expect(approvals.single.id, 12);
    expect(approvals.single.reply, 'Glad you like it');

    final approved = await client.inbox.approveReply(12, text: 'Thank you');
    expect(seen.last.url.path, '/v1/inbox/approvals/12/approve');
    expect(jsonDecode(seen.last.body), {'text': 'Thank you'});
    expect(approved.outcome, 'approved');

    final rejected = await client.inbox.rejectReply(12);
    expect(seen.last.url.path, '/v1/inbox/approvals/12/reject');
    expect(seen.last.body, isEmpty);
    expect(rejected.outcome, 'rejected');
    client.close();
  });

  test('accounts and platforms read their flags', () async {
    final client = fakeClient(
      (request) async => request.url.path.endsWith('/accounts')
          ? jsonOk([
              {
                'id': 'acc_1',
                'platform': 'instagram',
                'username': 'yourbrand',
                'name': 'Your Brand',
                'inboxSupported': true,
                'dmSupported': false,
                'dmPendingReason': 'approval_pending',
                'canStartConversation': true,
              }
            ])
          : jsonOk([
              {'platform': 'instagram', 'comments': 'live', 'dms': 'soon'}
            ]),
    );

    final accounts = await client.inbox.accounts(workspaceId: 'ws_1');
    expect(accounts.single.inboxSupported, isTrue);
    expect(accounts.single.dmSupported, isFalse);
    expect(accounts.single.dmPendingReason, 'approval_pending');
    expect(accounts.single.canStartConversation, isTrue);

    final platforms = await client.inbox.platforms();
    expect(platforms.single.comments, 'live');
    expect(platforms.single.dms, 'soon');
    client.close();
  });

  test('like, pin, react and editComment read the action fields', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => jsonOk({
        ...itemJson(),
        'liked': true,
        'pinned': true,
        'reaction': null,
        'editedAt': '2026-09-18T12:00:00.000Z',
        'canLike': true,
        'canPin': true,
        'canEdit': true,
        'canReact': false,
        'canSendMedia': false,
        'canQuickReply': false,
        'canPrivateReply': true,
      }),
      recorder: seen,
    );

    final liked = await client.inbox.like('in_1');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/inbox/in_1/like');
    expect(liked.liked, isTrue);
    expect(liked.canPrivateReply, isTrue);
    expect(liked.canSendMedia, isFalse);

    await client.inbox.unlike('in_1');
    expect(seen.last.url.path, '/v1/inbox/in_1/unlike');
    final pinned = await client.inbox.pin('in_1');
    expect(seen.last.url.path, '/v1/inbox/in_1/pin');
    expect(pinned.pinned, isTrue);
    await client.inbox.unpin('in_1');
    expect(seen.last.url.path, '/v1/inbox/in_1/unpin');

    final reacted = await client.inbox.react('in_1', null);
    expect(seen.last.url.path, '/v1/inbox/in_1/react');
    expect(jsonDecode(seen.last.body), {'reaction': null});
    expect(reacted.reaction, isNull);

    final edited = await client.inbox.editComment('in_1', 'Fixed typo');
    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/inbox/in_1');
    expect(jsonDecode(seen.last.body), {'text': 'Fixed typo'});
    expect(edited.editedAt, DateTime.utc(2026, 9, 18, 12));
    client.close();
  });

  test('reply sends media ids and quick replies without text', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (_) async => jsonOk({
        'item': itemJson(),
        'reply': {'externalId': 'm_1'},
      }),
      recorder: seen,
    );

    await client.inbox
        .reply('in_1', null, mediaIds: ['med_1'], quickReplies: ['Yes', 'No']);
    expect(jsonDecode(seen.last.body), {
      'media_ids': ['med_1'],
      'quick_replies': ['Yes', 'No'],
    });
    client.close();
  });

  test('startConversation and setTyping post snake_case bodies', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
      (request) async => request.url.path.endsWith('/typing')
          ? jsonOk({'typing': false})
          : jsonBare({
              'data': {
                'conversationId': 'conv_9',
                'item': {...itemJson(), 'type': 'dm', 'direction': 'outbound'},
              },
            }, status: 201),
      recorder: seen,
    );

    final started = await client.inbox
        .startConversation(text: 'Thanks for the comment!', commentId: 'in_1');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/inbox/conversations');
    expect(jsonDecode(seen.last.body),
        {'comment_id': 'in_1', 'text': 'Thanks for the comment!'});
    expect(started.conversationId, 'conv_9');
    expect(started.item?.direction, 'outbound');

    final typing =
        await client.inbox.setTyping('conv_9', accountId: 'acc_1', on: false);
    expect(seen.last.url.path, '/v1/inbox/conversations/conv_9/typing');
    expect(jsonDecode(seen.last.body), {'account_id': 'acc_1', 'on': false});
    expect(typing, isFalse);
    client.close();
  });
}
