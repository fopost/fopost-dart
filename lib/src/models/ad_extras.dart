import '../json.dart';

/// Where a messaging ad opens a conversation.
abstract final class MessagingDestination {
  /// Opens a Messenger thread.
  static const messenger = 'messenger';

  /// Opens an Instagram Direct thread.
  static const instagramDirect = 'instagram_direct';

  /// Opens a WhatsApp thread. Refused unless the deployment has a number.
  static const whatsApp = 'whatsapp';
}

/// How the ad platform reads a high-demand period's budget value.
abstract final class BudgetValueType {
  /// An absolute amount.
  static const absolute = 'ABSOLUTE';

  /// A multiple of the usual pace.
  static const multiplier = 'MULTIPLIER';
}

/// A product catalog on the connection's business portfolio, read live.
class ProductCatalog {
  /// Creates a catalog.
  const ProductCatalog({
    required this.id,
    required this.name,
    this.vertical,
    this.productCount,
  });

  /// Reads a catalog.
  factory ProductCatalog.fromJson(Map<String, dynamic> json) => ProductCatalog(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        vertical: asString(json['vertical']),
        productCount: asInt(json['productCount']),
      );

  /// The catalog's id on the ad platform.
  final String id;

  /// The catalog's name.
  final String name;

  /// The ad platform's catalog vertical.
  final String? vertical;

  /// How many products it holds.
  final int? productCount;
}

/// One product in a catalog. [priceMinor] is minor units of [currency].
class CatalogProduct {
  /// Creates a product.
  const CatalogProduct({
    required this.id,
    required this.retailerId,
    required this.name,
    this.description,
    this.availability,
    this.condition,
    this.priceMinor,
    this.currency,
    this.imageUrl,
    this.url,
  });

  /// Reads a product.
  factory CatalogProduct.fromJson(Map<String, dynamic> json) => CatalogProduct(
        id: asString(json['id']) ?? '',
        retailerId: asString(json['retailerId']) ?? '',
        name: asString(json['name']) ?? '',
        description: asString(json['description']),
        availability: asString(json['availability']),
        condition: asString(json['condition']),
        priceMinor: asInt(json['priceMinor']),
        currency: asString(json['currency']),
        imageUrl: asString(json['imageUrl']),
        url: asString(json['url']),
      );

  /// The product's id on the ad platform.
  final String id;

  /// Your own key for the product.
  final String retailerId;

  /// The product's name.
  final String name;

  /// Its description.
  final String? description;

  /// `in stock`, `out of stock`, and so on.
  final String? availability;

  /// `new`, `refurbished` or `used`.
  final String? condition;

  /// Minor units of [currency].
  final int? priceMinor;

  /// The currency the price is in.
  final String? currency;

  /// The product image.
  final String? imageUrl;

  /// The product page.
  final String? url;
}

/// One page of catalog products; pass [nextCursor] back as `after`.
class CatalogProductsPage {
  /// Creates a page.
  const CatalogProductsPage({required this.products, this.nextCursor});

  /// Reads a page.
  factory CatalogProductsPage.fromJson(Map<String, dynamic> json) =>
      CatalogProductsPage(
        products: asModelList(json['products'], CatalogProduct.fromJson),
        nextCursor: asString(json['nextCursor']),
      );

  /// The products on this page.
  final List<CatalogProduct> products;

  /// Pass this back as `after` for the next page.
  final String? nextCursor;
}

/// What a catalog product batch was accepted as.
class CatalogBatchResult {
  /// Creates a result.
  const CatalogBatchResult({required this.handles, required this.accepted});

  /// Reads a result.
  factory CatalogBatchResult.fromJson(Map<String, dynamic> json) =>
      CatalogBatchResult(
        handles: asStringList(json['handles']),
        accepted: asInt(json['accepted']) ?? 0,
      );

  /// The ad platform's handles for the batch.
  final List<String> handles;

  /// Products sent in this batch.
  final int accepted;
}

/// Keeps a catalog in step with a product file you host.
class ProductFeed {
  /// Creates a feed.
  const ProductFeed({
    required this.id,
    required this.name,
    this.url,
    this.schedule,
    this.createdAt,
  });

  /// Reads a feed.
  factory ProductFeed.fromJson(Map<String, dynamic> json) => ProductFeed(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        url: asString(json['url']),
        schedule: asString(json['schedule']),
        createdAt: asDate(json['createdAt']),
      );

  /// The feed's id on the ad platform.
  final String id;

  /// The feed's name.
  final String name;

  /// Set when the ad platform fetches the file on a schedule.
  final String? url;

