import '../json.dart';

/// A blog on a connected site.
///
/// [id] is the platform's own id, never a FoPost id. A Shopify store reports
/// every blog it has; WordPress has one implicit blog and reports it under the
/// id `default`, so both answer the same shape.
class RemoteBlog {
  /// Creates a blog.
  const RemoteBlog({
    required this.id,
    required this.title,
    this.handle,
    this.url,
  });

  /// Reads a blog.
  factory RemoteBlog.fromJson(Map<String, dynamic> json) => RemoteBlog(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        handle: asString(json['handle']),
        url: asString(json['url']),
      );

  /// The blog's id on the platform.
  final String id;

  /// The blog's name.
  final String title;

  /// The blog's slug on the site.
  final String? handle;

  /// Where the blog lives.
  final String? url;

  @override
  String toString() => 'RemoteBlog($title)';
}

/// An article that already lives on a connected site.
class RemoteArticle {
  /// Creates an article.
  const RemoteArticle({
    required this.id,
    required this.title,
    required this.status,
    required this.tags,
    this.blogId,
    this.bodyHtml,
    this.excerpt,
    this.authorName,
    this.imageUrl,
    this.url,
    this.publishedAt,
    this.updatedAt,
  });

  /// Reads an article.
  factory RemoteArticle.fromJson(Map<String, dynamic> json) => RemoteArticle(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        status: asString(json['status']) ?? '',
        tags: asStringList(json['tags']),
        blogId: asString(json['blog_id'] ?? json['blogId']),
        bodyHtml: asString(json['body_html'] ?? json['bodyHtml']),
        excerpt: asString(json['excerpt']),
        authorName: asString(json['author_name'] ?? json['authorName']),
        imageUrl: asString(json['image_url'] ?? json['imageUrl']),
        url: asString(json['url']),
        publishedAt: asDate(json['published_at'] ?? json['publishedAt']),
        updatedAt: asDate(json['updated_at'] ?? json['updatedAt']),
      );

  /// The article's id on the platform.
  final String id;

  /// The article's title.
  final String title;

  /// One of `published`, `draft`, `pending` or `scheduled`.
  final String status;

  /// The article's tags.
  final List<String> tags;

  /// The blog it sits on.
  final String? blogId;

  /// The article body, as the site stores it.
  final String? bodyHtml;

  /// The summary shown in listings.
  final String? excerpt;

  /// The byline, where the platform carries one.
  final String? authorName;

  /// The featured image.
  final String? imageUrl;

  /// Where the article lives.
  final String? url;

  /// When it went live.
  final DateTime? publishedAt;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'RemoteArticle($title)';
}

/// A product on a connected store.
class RemoteProduct {
  /// Creates a product.
  const RemoteProduct({
    required this.id,
    required this.title,
    required this.status,
    required this.tags,
    this.handle,
    this.description,
    this.vendor,
    this.productType,
    this.imageUrl,
    this.url,
    this.price,
    this.currency,
    this.updatedAt,
  });

  /// Reads a product.
  factory RemoteProduct.fromJson(Map<String, dynamic> json) => RemoteProduct(
        id: asString(json['id']) ?? '',
        title: asString(json['title']) ?? '',
        status: asString(json['status']) ?? '',
        tags: asStringList(json['tags']),
        handle: asString(json['handle']),
        description: asString(json['description']),
        vendor: asString(json['vendor']),
        productType: asString(json['product_type'] ?? json['productType']),
        imageUrl: asString(json['image_url'] ?? json['imageUrl']),
        url: asString(json['url']),
        price: asString(json['price']),
        currency: asString(json['currency']),
        updatedAt: asDate(json['updated_at'] ?? json['updatedAt']),
      );

  /// The product's id on the platform.
  final String id;

  /// The product's title.
  final String title;

  /// One of `active`, `draft` or `archived`.
  final String status;

  /// The product's tags.
  final List<String> tags;

  /// The product's slug on the store.
  final String? handle;

  /// The product description, as the store stores it.
  final String? description;

  /// The vendor.
  final String? vendor;

  /// The product type.
  final String? productType;

  /// The featured image.
  final String? imageUrl;

  /// Where the product lives.
  final String? url;

  /// The lowest variant price, as a decimal string.
  final String? price;

  /// The currency [price] is in.
  final String? currency;

  /// When it last changed.
  final DateTime? updatedAt;

  @override
  String toString() => 'RemoteProduct($title)';
}
