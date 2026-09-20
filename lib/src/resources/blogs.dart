import 'package:meta/meta.dart';

import '../http.dart';
import '../models/blog.dart';
import 'base.dart';

/// Articles and products that already live on a connected site.
///
/// Reach it as `client.blogs`. Every id here is the platform's own, never a
/// FoPost id. Reads need the `posts` scope; anything that changes the site
/// needs `posts` and `publish`. An account on a platform that cannot manage
/// articles answers 400 `unsupported_platform`.
class BlogsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  BlogsResource(this._http);

  final FoPostHttp _http;

  String _blogs(String accountId) => '/accounts/${segment(accountId)}/blogs';

  String _articles(String accountId, String blogId) =>
      '${_blogs(accountId)}/${segment(blogId)}/articles';

  String _article(String accountId, String blogId, String articleId) =>
      '${_articles(accountId, blogId)}/${segment(articleId)}';

  Map<String, dynamic> _articleBody({
    String? title,
    String? body,
    String? excerpt,
    String? status,
    List<String>? tags,
    String? authorName,
    String? imageUrl,
  }) =>
      {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (excerpt != null) 'excerpt': excerpt,
        if (status != null) 'status': status,
        if (tags != null) 'tags': tags,
        if (authorName != null) 'author_name': authorName,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  /// Returns the blogs the account can write to.
  ///
  /// WordPress reports its one implicit blog, under the id `default`.
  Future<List<RemoteBlog>> listBlogs(String accountId) async {
    final rows = await _http.objects('GET', _blogs(accountId));
    return rows.map(RemoteBlog.fromJson).toList();
  }

  /// Returns the blog's articles, newest first, drafts included.
  Future<List<RemoteArticle>> listArticles(
    String accountId,
    String blogId, {
    int? limit,
    String? status,
    String? q,
  }) async {
    final rows = await _http.objects(
      'GET',
      _articles(accountId, blogId),
      query: {'limit': limit, 'status': status, 'q': q},
    );
    return rows.map(RemoteArticle.fromJson).toList();
  }

  /// Returns one article in full.
  Future<RemoteArticle> getArticle(
    String accountId,
    String blogId,
    String articleId,
  ) async =>
      RemoteArticle.fromJson(
          await _http.object('GET', _article(accountId, blogId, articleId)));

  /// Writes a new article to the site. Needs the `publish` scope.
  ///
  /// [body] is FoPost body markup; the site's own format is rendered from it.
  Future<RemoteArticle> createArticle(
    String accountId,
    String blogId, {
    required String title,
    required String body,
    String? excerpt,
    String? status,
    List<String>? tags,
    String? authorName,
    String? imageUrl,
  }) async =>
      RemoteArticle.fromJson(await _http.object(
        'POST',
        _articles(accountId, blogId),
        body: _articleBody(
          title: title,
          body: body,
          excerpt: excerpt,
          status: status,
          tags: tags,
          authorName: authorName,
          imageUrl: imageUrl,
        ),
      ));

  /// Changes the live article in place. Needs the `publish` scope.
  ///
  /// Only what is passed changes, and the article is addressed by its own id,
  /// so this never creates a second post.
  Future<RemoteArticle> updateArticle(
    String accountId,
    String blogId,
    String articleId, {
    String? title,
    String? body,
    String? excerpt,
    String? status,
    List<String>? tags,
    String? authorName,
    String? imageUrl,
  }) async =>
      RemoteArticle.fromJson(await _http.object(
        'PATCH',
        _article(accountId, blogId, articleId),
        body: _articleBody(
          title: title,
          body: body,
          excerpt: excerpt,
          status: status,
          tags: tags,
          authorName: authorName,
          imageUrl: imageUrl,
        ),
      ));

  /// Removes the article from the site. This cannot be undone.
  Future<void> deleteArticle(
    String accountId,
    String blogId,
    String articleId,
  ) =>
      _http.discard('DELETE', _article(accountId, blogId, articleId));

  /// Returns the store's products.
  Future<List<RemoteProduct>> listProducts(
    String accountId, {
    int? limit,
    String? status,
    String? q,
  }) async {
    final rows = await _http.objects(
      'GET',
      '/accounts/${segment(accountId)}/products',
      query: {'limit': limit, 'status': status, 'q': q},
    );
    return rows.map(RemoteProduct.fromJson).toList();
  }

  /// Changes a product on the store. Only what is passed changes.
  Future<RemoteProduct> updateProduct(
    String accountId,
    String productId, {
    String? title,
    String? description,
    String? status,
    List<String>? tags,
    String? productType,
    String? vendor,
  }) async =>
      RemoteProduct.fromJson(await _http.object(
        'PATCH',
        '/accounts/${segment(accountId)}/products/${segment(productId)}',
        body: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (status != null) 'status': status,
          if (tags != null) 'tags': tags,
          if (productType != null) 'product_type': productType,
          if (vendor != null) 'vendor': vendor,
        },
      ));
}