  /// `HOURLY`, `DAILY` or `WEEKLY`.
  final String? schedule;

  /// When it was created.
  final DateTime? createdAt;
}

/// One run the ad platform made of a product feed.
class ProductFeedUpload {
  /// Creates an upload.
  const ProductFeedUpload({
    required this.id,
    this.startedAt,
    this.endedAt,
    this.status,
    this.errorCount,
    this.warningCount,
  });

  /// Reads an upload.
  factory ProductFeedUpload.fromJson(Map<String, dynamic> json) =>
      ProductFeedUpload(
        id: asString(json['id']) ?? '',
        startedAt: asDate(json['startedAt']),
        endedAt: asDate(json['endedAt']),
        status: asString(json['status']),
        errorCount: asInt(json['errorCount']),
        warningCount: asInt(json['warningCount']),
      );

  /// The upload's id.
  final String id;

  /// When the run started.
  final DateTime? startedAt;

  /// When it finished.
  final DateTime? endedAt;

  /// How the ad platform reports the run.
  final String? status;

  /// Rows it refused.
  final int? errorCount;

  /// Rows it accepted with a warning.
  final int? warningCount;
}

/// The slice of a catalog one catalog ad runs from.
class ProductSet {
  /// Creates a product set.
  const ProductSet({
    required this.id,
    required this.name,
    this.productCount,
    this.filter,
  });

  /// Reads a product set.
  factory ProductSet.fromJson(Map<String, dynamic> json) => ProductSet(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        productCount: asInt(json['productCount']),
        filter: asMapOrNull(json['filter']),
      );

  /// The set's id on the ad platform.
  final String id;

  /// The set's name.
  final String name;

  /// How many products match.
  final int? productCount;

  /// The ad platform's own product-set filter.
  final Map<String, dynamic>? filter;
}

/// A priced flight. Nothing is bought until it is reserved.
class ReachFrequencyPrediction {
  /// Creates a prediction.
  const ReachFrequencyPrediction({
    required this.id,
    required this.reserved,
    this.name,
    this.status,
    this.reach,
    this.impressions,
    this.frequencyCap,
    this.budgetMinor,
    this.startAt,
    this.endAt,
  });

  /// Reads a prediction.
  factory ReachFrequencyPrediction.fromJson(Map<String, dynamic> json) =>
      ReachFrequencyPrediction(
        id: asString(json['id']) ?? '',
        reserved: asBool(json['reserved']) ?? false,
        name: asString(json['name']),
        status: asString(json['status']),
        reach: asInt(json['reach']),
        impressions: asInt(json['impressions']),
        frequencyCap: asInt(json['frequencyCap']),
        budgetMinor: asInt(json['budgetMinor']),
        startAt: asDate(json['startAt']),
        endAt: asDate(json['endAt']),
      );

  /// The prediction's id.
  final String id;

  /// True once the prediction holds inventory.
  final bool reserved;

  /// The campaign name it was priced for.
  final String? name;

  /// How the ad platform reports it.
  final String? status;

  /// People it would reach.
  final int? reach;

  /// Impressions it would serve.
  final int? impressions;

  /// How often one person would see the ad.
  final int? frequencyCap;

  /// Account currency, minor units.
  final int? budgetMinor;

  /// When the flight starts.
  final DateTime? startAt;

  /// When it ends.
  final DateTime? endAt;
}

/// One public archive entry. Read live on every search and stored nowhere.
class AdLibraryEntry {
  /// Creates an entry.
  const AdLibraryEntry({
    required this.id,
    required this.bodies,
    required this.titles,
    required this.linkUrls,
    required this.publisherPlatforms,
    this.pageId,
    this.pageName,
    this.snapshotUrl,
    this.startedAt,
    this.endedAt,
    this.currency,
    this.spendLower,
    this.spendUpper,
    this.impressionsLower,
    this.impressionsUpper,
  });

  /// Reads an entry.
  factory AdLibraryEntry.fromJson(Map<String, dynamic> json) => AdLibraryEntry(
        id: asString(json['id']) ?? '',
        bodies: asStringList(json['bodies']),
        titles: asStringList(json['titles']),
        linkUrls: asStringList(json['linkUrls']),
        publisherPlatforms: asStringList(json['publisherPlatforms']),
        pageId: asString(json['pageId']),
        pageName: asString(json['pageName']),
        snapshotUrl: asString(json['snapshotUrl']),
        startedAt: asDate(json['startedAt']),
        endedAt: asDate(json['endedAt']),
        currency: asString(json['currency']),
        spendLower: asInt(json['spendLower']),
        spendUpper: asInt(json['spendUpper']),
        impressionsLower: asInt(json['impressionsLower']),
        impressionsUpper: asInt(json['impressionsUpper']),
      );

