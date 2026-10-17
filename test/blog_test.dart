import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

const settingsJson = {
  'siteUrl': 'https://yourbrand.com',
  'topic': 'Running shoes',
  'audience': 'Weekend runners',
  'language': 'en',
  'locationCode': 2840,
  'cadencePerWeek': 2,
  'reviewHoldDays': 3,
  'autoPublish': false,
  'imageTier': 'standard',
  'inBodyImages': 2,
  'minWords': 900,
  'maxWords': 1500,
  'brandVoiceId': null,
  'targetKind': 'website',
  'targetAccountId': null,
  'targetPlatform': null,
  'websiteUrl': 'https://yourbrand.com/fopost',
  'hasWebsiteSecret': true,
  'keywordDataAvailable': true,
  'updatedAt': '2026-10-10T08:00:00.000Z',
};

const keywordJson = {
  'id': 'kw_1',
  'keyword': 'best trail running shoes',
  'searchVolume': 4400,
  'difficulty': 38,
  'cpc': 1.25,
  'intent': 'commercial',
  'source': 'provider',
  'status': 'suggested',
  'plannedFor': null,
  'createdAt': '2026-10-09T12:00:00.000Z',
};

const articleJson = {
  'id': 'art_1',
  'title': 'The Best Trail Running Shoes of the Year',
  'slug': 'best-trail-running-shoes',
  'keyword': 'best trail running shoes',
  'excerpt': 'Our picks.',
  'metaTitle': null,
  'metaDescription': null,
  'featuredImage': {
    'mediaId': 'med_1',
    'url': 'https://media.example/hero.jpg',
    'alt': 'Trail shoes on a rock',
  },
  'tags': ['running', 'gear'],
  'wordCount': 1200,
  'status': 'draft',
  'origin': 'plan',
  'reviewUntil': '2026-10-13T08:00:00.000Z',
  'publishAt': null,
  'publishedAt': null,
  'publishedUrl': null,
  'error': null,
  'createdAt': '2026-10-10T08:00:00.000Z',
  'updatedAt': '2026-10-10T09:00:00.000Z',
};

const fullArticleJson = {
  ...articleJson,
  'instructions': 'Lead with the lightest pair.',
  'outline': ['Why trail shoes differ', 'Our picks'],
  'brief': {'sources': 3},
  'bodyMarkdown': '# Hello',
  'bodyHtml': '<h1>Hello</h1>',
  'images': [
    {
      'mediaId': 'med_2',
      'url': 'https://media.example/in-body.jpg',
      'alt': 'A muddy trail',
      'position': 1,
    },
  ],
};

