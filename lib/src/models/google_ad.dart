import '../json.dart';

/// A keyword on an ad group.
///
/// [id] is `<customerId>~keyword~<adGroupId>~<criterionId>`: a Google resource
/// name has slashes and cannot ride in a URL path segment, so every id here
/// carries the account it belongs to.
class GoogleKeyword {
  /// Creates a keyword.
  const GoogleKeyword({
    required this.id,
    required this.adGroupId,
    required this.text,
    required this.matchType,
    required this.status,
    this.cpcBidMinor,
    this.negative = false,
  });

  /// Reads a keyword.
  factory GoogleKeyword.fromJson(Map<String, dynamic> json) => GoogleKeyword(
        id: asString(json['id']) ?? '',
        adGroupId: asString(json['adGroupId']) ?? '',
        text: asString(json['text']) ?? '',
        matchType: asString(json['matchType']) ?? '',
        status: asString(json['status']) ?? '',
        cpcBidMinor: asInt(json['cpcBidMinor']),
        negative: asBool(json['negative']) ?? false,
      );

  /// Its object id.
  final String id;

  /// The ad group it sits on.
  final String adGroupId;

  /// The term itself.
  final String text;

  /// `EXACT`, `PHRASE` or `BROAD`.
  final String matchType;

  /// `ENABLED` or `PAUSED`.
  final String status;

  /// The account's currency, in minor units.
  final int? cpcBidMinor;

  /// Whether the keyword excludes rather than targets.
  final bool negative;
}

/// A keyword idea, or the historical metrics of one.
class GoogleKeywordIdea {
  /// Creates an idea.
  const GoogleKeywordIdea({
    required this.text,
    this.avgMonthlySearches = 0,
    this.competition,
    this.lowTopOfPageBidMinor,
    this.highTopOfPageBidMinor,
  });

  /// Reads an idea.
  factory GoogleKeywordIdea.fromJson(Map<String, dynamic> json) =>
      GoogleKeywordIdea(
        text: asString(json['text']) ?? '',
        avgMonthlySearches: asInt(json['avgMonthlySearches']) ?? 0,
        competition: asString(json['competition']),
        lowTopOfPageBidMinor: asInt(json['lowTopOfPageBidMinor']),
        highTopOfPageBidMinor: asInt(json['highTopOfPageBidMinor']),
      );

  /// The term.
  final String text;

  /// How often it is searched in a month.
  final int avgMonthlySearches;

  /// How contested it is.
  final String? competition;

  /// The low end of the top-of-page bid range, in minor units.
  final int? lowTopOfPageBidMinor;

  /// The high end of the top-of-page bid range, in minor units.
  final int? highTopOfPageBidMinor;
}

/// What someone actually searched, with the metrics it earned.
class GoogleSearchTerm {
  /// Creates a search term.
  const GoogleSearchTerm({
    required this.term,
    this.adGroupId,
    this.status,
    this.metrics = const {},
  });

  /// Reads a search term.
  factory GoogleSearchTerm.fromJson(Map<String, dynamic> json) =>
      GoogleSearchTerm(
        term: asString(json['term']) ?? '',
        adGroupId: asString(json['adGroupId']),
        status: asString(json['status']),
        metrics: asMap(json['metrics']),
      );

  /// The term as typed.
  final String term;

  /// The ad group it matched.
  final String? adGroupId;

  /// Whether it was added or excluded.
  final String? status;

  /// Impressions, clicks, spend and conversions.
  final Map<String, dynamic> metrics;
}

/// A portfolio bid strategy on the account.
class GoogleBidStrategy {
  /// Creates a bid strategy.
  const GoogleBidStrategy({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.campaignCount = 0,
  });

  /// Reads a bid strategy.
  factory GoogleBidStrategy.fromJson(Map<String, dynamic> json) =>
      GoogleBidStrategy(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        type: asString(json['type']) ?? '',
        status: asString(json['status']) ?? '',
        campaignCount: asInt(json['campaignCount']) ?? 0,
      );

  /// Its id.
  final String id;

  /// What it is called.
  final String name;

  /// Which strategy it is.
  final String type;

  /// Whether it is live.
  final String status;

  /// How many campaigns use it.
  final int campaignCount;
}

/// One slot of a campaign's ad schedule.
class GoogleAdScheduleSlot {
  /// Creates a slot.
  const GoogleAdScheduleSlot({
    required this.id,
    required this.dayOfWeek,
    this.startHour = 0,
    this.endHour = 0,
    this.bidModifier,
  });

  /// Reads a slot.
  factory GoogleAdScheduleSlot.fromJson(Map<String, dynamic> json) =>
      GoogleAdScheduleSlot(
        id: asString(json['id']) ?? '',
        dayOfWeek: asString(json['dayOfWeek']) ?? '',
        startHour: asInt(json['startHour']) ?? 0,
        endHour: asInt(json['endHour']) ?? 0,
        bidModifier: asDouble(json['bidModifier']),
      );

  /// Its criterion id.
  final String id;

  /// `MONDAY` through `SUNDAY`.
  final String dayOfWeek;

  /// When the slot opens.
  final int startHour;

  /// When the slot closes.
  final int endHour;

  /// What it does to the bid while it runs.
  final double? bidModifier;
}

/// A negative keyword list.
class GoogleSharedSet {
  /// Creates a list.
  const GoogleSharedSet({
    required this.id,
    required this.name,
    required this.type,
    this.memberCount = 0,
  });

  /// Reads a list.
  factory GoogleSharedSet.fromJson(Map<String, dynamic> json) =>
      GoogleSharedSet(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        type: asString(json['type']) ?? '',
        memberCount: asInt(json['memberCount']) ?? 0,
      );

