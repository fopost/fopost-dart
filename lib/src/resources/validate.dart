import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/validate.dart';

/// Standalone checks that store nothing: a draft against its platforms, a
/// text's length, a media URL, or a subreddit.
///
/// Every call needs the `posts` scope. Reach it as `client.validate`.
class ValidateResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  ValidateResource(this._http);

  final FoPostHttp _http;

  /// Checks [content] and [media] against each of [platforms].
  Future<ValidatePostResult> post({
    required List<String> platforms,
    String? content,
    List<ValidateMedia>? media,
  }) async {
    final body = pruned({
      'content': content,
      'media': media?.map((m) => m.toJson()).toList(),
      'platforms': platforms,
    });
    return ValidatePostResult.fromJson(
        await _http.object('POST', '/validate/post', body: body));
  }

  /// Counts [text] the way each of [platforms] does and compares it to the
  /// platform's limit.
  Future<ValidateLengthResult> length({
    required String text,
    required List<String> platforms,
  }) async {
    final body = {'text': text, 'platforms': platforms};
    return ValidateLengthResult.fromJson(
        await _http.object('POST', '/validate/length', body: body));
  }

  /// Fetches the file at [url] and checks it. A file that fails a check still
  /// answers `200` with [ValidateMediaResult.issues].
  Future<ValidateMediaResult> media({required String url}) async =>
      ValidateMediaResult.fromJson(
          await _http.object('POST', '/validate/media', body: {'url': url}));

  /// Checks whether the subreddit [name] exists and takes a post from
  /// [accountId].
  ///
  /// The check runs with that account's own token, so the account has to be one
  /// the key can see. A private, banned or missing subreddit still answers
  /// `200`, with [ValidateSubredditResult.exists] false.
  Future<ValidateSubredditResult> subreddit({
    required String accountId,
    required String name,
  }) async =>
      ValidateSubredditResult.fromJson(await _http.object(
        'GET',
        '/validate/subreddit',
        query: {'account_id': accountId, 'name': name},
      ));
}
