import 'package:meta/meta.dart';

import '../errors.dart';
import '../http.dart';
import '../json.dart';
import '../models/blog.dart';
import 'base.dart';

/// The blog: settings, the keyword plan, and the articles written from it.
///
/// An article goes to a website, never to a social network. Where it goes is
/// the settings' target: the hosted blog, a connected account, or your own
/// site, which receives a signed `article.published` webhook you check with
/// `verifyWebhook`.
///
/// Reads, settings, keyword edits and [submitArticle] need the `posts` scope.
/// [suggestSeeds], [planKeywords], [requestArticle] and [regenerateArticle]
/// spend AI credits and need `ai`; an empty balance answers `402`.
/// [publishArticle] needs `publish`.
///
/// Every call names its workspace, because the key may reach several.
///
/// Reach it as `client.blog`.
class BlogResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  BlogResource(this._http);

  final FoPostHttp _http;

  // ─── Settings ─────────────────────────────────────────────────────

  /// Returns the workspace's blog settings.
  Future<BlogSettings> getSettings(String workspaceId) async =>
      BlogSettings.fromJson(await _http.object('GET', '/blog/settings',
          query: {'workspace_id': workspaceId}));

  /// Changes the settings. Only the fields given are touched.
  ///
  /// [goal] is one of [BlogGoal]. [reviewHoldDays] is how many days before
  /// its planned date a picked keyword starts being written.
  ///
  /// Setting [websiteUrl] for the first time issues the signing secret, which
  /// comes back once as `BlogSettingsUpdate.websiteSecret`. A `clear*` flag
  /// sends `null` for a field that can be unset.
  Future<BlogSettingsUpdate> updateSettings(
    String workspaceId, {
    String? siteUrl,
    String? topic,
    String? audience,
    String? goal,
    String? focusTopics,
    String? avoidTopics,
    String? language,
    int? locationCode,
    int? cadencePerWeek,
    int? reviewHoldDays,
    String? imageTier,
    int? inBodyImages,
    int? minWords,
    int? maxWords,
    String? brandVoiceId,
    String? targetKind,
    String? targetAccountId,
    String? websiteUrl,
    bool clearSiteUrl = false,
    bool clearBrandVoiceId = false,
    bool clearTarget = false,
    bool clearTargetAccountId = false,
    bool clearWebsiteUrl = false,
  }) async {
    final body = pruned({
      'workspaceId': workspaceId,
      'siteUrl': siteUrl,
      'topic': topic,
      'audience': audience,
      'goal': goal,
      'focusTopics': focusTopics,
      'avoidTopics': avoidTopics,
      'language': language,
      'locationCode': locationCode,
      'cadencePerWeek': cadencePerWeek,
      'reviewHoldDays': reviewHoldDays,
      'imageTier': imageTier,
      'inBodyImages': inBodyImages,
      'minWords': minWords,
      'maxWords': maxWords,
      'brandVoiceId': brandVoiceId,
      'targetKind': targetKind,
      'targetAccountId': targetAccountId,
      'websiteUrl': websiteUrl,
    });
    if (clearSiteUrl) body['siteUrl'] = null;
    if (clearBrandVoiceId) body['brandVoiceId'] = null;
    if (clearTarget) body['targetKind'] = null;
    if (clearTargetAccountId) body['targetAccountId'] = null;
    if (clearWebsiteUrl) body['websiteUrl'] = null;
    return BlogSettingsUpdate.fromJson(
        await _http.object('PATCH', '/blog/settings', body: body));
  }

  /// Issues a new website signing secret and returns it.
  ///
  /// The old one stops verifying at once, so update the receiver first.
  Future<String> rotateWebsiteSecret(String workspaceId) async {
    final body = await _http.object('POST', '/blog/settings/website-secret',
        body: {'workspaceId': workspaceId});
    return asString(body['website_secret']) ?? '';
  }

  /// Sends a signed `article.test` delivery to the website target.
  ///
  /// A site that does not answer 2xx comes back as `ok: false` with its status
  /// and the error, rather than throwing.
  Future<BlogWebsiteTest> testWebsite(String workspaceId) async {
    try {
      return BlogWebsiteTest.fromJson(await _http.object(
          'POST', '/blog/settings/website-test',
          body: {'workspaceId': workspaceId}));
    } on FoPostServerException catch (error) {
      // The API answers 502 with the site's status when the delivery failed.
      if (error.statusCode != 502) rethrow;
      return BlogWebsiteTest.fromJson(error.bodyMap);
    }
  }

  // ─── Keywords ─────────────────────────────────────────────────────

  /// Returns the keyword plan, optionally narrowed to some [status] values
  /// from [BlogKeywordStatus].
  Future<List<BlogKeyword>> listKeywords(
    String workspaceId, {
    List<String>? status,
    int? limit,
  }) async {
    final rows = await _http.objects('GET', '/blog/keywords', query: {
      'workspace_id': workspaceId,
      'status': status,
      'limit': limit,
    });
    return rows.map(BlogKeyword.fromJson).toList();
  }

  /// Suggests about ten search terms from the blog goal and topics, for you to
  /// edit before [planKeywords].
  ///
  /// Pass the current [seeds] to refine them and [prompt] (up to 500
  /// characters) to steer. Spends AI credits.
  Future<List<String>> suggestSeeds(
    String workspaceId, {
    List<String>? seeds,
    String? prompt,
  }) async {
    final body = await _http.object('POST', '/blog/keywords/suggest',
        body: pruned({
          'workspaceId': workspaceId,
          'seeds': seeds,
          'prompt': prompt,
        }));
    return asStringList(body['seeds']);
  }

  /// Queues a research run over [seeds], or terms derived from the settings
  /// when omitted.
  ///
  /// Returns as soon as the run is queued; follow it in
  /// `BlogSettings.planRun`. Results arrive as `suggested` keywords and do not
  /// fill the calendar: set one to `planned` with [updateKeyword] to pick it.
  /// Spends AI credits.
  Future<void> planKeywords(String workspaceId, {List<String>? seeds}) =>
      _http.discard('POST', '/blog/keywords/plan',
          body: pruned({'workspaceId': workspaceId, 'seeds': seeds}));

  /// Adds a keyword of your own, optionally planned for a `YYYY-MM-DD` day.
  Future<BlogKeyword> addKeyword(
    String workspaceId, {
    required String keyword,
    String? plannedFor,
  }) async =>
      BlogKeyword.fromJson(await _http.object('POST', '/blog/keywords',
          body: pruned({
            'workspaceId': workspaceId,
            'keyword': keyword,
            'plannedFor': plannedFor,
          })));

  /// Changes a keyword's status or planned day. [clearPlannedFor] sends `null`.
  ///
  /// Setting [status] to `planned` picks the keyword, and it takes the next
  /// free date unless [plannedFor] names one.
  Future<BlogKeyword> updateKeyword(
    String workspaceId,
    String id, {
    String? status,
    String? plannedFor,
    bool clearPlannedFor = false,
  }) async {
    final body = pruned({'status': status, 'plannedFor': plannedFor});
    if (clearPlannedFor) body['plannedFor'] = null;
    return BlogKeyword.fromJson(await _http.object(
      'PATCH',
      '/blog/keywords/${segment(id)}',
      body: body,
      query: {'workspace_id': workspaceId},
    ));
  }

  /// Removes a keyword from the plan.
  Future<void> deleteKeyword(String workspaceId, String id) =>
      _http.discard('DELETE', '/blog/keywords/${segment(id)}',
          query: {'workspace_id': workspaceId});

  // ─── Articles ─────────────────────────────────────────────────────

  /// Returns articles, newest first, optionally narrowed to some [status]
  /// values from [BlogArticleStatus].
  Future<List<BlogArticle>> listArticles(
    String workspaceId, {
    List<String>? status,
    int? limit,
  }) async {
    final rows = await _http.objects('GET', '/blog/articles', query: {
      'workspace_id': workspaceId,
      'status': status,
      'limit': limit,
    });
    return rows.map(BlogArticle.fromJson).toList();
  }

  /// Queues an article. Give one of [title], [keyword] or [keywordId].
  ///
  /// Returns the article as `queued`; poll [getArticle] until it is a `draft`.
  /// Spends AI credits.
  Future<BlogArticle> requestArticle(
    String workspaceId, {
    String? title,
    String? keyword,
    String? keywordId,
    String? instructions,
  }) async =>
      BlogArticle.fromJson(await _http.object('POST', '/blog/articles',
          body: pruned({
            'workspaceId': workspaceId,
            'title': title,
            'keyword': keyword,
            'keywordId': keywordId,
            'instructions': instructions,
          })));

  /// Returns one article with its body, outline and images.
  Future<BlogArticleFull> getArticle(String workspaceId, String id) async =>
      BlogArticleFull.fromJson(await _http.object(
          'GET', '/blog/articles/${segment(id)}',
          query: {'workspace_id': workspaceId}));

  /// Edits a draft or scheduled article.
  ///
  /// [publishAt] puts an article in review on the calendar; a draft answers
  /// `409` until it is submitted with [submitArticle]. [clearPublishAt]
  /// returns it to review. An article that is not editable answers
  /// `409 invalid_state`.
  Future<BlogArticleFull> updateArticle(
    String workspaceId,
    String id, {
    String? title,
    String? slug,
    String? excerpt,
    String? metaTitle,
    String? metaDescription,
    String? bodyMarkdown,
    List<String>? tags,
    DateTime? publishAt,
    bool clearExcerpt = false,
    bool clearMetaTitle = false,
    bool clearMetaDescription = false,
    bool clearPublishAt = false,
  }) async {
    final body = pruned({
      'title': title,
      'slug': slug,
      'excerpt': excerpt,
      'metaTitle': metaTitle,
      'metaDescription': metaDescription,
      'bodyMarkdown': bodyMarkdown,
      'tags': tags,
      'publishAt': publishAt?.toUtc().toIso8601String(),
    });
    if (clearExcerpt) body['excerpt'] = null;
    if (clearMetaTitle) body['metaTitle'] = null;
    if (clearMetaDescription) body['metaDescription'] = null;
    if (clearPublishAt) body['publishAt'] = null;
    return BlogArticleFull.fromJson(await _http.object(
      'PATCH',
      '/blog/articles/${segment(id)}',
      body: body,
      query: {'workspace_id': workspaceId},
    ));
  }

  /// Writes the article again from its brief. Spends AI credits.
  Future<BlogArticle> regenerateArticle(String workspaceId, String id) async =>
      BlogArticle.fromJson(await _http.object(
          'POST', '/blog/articles/${segment(id)}/regenerate',
          query: {'workspace_id': workspaceId}));

  /// Moves a draft, failed or rejected article to `in_review`, ready for
  /// approval. Any other status answers `409`.
  Future<BlogArticle> submitArticle(String workspaceId, String id) async =>
      BlogArticle.fromJson(await _http.object(
          'POST', '/blog/articles/${segment(id)}/submit',
          query: {'workspace_id': workspaceId}));

  /// Approves an article in review and sends it to the target now.
  ///
  /// A draft answers `409` until it is submitted with [submitArticle].
  /// Returns once publishing is queued, not once the article is live. With no
  /// target set it answers `409 no_target`. Needs the `publish` scope.
  Future<BlogArticle> publishArticle(String workspaceId, String id) async =>
      BlogArticle.fromJson(await _http.object(
          'POST', '/blog/articles/${segment(id)}/publish',
          query: {'workspace_id': workspaceId}));

  /// Turns a draft down. It stays readable but never publishes.
  Future<BlogArticle> rejectArticle(String workspaceId, String id) async =>
      BlogArticle.fromJson(await _http.object(
          'POST', '/blog/articles/${segment(id)}/reject',
          query: {'workspace_id': workspaceId}));

  /// Removes an article. A published copy on the target is left alone.
  Future<void> deleteArticle(String workspaceId, String id) =>
      _http.discard('DELETE', '/blog/articles/${segment(id)}',
          query: {'workspace_id': workspaceId});
}