  /// Its id.
  final String id;

  /// What it is called.
  final String name;

  /// Always `NEGATIVE_KEYWORDS` today.
  final String type;

  /// How many keywords it holds.
  final int memberCount;
}

/// A sitelink, callout or structured snippet.
class GoogleAsset {
  /// Creates an asset.
  const GoogleAsset({
    required this.id,
    required this.type,
    this.name,
    this.text,
    this.finalUrl,
  });

  /// Reads an asset.
  factory GoogleAsset.fromJson(Map<String, dynamic> json) => GoogleAsset(
        id: asString(json['id']) ?? '',
        type: asString(json['type']) ?? '',
        name: asString(json['name']),
        text: asString(json['text']),
        finalUrl: asString(json['finalUrl']),
      );

  /// Its object id.
  final String id;

  /// `SITELINK`, `CALLOUT` or `STRUCTURED_SNIPPET`.
  final String type;

  /// Its name on the account.
  final String? name;

  /// What it renders.
  final String? text;

  /// Where a sitelink sends people.
  final String? finalUrl;
}

/// Where an asset is attached; one with no links serves nowhere.
class GoogleAssetLink {
  /// Creates a link.
  const GoogleAssetLink({
    required this.id,
    required this.assetId,
    required this.level,
    required this.fieldType,
    required this.status,
    this.ownerId,
  });

  /// Reads a link.
  factory GoogleAssetLink.fromJson(Map<String, dynamic> json) =>
      GoogleAssetLink(
        id: asString(json['id']) ?? '',
        assetId: asString(json['assetId']) ?? '',
        level: asString(json['level']) ?? '',
        fieldType: asString(json['fieldType']) ?? '',
        status: asString(json['status']) ?? '',
        ownerId: asString(json['ownerId']),
      );

  /// Its id.
  final String id;

  /// The asset it places.
  final String assetId;

  /// `customer` or `campaign`.
  final String level;

  /// Where it renders.
  final String fieldType;

  /// Whether it is live.
  final String status;

  /// The campaign, when the link is on one.
  final String? ownerId;
}

/// The account's assets with the links that place them.
class GoogleAssets {
  /// Creates the pair.
  const GoogleAssets({this.assets = const [], this.links = const []});

  /// Reads the pair.
  factory GoogleAssets.fromJson(Map<String, dynamic> json) => GoogleAssets(
        assets: (json['assets'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => GoogleAsset.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        links: (json['links'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => GoogleAssetLink.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  /// The assets in the library.
  final List<GoogleAsset> assets;

  /// Where each one is attached.
  final List<GoogleAssetLink> links;
}

/// A Performance Max asset group.
class GoogleAssetGroup {
  /// Creates an asset group.
  const GoogleAssetGroup({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.status,
    this.finalUrls = const [],
  });

  /// Reads an asset group.
  factory GoogleAssetGroup.fromJson(Map<String, dynamic> json) =>
      GoogleAssetGroup(
        id: asString(json['id']) ?? '',
        campaignId: asString(json['campaignId']) ?? '',
        name: asString(json['name']) ?? '',
        status: asString(json['status']) ?? '',
        finalUrls: (json['finalUrls'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
      );

  /// Its object id.
  final String id;

  /// The Performance Max campaign it belongs to.
  final String campaignId;

  /// What it is called.
  final String name;

  /// Whether it is live.
  final String status;

  /// Where it sends people.
  final List<String> finalUrls;
}

/// A lead from Local Services Ads, read live and never stored.
class GoogleLocalServicesLead {
  /// Creates a lead.
  const GoogleLocalServicesLead({
    required this.id,
    this.category,
    this.service,
    this.contactName,
    this.phone,
    this.email,
    this.status,
    this.type,
    this.createdAt,
  });

  /// Reads a lead.
  factory GoogleLocalServicesLead.fromJson(Map<String, dynamic> json) =>
      GoogleLocalServicesLead(
        id: asString(json['id']) ?? '',
        category: asString(json['category']),
        service: asString(json['service']),
        contactName: asString(json['contactName']),
        phone: asString(json['phone']),
        email: asString(json['email']),
        status: asString(json['status']),
        type: asString(json['type']),
        createdAt: asString(json['createdAt']),
      );

  /// Its id.
  final String id;

  /// The service category it came through.
  final String? category;

  /// The service asked for.
  final String? service;

  /// Who got in touch.
  final String? contactName;

  /// Their phone number.
  final String? phone;

  /// Their email address.
  final String? email;

  /// Where the lead stands.
  final String? status;

  /// How it arrived.
  final String? type;

  /// When it arrived.
  final String? createdAt;
}

/// A conversion action on the account.
class GoogleConversionAction {
  /// Creates a conversion action.
  const GoogleConversionAction({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.type,
    this.countingType,
    this.valueMinor,
  });

  /// Reads a conversion action.
  factory GoogleConversionAction.fromJson(Map<String, dynamic> json) =>
      GoogleConversionAction(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        category: asString(json['category']) ?? '',
        status: asString(json['status']) ?? '',
        type: asString(json['type']) ?? '',
        countingType: asString(json['countingType']),
        valueMinor: asInt(json['valueMinor']),
      );

  /// Its id.
  final String id;

  /// What it is called.
  final String name;

  /// What it counts.
  final String category;

  /// Whether it is live.
  final String status;

  /// How it is recorded.
  final String type;

  /// `ONE_PER_CLICK` or `MANY_PER_CLICK`.
  final String? countingType;

  /// Its default value, in minor units.
  final int? valueMinor;
}