  /// The archive's id for the ad.
  final String id;

  /// Its creative bodies.
  final List<String> bodies;

  /// Its headlines.
  final List<String> titles;

  /// The links it carries.
  final List<String> linkUrls;

  /// Where it runs.
  final List<String> publisherPlatforms;

  /// The Page running it.
  final String? pageId;

  /// That Page's name.
  final String? pageName;

  /// A link into the public archive.
  final String? snapshotUrl;

  /// When delivery started.
  final DateTime? startedAt;

  /// When it stopped.
  final DateTime? endedAt;

  /// Only on the archive's disclosure entries.
  final String? currency;

  /// The low end of the disclosed spend range.
  final int? spendLower;

  /// The high end of the disclosed spend range.
  final int? spendUpper;

  /// The low end of the disclosed impressions range.
  final int? impressionsLower;

  /// The high end of the disclosed impressions range.
  final int? impressionsUpper;
}

/// One page of archive results.
class AdLibraryPage {
  /// Creates a page.
  const AdLibraryPage({required this.entries, this.nextCursor});

  /// Reads a page.
  factory AdLibraryPage.fromJson(Map<String, dynamic> json) => AdLibraryPage(
        entries: asModelList(json['entries'], AdLibraryEntry.fromJson),
        nextCursor: asString(json['nextCursor']),
      );

  /// The entries on this page.
  final List<AdLibraryEntry> entries;

  /// Pass this back as `after` for the next page.
  final String? nextCursor;
}

/// A creator who allowlisted this advertiser for partnership ads.
class PartnershipCreator {
  /// Creates a creator.
  const PartnershipCreator({
    required this.id,
    required this.permissions,
    this.username,
    this.name,
    this.status,
  });

  /// Reads a creator.
  factory PartnershipCreator.fromJson(Map<String, dynamic> json) =>
      PartnershipCreator(
        id: asString(json['id']) ?? '',
        permissions: asStringList(json['permissions']),
        username: asString(json['username']),
        name: asString(json['name']),
        status: asString(json['status']),
      );

  /// The creator's account id.
  final String id;

  /// What they allowed.
  final List<String> permissions;

  /// Their handle.
  final String? username;

  /// Their display name.
  final String? name;

  /// How the ad platform reports the permission.
  final String? status;
}

/// One change recorded on an ad account.
class AdActivity {
  /// Creates an activity row.
  const AdActivity({
    required this.id,
    this.eventType,
    this.actorName,
    this.objectName,
    this.objectType,
    this.extraData,
    this.createdAt,
  });

  /// Reads an activity row.
  factory AdActivity.fromJson(Map<String, dynamic> json) => AdActivity(
        id: asString(json['id']) ?? '',
        eventType: asString(json['eventType']),
        actorName: asString(json['actorName']),
        objectName: asString(json['objectName']),
        objectType: asString(json['objectType']),
        extraData: asString(json['extraData']),
        createdAt: asDate(json['createdAt']),
      );

  /// A key for the row.
  final String id;

  /// What changed.
  final String? eventType;

  /// Who changed it.
  final String? actorName;

  /// What it was changed on.
  final String? objectName;

  /// What kind of object that was.
  final String? objectType;

  /// Whatever else the ad platform recorded.
  final String? extraData;

  /// When it happened.
  final DateTime? createdAt;
}

/// Groups campaigns, ad sets and ads for reporting.
class AdLabel {
  /// Creates a label.
  const AdLabel({required this.id, required this.name, this.createdAt});

  /// Reads a label.
  factory AdLabel.fromJson(Map<String, dynamic> json) => AdLabel(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        createdAt: asDate(json['createdAt']),
      );

  /// The label's id.
  final String id;

  /// The label's name.
  final String name;

  /// When it was created.
  final DateTime? createdAt;
}

/// An A/B study splitting traffic across its cells.
class AdStudy {
  /// Creates a study.
  const AdStudy({
    required this.id,
    required this.name,
    this.description,
    this.type,
    this.status,
    this.startAt,
    this.endAt,
  });

  /// Reads a study.
  factory AdStudy.fromJson(Map<String, dynamic> json) => AdStudy(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        description: asString(json['description']),
        type: asString(json['type']),
        status: asString(json['status']),
        startAt: asDate(json['startAt']),
        endAt: asDate(json['endAt']),
      );

  /// The study's id.
  final String id;

  /// The study's name.
  final String name;

  /// What it is testing.
  final String? description;