void main() {
  group('settings', () {
    test('getSettings reads camelCase and passes the workspace as a query',
        () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(settingsJson), recorder: seen);

      final settings = await client.blog.getSettings('ws_1');

      expect(seen.last.method, 'GET');
      expect(seen.last.url.path, '/v1/blog/settings');
      expect(seen.last.url.queryParameters, {'workspaceId': 'ws_1'});
      expect(settings.targetKind, BlogTargetKind.website);
      expect(settings.cadencePerWeek, 2);
      expect(settings.hasWebsiteSecret, isTrue);
      expect(settings.websiteUrl, 'https://yourbrand.com/fopost');
    });

    test('updateSettings sends the workspace in the body and keeps the secret',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async =>
            jsonBare({'data': settingsJson, 'websiteSecret': 'whsec_abc'}),
        recorder: seen,
      );

      final result = await client.blog.updateSettings(
        'ws_1',
        targetKind: BlogTargetKind.website,
        websiteUrl: 'https://yourbrand.com/fopost',
        clearBrandVoiceId: true,
      );

      expect(seen.last.method, 'PATCH');
      expect(seen.last.url.path, '/v1/blog/settings');
      expect(jsonDecode(seen.last.body), {
        'workspaceId': 'ws_1',
        'targetKind': 'website',
        'websiteUrl': 'https://yourbrand.com/fopost',
        'brandVoiceId': null,
      });
      expect(result.websiteSecret, 'whsec_abc');
      expect(result.settings.topic, 'Running shoes');
    });

    test('updateSettings answers a null secret when none was issued', () async {
      final client = fakeClient(
          (_) async => jsonBare({'data': settingsJson, 'websiteSecret': null}));

      final result = await client.blog.updateSettings('ws_1', topic: 'Shoes');

      expect(result.websiteSecret, isNull);
    });

    test('rotateWebsiteSecret returns the new secret', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
          (_) async => jsonOk({'websiteSecret': 'whsec_new'}),
          recorder: seen);

      final secret = await client.blog.rotateWebsiteSecret('ws_1');

      expect(seen.last.url.path, '/v1/blog/settings/website-secret');
      expect(jsonDecode(seen.last.body), {'workspaceId': 'ws_1'});
      expect(secret, 'whsec_new');
    });

    test('testWebsite reads a 502 as a failed test instead of throwing',
        () async {
      final client = fakeClient(
        (_) async => jsonBare(
          {
            'data': {'ok': false, 'status': 500, 'error': 'site answered 500'},
          },
          status: 502,
        ),
        maxRetries: 1,
      );

      final result = await client.blog.testWebsite('ws_1');

      expect(result.ok, isFalse);
      expect(result.status, 500);
      expect(result.error, 'site answered 500');
    });
  });

  group('keywords', () {
    test('listKeywords joins statuses and reads the rows', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk([keywordJson]), recorder: seen);

      final keywords = await client.blog.listKeywords(
        'ws_1',
        status: [BlogKeywordStatus.suggested, BlogKeywordStatus.planned],
        limit: 50,
      );

      expect(seen.last.url.path, '/v1/blog/keywords');
      expect(seen.last.url.queryParameters, {
        'workspaceId': 'ws_1',
        'status': 'suggested,planned',
        'limit': '50',
      });
      final keyword = keywords.single;
      expect(keyword.keyword, 'best trail running shoes');
      expect(keyword.searchVolume, 4400);
      expect(keyword.cpc, 1.25);
    });

    test('planKeywords posts the seeds and accepts a 202', () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonBare({
          'data': {'status': 'queued'},
        }, status: 202),
        recorder: seen,
      );

      await client.blog.planKeywords('ws_1', seeds: ['trail shoes']);

      expect(seen.last.method, 'POST');
      expect(seen.last.url.path, '/v1/blog/keywords/plan');
      expect(jsonDecode(seen.last.body), {
        'workspaceId': 'ws_1',
        'seeds': ['trail shoes'],
      });
    });

    test('planKeywords surfaces an empty balance as 402 with the upgrade url',
        () async {
      final client = fakeClient(
        (_) async => jsonError(402, 'insufficient_credits', 'Balance is empty',
            extra: {'upgrade_url': 'https://app.fopost.com/billing'}),
        maxRetries: 1,
      );

      await expectLater(
        client.blog.planKeywords('ws_1'),
        throwsA(isA<FoPostPaymentRequiredException>()
            .having((e) => e.code, 'code', 'insufficient_credits')
            .having((e) => e.upgradeUrl, 'upgradeUrl',
                'https://app.fopost.com/billing')),
      );
    });

    test('addKeyword, updateKeyword and deleteKeyword address the right route',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient((request) async {
        if (request.method == 'DELETE') return jsonBare(null, status: 204);
        return jsonOk({...keywordJson, 'status': 'planned'});
      }, recorder: seen);

      await client.blog
          .addKeyword('ws_1', keyword: 'trail shoes', plannedFor: '2026-10-20');
      expect(seen.last.method, 'POST');
      expect(seen.last.url.path, '/v1/blog/keywords');
      expect(jsonDecode(seen.last.body), {
        'workspaceId': 'ws_1',
        'keyword': 'trail shoes',
        'plannedFor': '2026-10-20',
      });

      final updated = await client.blog.updateKeyword('ws_1', 'kw_1',
          status: BlogKeywordStatus.planned, clearPlannedFor: true);
      expect(seen.last.method, 'PATCH');
      expect(seen.last.url.path, '/v1/blog/keywords/kw_1');
      expect(seen.last.url.queryParameters, {'workspaceId': 'ws_1'});
      expect(jsonDecode(seen.last.body),
          {'status': 'planned', 'plannedFor': null});
      expect(updated.status, 'planned');

      await client.blog.deleteKeyword('ws_1', 'kw_1');
      expect(seen.last.method, 'DELETE');
      expect(seen.last.url.path, '/v1/blog/keywords/kw_1');
      expect(seen.last.url.queryParameters, {'workspaceId': 'ws_1'});
    });
  });

  group('articles', () {
    test('listArticles reads the list shape', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk([articleJson]), recorder: seen);

      final articles = await client.blog
          .listArticles('ws_1', status: [BlogArticleStatus.draft]);

      expect(seen.last.url.path, '/v1/blog/articles');
      expect(seen.last.url.queryParameters,
          {'workspaceId': 'ws_1', 'status': 'draft'});
      final article = articles.single;
      expect(article.slug, 'best-trail-running-shoes');
      expect(article.featuredImage?.mediaId, 'med_1');
      expect(article.tags, ['running', 'gear']);
      expect(article.reviewUntil, DateTime.utc(2026, 10, 13, 8));
    });

    test('requestArticle sends the workspace in the body and accepts a 202',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient(
        (_) async => jsonBare({
          'data': {...articleJson, 'status': 'queued', 'wordCount': 0},
        }, status: 202),
        recorder: seen,
      );

      final article = await client.blog.requestArticle('ws_1',
          keywordId: 'kw_1', instructions: 'Lead with the lightest pair.');

      expect(seen.last.method, 'POST');
      expect(seen.last.url.path, '/v1/blog/articles');
      expect(jsonDecode(seen.last.body), {
        'workspaceId': 'ws_1',
        'keywordId': 'kw_1',
        'instructions': 'Lead with the lightest pair.',
      });
      expect(article.status, BlogArticleStatus.queued);
    });

    test('getArticle reads the body, outline and images', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(fullArticleJson), recorder: seen);

      final article = await client.blog.getArticle('ws_1', 'art_1');

      expect(seen.last.url.path, '/v1/blog/articles/art_1');
      expect(seen.last.url.queryParameters, {'workspaceId': 'ws_1'});
      expect(article.bodyMarkdown, '# Hello');
      expect(article.bodyHtml, '<h1>Hello</h1>');
      expect(article.outline, ['Why trail shoes differ', 'Our picks']);
      expect(article.images.single.position, 1);
      expect(article.brief, {'sources': 3});
      expect(article.instructions, 'Lead with the lightest pair.');
    });

    test('updateArticle sends the patch and a UTC publishAt', () async {
      final seen = RecordedRequests();
      final client =
          fakeClient((_) async => jsonOk(fullArticleJson), recorder: seen);

      await client.blog.updateArticle(
        'ws_1',
        'art_1',
        title: 'New title',
        tags: ['running'],
        publishAt: DateTime.utc(2026, 10, 20, 9),
        clearExcerpt: true,
      );

      expect(seen.last.method, 'PATCH');
      expect(seen.last.url.path, '/v1/blog/articles/art_1');
      expect(seen.last.url.queryParameters, {'workspaceId': 'ws_1'});
      expect(jsonDecode(seen.last.body), {
        'title': 'New title',
        'tags': ['running'],
        'publishAt': '2026-10-20T09:00:00.000Z',
        'excerpt': null,
      });
    });

    test('publish, regenerate, reject and delete address the right routes',
        () async {
      final seen = RecordedRequests();
      final client = fakeClient((request) async {
        if (request.method == 'DELETE') return jsonBare(null, status: 204);
        return jsonBare({'data': articleJson}, status: 202);
      }, recorder: seen);

      await client.blog.publishArticle('ws_1', 'art_1');
      expect(seen.last.method, 'POST');
      expect(seen.last.url.path, '/v1/blog/articles/art_1/publish');
      expect(seen.last.url.queryParameters, {'workspaceId': 'ws_1'});

      await client.blog.regenerateArticle('ws_1', 'art_1');
      expect(seen.last.url.path, '/v1/blog/articles/art_1/regenerate');

      await client.blog.rejectArticle('ws_1', 'art_1');
      expect(seen.last.url.path, '/v1/blog/articles/art_1/reject');

      await client.blog.deleteArticle('ws_1', 'art_1');
      expect(seen.last.method, 'DELETE');
      expect(seen.last.url.path, '/v1/blog/articles/art_1');
      expect(seen.last.url.queryParameters, {'workspaceId': 'ws_1'});
    });

    test('publish with no target is a 409 with its code', () async {
      final client = fakeClient(
        (_) async => jsonError(409, 'no_target', 'Set a target first'),
        maxRetries: 1,
      );

      await expectLater(
        client.blog.publishArticle('ws_1', 'art_1'),
        throwsA(isA<FoPostException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.code, 'code', 'no_target')),
      );
    });
  });
}
