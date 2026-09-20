import 'dart:convert';

import 'package:fopost/fopost.dart';
import 'package:test/test.dart';

import 'support.dart';

const _article = {
  'id': '99',
  'blog_id': '11',
  'title': 'Spring drop',
  'body_html': '<p>Hello</p>',
  'excerpt': 'A short summary',
  'status': 'published',
  'author_name': 'Store Owner',
  'tags': ['news'],
  'image_url': 'https://cdn.example/img.png',
  'url': 'https://demo.myshopify.com/blogs/article/spring-drop',
  'published_at': '2026-09-01T10:00:00Z',
  'updated_at': '2026-09-02T10:00:00Z',
};

void main() {
  test('lists the blogs on the site', () async {
    final seen = RecordedRequests();
    final client = fakeClient(
        (_) async => jsonOk([
              {'id': '11', 'title': 'News', 'handle': 'news', 'url': null}
            ]),
        recorder: seen);

    final blogs = await client.blogs.listBlogs('acc_1');

    expect(seen.last.method, 'GET');
    expect(seen.last.url.path, '/v1/accounts/acc_1/blogs');
    expect(blogs.single.id, '11');
    expect(blogs.single.title, 'News');
    expect(blogs.single.url, isNull);
    client.close();
  });

  test('lists articles with the filters', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk(<Object>[]), recorder: seen);

    await client.blogs
        .listArticles('acc_1', '11', limit: 5, status: 'draft', q: 'spring');

    expect(seen.last.url.path, '/v1/accounts/acc_1/blogs/11/articles');
    expect(seen.last.url.queryParameters,
        {'limit': '5', 'status': 'draft', 'q': 'spring'});
    client.close();
  });

  test('reads an article into its fields', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk(_article), recorder: seen);

    final article = await client.blogs.getArticle('acc_1', '11', '99');

    expect(seen.last.url.path, '/v1/accounts/acc_1/blogs/11/articles/99');
    expect(article.id, '99');
    expect(article.blogId, '11');
    expect(article.status, 'published');
    expect(article.tags, ['news']);
    expect(article.updatedAt, isNotNull);
    client.close();
  });

  test('creates an article with only the fields set', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk(_article), recorder: seen);

    await client.blogs.createArticle('acc_1', '11',
        title: 'Spring drop', body: 'Hello', status: 'draft');

    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/v1/accounts/acc_1/blogs/11/articles');
    expect(jsonDecode(seen.last.body),
        {'title': 'Spring drop', 'body': 'Hello', 'status': 'draft'});
    client.close();
  });

  // The article is addressed by its own id, so an update never forks a duplicate.
  test('updates the live article in place', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk(_article), recorder: seen);

    await client.blogs
        .updateArticle('acc_1', '11', '99', title: 'Spring drop, restocked');

    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/accounts/acc_1/blogs/11/articles/99');
    expect(jsonDecode(seen.last.body), {'title': 'Spring drop, restocked'});
    client.close();
  });

  test('deletes an article', () async {
    final seen = RecordedRequests();
    final client = fakeClient((_) async => jsonOk(null), recorder: seen);

    await client.blogs.deleteArticle('acc_1', '11', '99');

    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/accounts/acc_1/blogs/11/articles/99');
    client.close();
  });

  test('lists and updates products', () async {
    final seen = RecordedRequests();
    var calls = 0;
    final client = fakeClient((_) async {
      calls++;
      return calls == 1
          ? jsonOk([
              {
                'id': '7',
                'title': 'Mug',
                'status': 'active',
                'tags': <String>[],
                'price': '12.00',
                'currency': 'USD'
              }
            ])
          : jsonOk({
              'id': '7',
              'title': 'Mug XL',
              'status': 'draft',
              'tags': <String>[]
            });
    }, recorder: seen);

    final products = await client.blogs.listProducts('acc_1', status: 'active');
    expect(seen.last.url.path, '/v1/accounts/acc_1/products');
    expect(seen.last.url.queryParameters, {'status': 'active'});
    expect(products.single.price, '12.00');
    expect(products.single.currency, 'USD');

    final updated = await client.blogs
        .updateProduct('acc_1', '7', title: 'Mug XL', status: 'draft');
    expect(seen.last.method, 'PATCH');
    expect(seen.last.url.path, '/v1/accounts/acc_1/products/7');
    expect(jsonDecode(seen.last.body), {'title': 'Mug XL', 'status': 'draft'});
    expect(updated.status, 'draft');
    client.close();
  });
}