  /// The ad platform's study type.
  final String? type;

  /// How the ad platform reports it.
  final String? status;

  /// When it starts.
  final DateTime? startAt;

  /// When it ends.
  final DateTime? endAt;
}

/// How many iOS 14 campaigns an ad account may run at once, per app.
class IosCampaignLimits {
  /// Creates a limit row.
  const IosCampaignLimits({this.limit, this.used, this.appId});

  /// Reads a limit row.
  factory IosCampaignLimits.fromJson(Map<String, dynamic> json) =>
      IosCampaignLimits(
        limit: asInt(json['limit']),
        used: asInt(json['used']),
        appId: asString(json['appId']),
      );

  /// How many campaigns the account may run at once.
  final int? limit;

  /// How many it is running.
  final int? used;

  /// The app the limit applies to.
  final String? appId;
}

/// A window the ad platform should expect heavier spend over.
class HighDemandPeriod {
  /// Creates a period.
  const HighDemandPeriod({
    required this.id,
    this.startAt,
    this.endAt,
    this.budgetValue,
    this.budgetValueType,
  });

  /// Reads a period.
  factory HighDemandPeriod.fromJson(Map<String, dynamic> json) =>
      HighDemandPeriod(
        id: asString(json['id']) ?? '',
        startAt: asDate(json['startAt']),
        endAt: asDate(json['endAt']),
        budgetValue: asDouble(json['budgetValue']),
        budgetValueType: asString(json['budgetValueType']),
      );

  /// The period's id.
  final String id;

  /// When it starts.
  final DateTime? startAt;

  /// When it ends.
  final DateTime? endAt;

  /// The uplift expected.
  final double? budgetValue;

  /// `ABSOLUTE` or `MULTIPLIER`.
  final String? budgetValueType;
}

/// Weights one condition's conversions.
class ValueRule {
  /// Creates a rule.
  const ValueRule({this.condition, this.multiplier});

  /// Reads a rule.
  factory ValueRule.fromJson(Map<String, dynamic> json) => ValueRule(
        condition: asString(json['condition']),
        multiplier: asDouble(json['multiplier']),
      );

  /// The ad platform's own rule condition.
  final String? condition;

  /// What conversions matching it are worth.
  final double? multiplier;

  /// Writes a rule.
  Map<String, dynamic> toJson() =>
      {'condition': condition, 'multiplier': multiplier};
}

/// Weights conversions so some audiences count for more than others.
class ValueRuleSet {
  /// Creates a rule set.
  const ValueRuleSet({
    required this.id,
    required this.name,
    required this.rules,
    this.status,
  });

  /// Reads a rule set.
  factory ValueRuleSet.fromJson(Map<String, dynamic> json) => ValueRuleSet(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        rules: asModelList(json['rules'], ValueRule.fromJson),
        status: asString(json['status']),
      );

  /// The rule set's id.
  final String id;

  /// The rule set's name.
  final String name;

  /// The rules in it.
  final List<ValueRule> rules;

  /// How the ad platform reports it.
  final String? status;
}

/// One upsert or delete in a catalog batch, keyed by your own retailer id.
/// Use [CatalogProductWrite.upsert] and [CatalogProductWrite.delete].
class CatalogProductWrite {
  const CatalogProductWrite._(this._json);

  /// Adds or replaces a product. [priceMinor] is minor units of [currency].
  factory CatalogProductWrite.upsert({
    required String retailerId,
    required String name,
    required String url,
    required String imageUrl,
    required int priceMinor,
    required String currency,
    String? description,
    String? availability,
    String? condition,
    String? brand,
  }) =>
      CatalogProductWrite._(pruned({
        'op': 'upsert',
        'retailerId': retailerId,
        'name': name,
        'url': url,
        'imageUrl': imageUrl,
        'priceMinor': priceMinor,
        'currency': currency,
        'description': description,
        'availability': availability,
        'condition': condition,
        'brand': brand,
      }));

  /// Removes a product from the catalog.
  factory CatalogProductWrite.delete(String retailerId) =>
      CatalogProductWrite._({'op': 'delete', 'retailerId': retailerId});

  final Map<String, dynamic> _json;

  /// Writes the row.
  Map<String, dynamic> toJson() => _json;
}

/// One arm of an A/B study: the campaigns it tests.
class AdStudyCell {
  /// Creates a cell.
  const AdStudyCell({required this.name, required this.objectIds});

  /// The cell's name.
  final String name;

  /// The campaigns it tests.
  final List<String> objectIds;

  /// Writes the cell.
  Map<String, dynamic> toJson() => {'name': name, 'objectIds': objectIds};
}
