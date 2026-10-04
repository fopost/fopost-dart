import 'dart:convert';

import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('creating a pinterest board omits the optionals it was not given',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async =>
            jsonOk({'id': 'b1', 'name': 'Recipes', 'privacy': 'PUBLIC'}),
        recorder: seen);

    final board =
        await client.accounts.createPinterestBoard('acc_1', name: 'Recipes');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/accounts/acc_1/pinterest/boards');
    expect(jsonDecode(seen.last.body), {'name': 'Recipes'});
    expect(board.id, 'b1');
    client.close();
  });

  test('setting the default youtube playlist sends null to clear it', () async {
    final seen = RecordedRequests();
    final client =
        fakeClient((_) async => jsonOk({'playlist_id': null}), recorder: seen);

    final stored =
        await client.accounts.setDefaultYouTubePlaylist('acc_1', null);

    expect(seen.last.method, 'PUT');
    expect(jsonDecode(seen.last.body), {'playlist_id': null});
    expect(stored, isNull);
    client.close();
  });

  test('playlists mark the stored default', () async {
    final client = fakeClient((_) async => jsonOk([
          {'id': 'PL1', 'title': 'Tutorials', 'is_default': true}
        ]));

    final playlists = await client.accounts.youtubePlaylists('acc_1');

    expect(playlists.single.isDefault, isTrue);
    client.close();
  });

  test('bluesky languages round trip', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'languages': ['en', 'pt-BR']
            }),
        recorder: seen);

    final result =
        await client.accounts.setBlueskyLanguages('acc_1', ['en', 'pt-BR']);

    expect(seen.last.method, 'PUT');
    expect(jsonDecode(seen.last.body), {
      'languages': ['en', 'pt-BR']
    });
    expect(result.languages, ['en', 'pt-BR']);
    client.close();
  });

  test("tiktok creator info reports the account's own switches", () async {
    final client = fakeClient((_) async => jsonOk({
          'privacy_level_options': ['PUBLIC_TO_EVERYONE'],
          'comment_disabled': false,
          'duet_disabled': true,
          'stitch_disabled': false,
          'max_video_post_duration_sec': 600,
        }));

    final info = await client.accounts.tiktokCreatorInfo('acc_1');

    expect(info.duetDisabled, isTrue);
    expect(info.stitchDisabled, isFalse);
    expect(info.maxVideoPostDurationSec, 600);
    client.close();
  });

  test('tiktok music search passes the query through', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {'id': 'm1', 'title': 'Sunrise', 'author': 'Kite'}
            ]),
        recorder: seen);

    final tracks =
        await client.accounts.tiktokMusic('acc_1', query: 'sunrise', limit: 5);

    expect(tracks.single.id, 'm1');
    expect(seen.last.url.queryParameters['q'], 'sunrise');
    expect(seen.last.url.queryParameters['limit'], '5');
    client.close();
  });

  test('tiktok video lookup returns the address a repurpose run reads',
      () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk({
              'video_id': '7300000000000000000',
              'download_url':
                  'https://www.tiktok.com/@a/video/7300000000000000000',
            }),
        recorder: seen);

    final video = await client.accounts.tiktokVideoLookup(
        'acc_1', 'https://www.tiktok.com/@a/video/7300000000000000000');

    expect(seen.last.method, 'POST');
    expect(video.videoId, '7300000000000000000');
    expect(video.downloadUrl, isNotNull);
    client.close();
  });

  test('instagram stories ask for insights only when requested', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {
                'id': 's1',
                'media_type': 'IMAGE',
                'insights': {'views': 40}
              }
            ]),
        recorder: seen);

    await client.accounts.instagramStories('acc_1');
    expect(seen.last.url.query, isEmpty);

    final stories =
        await client.accounts.instagramStories('acc_1', insights: true);
    expect(seen.last.url.queryParameters['insights'], 'true');
    expect(stories.single.insights?['views'], 40);
    client.close();
  });

  test('linkedin mentions carry the annotation to paste', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {
                'urn': 'urn:li:organization:2414183',
                'name': 'Devtestco',
                'annotation': '@[Devtestco](urn:li:organization:2414183)',
              }
            ]),
        recorder: seen);

    final mentions =
        await client.accounts.linkedinMentions('acc_1', 'devtestco');

    expect(seen.last.url.path, '/v1/accounts/acc_1/linkedin/mentions');
    expect(seen.last.url.queryParameters['q'], 'devtestco');
    expect(mentions.single.annotation,
        '@[Devtestco](urn:li:organization:2414183)');
    client.close();
  });
}
