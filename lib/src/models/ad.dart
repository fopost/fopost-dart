import '../json.dart';

/// What a boost or ad optimizes for.
abstract final class AdGoal {
  /// Reactions, comments and shares.
  static const String engagement = 'engagement';

  /// Clicks through to a destination.
  static const String traffic = 'traffic';

  /// Reach.
  static const String awareness = 'awareness';

  /// Video plays.
  static const String videoViews = 'video_views';
}

/// How a budget is spent.
abstract final class AdBudgetType {
  /// Per day, until paused or ended.
  static const String daily = 'daily';

  /// In total, across the whole run.
  static const String lifetime = 'lifetime';
}

/// The statuses a boost or ad can be set to.
abstract final class AdStatus {
  /// Delivering.
  static const String active = 'active';

  /// Not delivering, not spending.
  static const String paused = 'paused';
}

/// The kinds of targeting option `searchTargeting` can look up.
abstract final class TargetingType {
  /// A country.
  static const String country = 'country';

  /// A state or province.
  static const String region = 'region';

  /// A city.
  static const String city = 'city';

  /// A postal code.
  static const String zip = 'zip';

  /// A metro area.
  static const String metro = 'metro';

  /// An interest.
  static const String interest = 'interest';

  /// A behavior.
  static const String behavior = 'behavior';

  /// An income bracket.
  static const String income = 'income';
}

/// The questions an instant lead form can ask.
abstract final class LeadFormQuestion {
  /// The lead's email address.
  static const String email = 'EMAIL';

  /// The lead's full name.
  static const String fullName = 'FULL_NAME';

  /// The lead's phone number.
  static const String phone = 'PHONE';
}

/// How much a boost or ad may spend.
class AdBudget {
  /// Creates a budget. [minor] is in the ad account's currency, minor units.
  const AdBudget({required this.minor, required this.type, this.endAt});

  /// The amount, in minor units of the ad account's currency.
  final int minor;

  /// One of [AdBudgetType].
  final String type;

  /// When a lifetime budget stops.
  final DateTime? endAt;

  /// Renders the budget for a request body.
  Map<String, dynamic> toJson() => pruned({
        'minor': minor,
        'type': type,
        'endAt': endAt?.toUtc().toIso8601String(),
      });

  @override
  String toString() => 'AdBudget($minor $type)';
}

/// A place in a targeting spec, as `searchTargeting` names it.
class AdTargetingLocation {
  /// Creates a location.
  const AdTargetingLocation(
      {required this.key, required this.name, required this.type});

  /// Reads a location.
  factory AdTargetingLocation.fromJson(Map<String, dynamic> json) =>
      AdTargetingLocation(
        key: asString(json['key']) ?? '',
        name: asString(json['name']) ?? '',
        type: asString(json['type']) ?? '',
      );

  /// The platform's key for the place.
  final String key;

  /// The place's name.
  final String name;

  /// `region`, `city`, `zip` or `geo_market`.
  final String type;

  /// Renders the location for a request body.
  Map<String, dynamic> toJson() => {'key': key, 'name': name, 'type': type};

  @override
  String toString() => 'AdTargetingLocation($type, $name)';
}

/// An interest, behavior or income bracket in a targeting spec.
class AdTargetingRef {
  /// Creates a reference.
  const AdTargetingRef({required this.id, required this.name});

  /// Reads a reference.
  factory AdTargetingRef.fromJson(Map<String, dynamic> json) => AdTargetingRef(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
      );

  /// The platform's id for it.
  final String id;

  /// Its name.
  final String name;

  /// Renders the reference for a request body.
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => 'AdTargetingRef($name)';
}

/// Who a boost or ad is shown to.
class AdTargeting {
  /// Creates a targeting spec.
  const AdTargeting({
    required this.countries,
    required this.ageMin,
    required this.ageMax,
    this.gender = 'all',
    this.audienceIds = const [],
    this.locations = const [],
    this.interests = const [],
    this.behaviors = const [],
    this.income = const [],
  });

  /// Reads a targeting spec off an ad.
  factory AdTargeting.fromJson(Map<String, dynamic> json) => AdTargeting(
        countries: asStringList(json['countries']),
        ageMin: asInt(json['ageMin']) ?? 0,
        ageMax: asInt(json['ageMax']) ?? 0,
        gender: asString(json['gender']) ?? 'all',
        audienceIds: asStringList(json['audienceIds']),
        locations: asModelList(json['locations'], AdTargetingLocation.fromJson),
        interests: asModelList(json['interests'], AdTargetingRef.fromJson),
        behaviors: asModelList(json['behaviors'], AdTargetingRef.fromJson),
        income: asModelList(json['income'], AdTargetingRef.fromJson),
      );

  /// Country codes.
  final List<String> countries;

  /// Youngest age shown to.
  final int ageMin;

  /// Oldest age shown to.
  final int ageMax;

  /// `all`, `male` or `female`.
  final String gender;

  /// Saved audiences to include.
  final List<String> audienceIds;

  /// Places narrower than a country.
  final List<AdTargetingLocation> locations;

  /// Interests to match.
  final List<AdTargetingRef> interests;

  /// Behaviors to match.
  final List<AdTargetingRef> behaviors;

  /// Income brackets to match.
  final List<AdTargetingRef> income;

  /// Renders the spec for a request body.
  Map<String, dynamic> toJson() => {
        'countries': countries,
        'ageMin': ageMin,
        'ageMax': ageMax,
        'gender': gender,
        if (audienceIds.isNotEmpty) 'audienceIds': audienceIds,
        if (locations.isNotEmpty)
          'locations': locations.map((l) => l.toJson()).toList(),
        if (interests.isNotEmpty)
          'interests': interests.map((i) => i.toJson()).toList(),
        if (behaviors.isNotEmpty)
          'behaviors': behaviors.map((b) => b.toJson()).toList(),
        if (income.isNotEmpty) 'income': income.map((i) => i.toJson()).toList(),
      };

  @override
  String toString() => 'AdTargeting(${countries.join(',')}, $ageMin-$ageMax)';
}

/// Lifetime delivery numbers from an ad's last refresh.
class AdInsights {
  /// Creates insights.
  const AdInsights(
      {this.impressions = 0,
      this.reach = 0,
      this.clicks = 0,
      this.spendMinor = 0});

  /// Reads insights.
  factory AdInsights.fromJson(Map<String, dynamic> json) => AdInsights(
        impressions: asInt(json['impressions']) ?? 0,
        reach: asInt(json['reach']) ?? 0,
        clicks: asInt(json['clicks']) ?? 0,
        spendMinor: asInt(json['spendMinor']) ?? 0,
      );

  /// Times shown.
  final int impressions;

  /// People reached.
  final int reach;

  /// Clicks.
  final int clicks;

  /// Spend, in minor units of the ad account's currency.
  final int spendMinor;

  @override
  String toString() => 'AdInsights($impressions impressions)';
}

/// A boost or standalone ad created through FoPost.
class Ad {
  /// Creates an ad.
  const Ad({
    required this.id,
    required this.kind,
    required this.name,
    required this.goal,
    required this.status,
    this.workspaceId,
    this.effectiveStatus,
    this.connectionId,
    this.accountId,
    this.platform,
    this.adAccountId,
    this.sourcePostId,
    this.budgetMinor,
    this.budgetType,
    this.currency,
    this.endAt,
    this.targeting,
    this.creative,
    this.insights,
    this.insightsAt,
    this.lastError,
    this.createdAt,
  });

  /// Reads an ad.
  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
        id: asString(json['id']) ?? '',
        kind: asString(json['kind']) ?? '',
        name: asString(json['name']) ?? '',
        goal: asString(json['goal']) ?? '',
        status: asString(json['status']) ?? '',
        workspaceId: asString(json['workspaceId']),
        effectiveStatus: asString(json['effectiveStatus']),
        connectionId: asString(json['connectionId']),
        accountId: asString(json['accountId']),
        platform: asString(json['platform']),
        adAccountId: asString(json['adAccountId']),
        sourcePostId: asString(json['sourcePostId']),
        budgetMinor: asInt(json['budgetMinor']),
        budgetType: asString(json['budgetType']),
        currency: asString(json['currency']),
        endAt: asDate(json['endAt']),
        targeting: json['targeting'] is Map
            ? AdTargeting.fromJson(asMap(json['targeting']))
            : null,
        creative: asMapOrNull(json['creative']),
        insights: json['insights'] is Map
            ? AdInsights.fromJson(asMap(json['insights']))
            : null,
        insightsAt: asDate(json['insightsAt']),
        lastError: asString(json['lastError']),
        createdAt: asDate(json['createdAt']),
      );

  /// The ad's id.
  final String id;

  /// `boost` or `ad`.
  final String kind;

  /// The ad's name.
  final String name;

  /// One of [AdGoal].
  final String goal;

  /// One of [AdStatus], as set through FoPost.
  final String status;

  /// The status the platform reports, which can differ while under review.
  final String? effectiveStatus;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// The ad connection it runs through.
  final String? connectionId;

  /// The connected account a boost promotes, for a boost.
  final String? accountId;

  /// The network it runs on.
  final String? platform;

  /// The ad account it spends from.
  final String? adAccountId;

  /// The FoPost post a boost promotes, for a boost.
  final String? sourcePostId;

  /// The budget, in minor units of [currency].
  final int? budgetMinor;

  /// One of [AdBudgetType].
  final String? budgetType;

  /// The ad account's currency.
  final String? currency;

  /// When a lifetime budget stops.
  final DateTime? endAt;

  /// Who it is shown to.
  final AdTargeting? targeting;

  /// The creative, for a standalone ad.
  final Map<String, dynamic>? creative;

  /// Numbers from the last refresh.
  final AdInsights? insights;

  /// When [insights] were last read.
  final DateTime? insightsAt;

  /// The last error the platform reported.
  final String? lastError;

  /// When it was created.
  final DateTime? createdAt;

  @override
  String toString() => 'Ad($id, $kind, $status)';
}

/// An ad on a connected ad account that was made outside FoPost.
class ExternalAd {
  /// Creates an external ad.
  const ExternalAd({
    required this.id,
    required this.name,
    this.effectiveStatus,
    this.campaignId,
    this.campaignName,
    this.objective,
    this.budgetMinor,
    this.budgetType,
    this.endAt,
    this.createdAt,
    this.connectionId,
    this.adAccountId,
    this.currency,
    this.workspaceId,
  });

  /// Reads an external ad.
  factory ExternalAd.fromJson(Map<String, dynamic> json) => ExternalAd(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        effectiveStatus: asString(json['effectiveStatus']),
        campaignId: asString(json['campaignId']),
        campaignName: asString(json['campaignName']),
        objective: asString(json['objective']),
        budgetMinor: asInt(json['budgetMinor']),
        budgetType: asString(json['budgetType']),
        endAt: asDate(json['endAt']),
        createdAt: asDate(json['createdAt']),
        connectionId: asString(json['connectionId']),
        adAccountId: asString(json['adAccountId']),
        currency: asString(json['currency']),
        workspaceId: asString(json['workspaceId']),
      );

  /// The ad's id on the platform.
  final String id;

  /// The ad's name.
  final String name;

  /// The status the platform reports.
  final String? effectiveStatus;

  /// The campaign it belongs to.
  final String? campaignId;

  /// The campaign's name.
  final String? campaignName;

  /// The campaign's objective.
  final String? objective;

  /// The budget, in minor units of [currency].
  final int? budgetMinor;

  /// One of [AdBudgetType].
  final String? budgetType;

  /// When a lifetime budget stops.
  final DateTime? endAt;

  /// When it was created on the platform.
  final DateTime? createdAt;

  /// The ad connection it was read through.
  final String? connectionId;

  /// The ad account it spends from.
  final String? adAccountId;

  /// The ad account's currency.
  final String? currency;

  /// The workspace the connection belongs to.
  final String? workspaceId;

  @override
  String toString() => 'ExternalAd($id, $name)';
}

/// A grant to an ads platform.
class AdConnection {
  /// Creates a connection.
  const AdConnection({
    required this.id,
    required this.name,
    this.provider,
    this.authType,
    this.businessId,
    this.createdAt,
    this.workspaceId,
  });

  /// Reads a connection.
  factory AdConnection.fromJson(Map<String, dynamic> json) => AdConnection(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        provider: asString(json['provider']),
        authType: asString(json['authType']),
        businessId: asString(json['businessId']),
        createdAt: asDate(json['createdAt']),
        workspaceId: asString(json['workspaceId']),
      );

  /// The connection's id.
  final String id;

  /// The connection's name.
  final String name;

  /// The ads platform.
  final String? provider;

  /// How it was authorized, e.g. `business` or `user`.
  final String? authType;

  /// The business the grant belongs to, when there is one.
  final String? businessId;

  /// When it was connected.
  final DateTime? createdAt;

  /// The workspace it belongs to.
  final String? workspaceId;

  @override
  String toString() => 'AdConnection($id, $name)';
}

/// An ad account a connection can spend from.
class AdAccountRef {
  /// Creates a reference.
  const AdAccountRef(
      {required this.id, required this.name, this.currency, this.status});

  /// Reads a reference.
  factory AdAccountRef.fromJson(Map<String, dynamic> json) => AdAccountRef(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        currency: asString(json['currency']),
        status: asInt(json['status']),
      );

  /// The ad account's id.
  final String id;

  /// The ad account's name.
  final String name;

  /// The ad account's currency.
  final String? currency;

  /// The platform's numeric account status.
  final int? status;

  @override
  String toString() => 'AdAccountRef($id, $name)';
}

/// A Page a connection can publish ads as.
class AdPageRef {
  /// Creates a reference.
  const AdPageRef({required this.id, required this.name, this.instagramUserId});

  /// Reads a reference.
  factory AdPageRef.fromJson(Map<String, dynamic> json) => AdPageRef(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        instagramUserId: asString(json['instagramUserId']),
      );

  /// The Page's id.
  final String id;

  /// The Page's name.
  final String name;

  /// The Instagram account linked to the Page, when there is one.
  final String? instagramUserId;

  @override
  String toString() => 'AdPageRef($id, $name)';
}

/// A connection with the ad accounts and Pages its grant reaches.
class AdSource {
  /// Creates a source.
  const AdSource({
    required this.connectionId,
    required this.name,
    this.workspaceId,
    this.adAccounts = const [],
    this.pages = const [],
    this.error,
  });

  /// Reads a source.
  factory AdSource.fromJson(Map<String, dynamic> json) => AdSource(
        connectionId: asString(json['connectionId']) ?? '',
        name: asString(json['name']) ?? '',
        workspaceId: asString(json['workspaceId']),
        adAccounts: asModelList(json['adAccounts'], AdAccountRef.fromJson),
        pages: asModelList(json['pages'], AdPageRef.fromJson),
        error: asString(json['error']),
      );

  /// The connection.
  final String connectionId;

  /// The connection's name.
  final String name;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// Ad accounts the grant reaches.
  final List<AdAccountRef> adAccounts;

  /// Pages the grant reaches.
  final List<AdPageRef> pages;

  /// Why the platform could not be read, when it could not.
  final String? error;

  @override
  String toString() => 'AdSource($connectionId, $name)';
}

/// One live delivery of a boostable post.
class BoostableDelivery {
  /// Creates a delivery.
  const BoostableDelivery({
    required this.accountId,
    required this.platform,
    required this.username,
    this.externalUrl,
    this.postedAt,
  });

  /// Reads a delivery.
  factory BoostableDelivery.fromJson(Map<String, dynamic> json) =>
      BoostableDelivery(
        accountId: asString(json['accountId']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']) ?? '',
        externalUrl: asString(json['externalUrl']),
        postedAt: asDate(json['postedAt']),
      );

  /// The account it went live on.
  final String accountId;

  /// The network.
  final String platform;

  /// The account's handle.
  final String username;

  /// The post's URL on the platform.
  final String? externalUrl;

  /// When it went live.
  final DateTime? postedAt;

  @override
  String toString() => 'BoostableDelivery($platform, $username)';
}

/// A published post that can be boosted.
class BoostablePost {
  /// Creates a boostable post.
  const BoostablePost({
    required this.id,
    this.workspaceId,
    this.text,
    this.thumbnailUrl,
    this.deliveries = const [],
  });

  /// Reads a boostable post.
  factory BoostablePost.fromJson(Map<String, dynamic> json) => BoostablePost(
        id: asString(json['id']) ?? '',
        workspaceId: asString(json['workspaceId']),
        text: asString(json['text']),
        thumbnailUrl: asString(json['thumbnailUrl']),
        deliveries: asModelList(json['deliveries'], BoostableDelivery.fromJson),
      );

  /// The FoPost post id.
  final String id;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// The post's text.
  final String? text;

  /// A thumbnail of the post's media.
  final String? thumbnailUrl;

  /// Where it is live; a boost targets one of these.
  final List<BoostableDelivery> deliveries;

  @override
  String toString() => 'BoostablePost($id)';
}

/// A saved audience on an ad account.
class Audience {
  /// Creates an audience.
  const Audience({
    required this.id,
    required this.name,
    this.subtype,
    this.description,
    this.sizeLower,
    this.sizeUpper,
    this.deliveryStatus,
    this.createdAt,
  });

  /// Reads an audience.
  factory Audience.fromJson(Map<String, dynamic> json) => Audience(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        subtype: asString(json['subtype']),
        description: asString(json['description']),
        sizeLower: asInt(json['sizeLower']),
        sizeUpper: asInt(json['sizeUpper']),
        deliveryStatus: asString(json['deliveryStatus']),
        createdAt: asString(json['createdAt']),
      );

  /// The audience's id.
  final String id;

  /// The audience's name.
  final String name;

  /// `CUSTOM`, `LOOKALIKE` or `WEBSITE`.
  final String? subtype;

  /// The audience's description.
  final String? description;

  /// The estimated size, lower bound.
  final int? sizeLower;

  /// The estimated size, upper bound.
  final int? sizeUpper;

  /// Whether the platform can deliver to it.
  final String? deliveryStatus;

  /// When it was created, as the platform formats it.
  final String? createdAt;

  @override
  String toString() => 'Audience($id, $name)';
}

/// A tracking pixel on an ad account.
class AdPixel {
  /// Creates a pixel.
  const AdPixel({required this.id, required this.name});

  /// Reads a pixel.
  factory AdPixel.fromJson(Map<String, dynamic> json) => AdPixel(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
      );

  /// The pixel's id.
  final String id;

  /// The pixel's name.
  final String name;

  @override
  String toString() => 'AdPixel($id, $name)';
}

/// The audiences and pixels on an ad account.
class AudiencesResult {
  /// Creates a result.
  const AudiencesResult(
      {this.audiences = const [], this.pixels = const [], this.workspaceId});

  /// Reads a result.
  factory AudiencesResult.fromJson(Map<String, dynamic> json) =>
      AudiencesResult(
        audiences: asModelList(json['audiences'], Audience.fromJson),
        pixels: asModelList(json['pixels'], AdPixel.fromJson),
        workspaceId: asString(json['workspaceId']),
      );

  /// Saved audiences.
  final List<Audience> audiences;

  /// Pixels a website audience can be built from.
  final List<AdPixel> pixels;

  /// The workspace the connection belongs to.
  final String? workspaceId;

  @override
  String toString() => 'AudiencesResult(${audiences.length} audiences)';
}

/// How to build a saved audience.
///
/// Use [AudienceSpec.custom], [AudienceSpec.lookalike] or
/// [AudienceSpec.website].
class AudienceSpec {
  AudienceSpec._(this._body);

  /// A customer list, matched by email.
  AudienceSpec.custom({List<String>? emails})
      : this._({'subtype': 'CUSTOM', 'emails': emails});

  /// People who resemble [originAudienceId] in [country].
  ///
  /// [ratio] is the share of the country to reach, from 0.01 to 0.2.
  AudienceSpec.lookalike({
    required String originAudienceId,
    required String country,
    double? ratio,
  }) : this._({
          'subtype': 'LOOKALIKE',
          'originAudienceId': originAudienceId,
          'country': country,
          'ratio': ratio,
        });

  /// Visitors a pixel saw in the last [retentionDays].
  AudienceSpec.website({
    required String pixelId,
    int? retentionDays,
    String? urlContains,
  }) : this._({
          'subtype': 'WEBSITE',
          'pixelId': pixelId,
          'retentionDays': retentionDays,
          'urlContains': urlContains,
        });

  final Map<String, dynamic> _body;

  /// Renders the spec for a request body.
  Map<String, dynamic> toJson() => pruned(Map<String, dynamic>.of(_body));

  @override
  String toString() => 'AudienceSpec(${_body['subtype']})';
}

/// What creating an audience returned.
class AudienceCreated {
  /// Creates a result.
  const AudienceCreated({required this.id, this.added});

  /// Reads a result.
  factory AudienceCreated.fromJson(Map<String, dynamic> json) =>
      AudienceCreated(
        id: asString(json['id']) ?? '',
        added: asInt(json['added']),
      );

  /// The new audience's id.
  final String id;

  /// How many emails the platform accepted, for a custom audience.
  final int? added;

  @override
  String toString() => 'AudienceCreated($id)';
}

/// A location, interest, behavior or income bracket, as the platform names it.
class TargetingOption {
  /// Creates an option.
  const TargetingOption({required this.id, required this.name, this.detail});

  /// Reads an option.
  factory TargetingOption.fromJson(Map<String, dynamic> json) =>
      TargetingOption(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        detail: asString(json['detail']),
      );

  /// The platform's id or key for it.
  final String id;

  /// Its name.
  final String name;

  /// Disambiguating detail, e.g. the region a city sits in.
  final String? detail;

  @override
  String toString() => 'TargetingOption($id, $name)';
}

/// An instant lead form on a Page.
class LeadForm {
  /// Creates a form.
  const LeadForm({
    required this.id,
    required this.name,
    this.status,
    this.leadsCount = 0,
    this.createdAt,
    this.questions = const [],
  });

  /// Reads a form.
  factory LeadForm.fromJson(Map<String, dynamic> json) => LeadForm(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        status: asString(json['status']),
        leadsCount: asInt(json['leadsCount']) ?? 0,
        createdAt: asString(json['createdAt']),
        questions: asStringList(json['questions']),
      );

  /// The form's id.
  final String id;

  /// The form's name.
  final String name;

  /// The status the platform reports.
  final String? status;

  /// How many leads it has collected.
  final int leadsCount;

  /// When it was created, as the platform formats it.
  final String? createdAt;

  /// The questions it asks, from [LeadFormQuestion].
  final List<String> questions;

  @override
  String toString() => 'LeadForm($id, $name)';
}

/// A connection's Page and the lead forms on it.
class LeadFormSource {
  /// Creates a source.
  const LeadFormSource({
    required this.connectionId,
    this.connectionName,
    this.pageId,
    this.pageName,
    this.forms = const [],
    this.error,
    this.workspaceId,
  });

  /// Reads a source.
  factory LeadFormSource.fromJson(Map<String, dynamic> json) => LeadFormSource(
        connectionId: asString(json['connectionId']) ?? '',
        connectionName: asString(json['connectionName']),
        pageId: asString(json['pageId']),
        pageName: asString(json['pageName']),
        forms: asModelList(json['forms'], LeadForm.fromJson),
        error: asString(json['error']),
        workspaceId: asString(json['workspaceId']),
      );

  /// The connection.
  final String connectionId;

  /// The connection's name.
  final String? connectionName;

  /// The Page the forms live on.
  final String? pageId;

  /// The Page's name.
  final String? pageName;

  /// The forms on the Page.
  final List<LeadForm> forms;

  /// Why the platform could not be read, when it could not.
  final String? error;

  /// The workspace the connection belongs to.
  final String? workspaceId;

  @override
  String toString() => 'LeadFormSource($connectionId, ${forms.length} forms)';
}

/// One answer on a lead.
class LeadField {
  /// Creates a field.
  const LeadField({required this.name, this.values = const []});

  /// Reads a field.
  factory LeadField.fromJson(Map<String, dynamic> json) => LeadField(
        name: asString(json['name']) ?? '',
        values: asStringList(json['values']),
      );

  /// The question's name.
  final String name;

  /// What the lead answered.
  final List<String> values;

  @override
  String toString() => 'LeadField($name)';
}

/// A lead a form collected.
class Lead {
  /// Creates a lead.
  const Lead({
    required this.id,
    this.createdAt,
    this.fields = const [],
    this.adName,
    this.campaignName,
    this.platform,
    this.isOrganic,
  });

  /// Reads a lead.
  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: asString(json['id']) ?? '',
        createdAt: asString(json['createdAt']),
        fields: asModelList(json['fields'], LeadField.fromJson),
        adName: asString(json['adName']),
        campaignName: asString(json['campaignName']),
        platform: asString(json['platform']),
        isOrganic: asBool(json['isOrganic']),
      );

  /// The lead's id.
  final String id;

  /// When it was submitted, as the platform formats it.
  final String? createdAt;

  /// The answers.
  final List<LeadField> fields;

  /// The ad it came through.
  final String? adName;

  /// The campaign it came through.
  final String? campaignName;

  /// The network it came from.
  final String? platform;

  /// Whether it came from an unpaid placement.
  final bool? isOrganic;

  @override
  String toString() => 'Lead($id)';
}

/// One page of leads.
class LeadsPage {
  /// Creates a page.
  const LeadsPage({this.leads = const [], this.nextCursor});

  /// Reads a page.
  factory LeadsPage.fromJson(Map<String, dynamic> json) => LeadsPage(
        leads: asModelList(json['leads'], Lead.fromJson),
        nextCursor: asString(json['nextCursor']),
      );

  /// The leads on this page.
  final List<Lead> leads;

  /// Pass back as `after` for the next page; null on the last.
  final String? nextCursor;

  /// Whether another page follows this one.
  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  @override
  String toString() => 'LeadsPage(${leads.length})';
}

/// The levels of the campaign tree `bulkSetStatus` can act on.
abstract final class AdObjectLevel {
  /// A campaign.
  static const String campaign = 'campaign';

  /// An ad set.
  static const String adSet = 'ad_set';

  /// An ad inside an ad set.
  static const String ad = 'ad';
}

/// How an insights report can be split.
abstract final class AdInsightsBreakdown {
  /// By age bracket.
  static const String age = 'age';

  /// By gender.
  static const String gender = 'gender';

  /// By placement.
  static const String placement = 'placement';

  /// By country.
  static const String country = 'country';
}

/// The creative formats `createCreative` builds.
abstract final class AdCreativeFormat {
  /// A single image.
  static const String image = 'image';

  /// A single video.
  static const String video = 'video';

  /// Two to ten cards.
  static const String carousel = 'carousel';
}

/// An ad inside an ad set, by the platform's id. Read live, never stored.
class NetworkAd {
  /// Creates an ad.
  const NetworkAd({
    required this.id,
    required this.name,
    required this.status,
    this.campaignId,
    this.adSetId,
    this.creativeId,
    this.effectiveStatus,
    this.createdAt,
  });

  /// Reads an ad.
  factory NetworkAd.fromJson(Map<String, dynamic> json) => NetworkAd(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        status: asString(json['status']) ?? '',
        campaignId: asString(json['campaignId']),
        adSetId: asString(json['adSetId']),
        creativeId: asString(json['creativeId']),
        effectiveStatus: asString(json['effectiveStatus']),
        createdAt: asString(json['createdAt']),
      );

  /// The platform's ad id.
  final String id;

  /// The ad's name.
  final String name;

  /// The status set on the platform.
  final String status;

  /// The campaign it sits in.
  final String? campaignId;

  /// The ad set it sits in.
  final String? adSetId;

  /// The creative it shows.
  final String? creativeId;

  /// The status the platform reports.
  final String? effectiveStatus;

  /// When it was created, as the platform formats it.
  final String? createdAt;

  @override
  String toString() => 'NetworkAd($id, $name)';
}

/// An ad set, by the platform's id. Read live, never stored.
class AdSet {
  /// Creates an ad set.
  const AdSet({
    required this.id,
    required this.name,
    required this.status,
    this.campaignId,
    this.effectiveStatus,
    this.budgetMinor,
    this.budgetType,
    this.endAt,
    this.optimizationGoal,
    this.createdAt,
    this.ads = const [],
  });

  /// Reads an ad set.
  factory AdSet.fromJson(Map<String, dynamic> json) => AdSet(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        status: asString(json['status']) ?? '',
        campaignId: asString(json['campaignId']),
        effectiveStatus: asString(json['effectiveStatus']),
        budgetMinor: asInt(json['budgetMinor']),
        budgetType: asString(json['budgetType']),
        endAt: asString(json['endAt']),
        optimizationGoal: asString(json['optimizationGoal']),
        createdAt: asString(json['createdAt']),
        ads: asModelList(json['ads'], NetworkAd.fromJson),
      );

  /// The platform's ad set id.
  final String id;

  /// The ad set's name.
  final String name;

  /// The status set on the platform.
  final String status;

  /// The campaign it sits in.
  final String? campaignId;

  /// The status the platform reports.
  final String? effectiveStatus;

  /// The budget, in minor units of the ad account's currency.
  final int? budgetMinor;

  /// One of [AdBudgetType].
  final String? budgetType;

  /// When a lifetime budget stops, as the platform formats it.
  final String? endAt;

  /// What the platform optimizes delivery for.
  final String? optimizationGoal;

  /// When it was created, as the platform formats it.
  final String? createdAt;

  /// Its ads; filled only in `accountTree`.
  final List<NetworkAd> ads;

  @override
  String toString() => 'AdSet($id, $name)';
}

/// A campaign, by the platform's id. Read live, never stored.
class AdCampaign {
  /// Creates a campaign.
  const AdCampaign({
    required this.id,
    required this.name,
    required this.status,
    this.effectiveStatus,
    this.objective,
    this.budgetMinor,
    this.budgetType,
    this.createdAt,
    this.adSets = const [],
  });

  /// Reads a campaign.
  factory AdCampaign.fromJson(Map<String, dynamic> json) => AdCampaign(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        status: asString(json['status']) ?? '',
        effectiveStatus: asString(json['effectiveStatus']),
        objective: asString(json['objective']),
        budgetMinor: asInt(json['budgetMinor']),
        budgetType: asString(json['budgetType']),
        createdAt: asString(json['createdAt']),
        adSets: asModelList(json['adSets'], AdSet.fromJson),
      );

  /// The platform's campaign id.
  final String id;

  /// The campaign's name.
  final String name;

  /// `ACTIVE`, `PAUSED`, `DELETED` or `ARCHIVED`.
  final String status;

  /// The status the platform reports.
  final String? effectiveStatus;

  /// The campaign's objective.
  final String? objective;

  /// The budget in minor units; null when it lives on the ad sets.
  final int? budgetMinor;

  /// One of [AdBudgetType].
  final String? budgetType;

  /// When it was created, as the platform formats it.
  final String? createdAt;

  /// Its ad sets; filled only in `accountTree`.
  final List<AdSet> adSets;

  @override
  String toString() => 'AdCampaign($id, $name)';
}

/// An ad account's campaigns, each with its ad sets and their ads.
class AdAccountTree {
  /// Creates a tree.
  const AdAccountTree({
    required this.adAccountId,
    this.currency,
    this.workspaceId,
    this.campaigns = const [],
  });

  /// Reads a tree.
  factory AdAccountTree.fromJson(Map<String, dynamic> json) => AdAccountTree(
        adAccountId: asString(json['adAccountId']) ?? '',
        currency: asString(json['currency']),
        workspaceId: asString(json['workspaceId']),
        campaigns: asModelList(json['campaigns'], AdCampaign.fromJson),
      );

  /// The ad account.
  final String adAccountId;

  /// The ad account's currency.
  final String? currency;

  /// The workspace the connection belongs to.
  final String? workspaceId;

  /// The campaigns.
  final List<AdCampaign> campaigns;

  @override
  String toString() => 'AdAccountTree($adAccountId, ${campaigns.length})';
}

/// A campaign, ad set or ad named in `bulkSetStatus`.
class AdObjectRef {
  /// Creates a reference. [level] is one of [AdObjectLevel].
  const AdObjectRef({required this.id, required this.level});

  /// The platform's id.
  final String id;

  /// One of [AdObjectLevel].
  final String level;

  /// Renders the reference for a request body.
  Map<String, dynamic> toJson() => {'id': id, 'level': level};

  @override
  String toString() => 'AdObjectRef($level, $id)';
}

/// What happened to one object in `bulkSetStatus`.
class BulkAdStatusResult {
  /// Creates a result.
  const BulkAdStatusResult(
      {required this.id, required this.level, required this.ok, this.error});

  /// Reads a result.
  factory BulkAdStatusResult.fromJson(Map<String, dynamic> json) =>
      BulkAdStatusResult(
        id: asString(json['id']) ?? '',
        level: asString(json['level']) ?? '',
        ok: asBool(json['ok']) ?? false,
        error: asString(json['error']),
      );

  /// The platform's id.
  final String id;

  /// One of [AdObjectLevel].
  final String level;

  /// Whether the status was set.
  final bool ok;

  /// Why it was not, when it was not.
  final String? error;

  @override
  String toString() => 'BulkAdStatusResult($id, $ok)';
}

/// A creative in an ad account's library.
class AdCreative {
  /// Creates a creative.
  const AdCreative({
    required this.id,
    required this.name,
    required this.format,
    this.status,
    this.title,
    this.body,
    this.link,
    this.thumbnailUrl,
    this.callToAction,
    this.urlTags,
  });

  /// Reads a creative.
  factory AdCreative.fromJson(Map<String, dynamic> json) => AdCreative(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        format: asString(json['format']) ?? '',
        status: asString(json['status']),
        title: asString(json['title']),
        body: asString(json['body']),
        link: asString(json['link']),
        thumbnailUrl: asString(json['thumbnailUrl']),
        callToAction: asString(json['callToAction']),
        urlTags: asString(json['urlTags']),
      );

  /// The creative's id.
  final String id;

  /// The creative's name.
  final String name;

  /// `image`, `video`, `carousel`, `post` or `other`.
  final String format;

  /// The status the platform reports.
  final String? status;

  /// The headline.
  final String? title;

  /// The primary text.
  final String? body;

  /// Where it links to.
  final String? link;

  /// A thumbnail of its media.
  final String? thumbnailUrl;

  /// The button, e.g. `LEARN_MORE`.
  final String? callToAction;

  /// The query string appended to every link.
  final String? urlTags;

  @override
  String toString() => 'AdCreative($id, $format)';
}

/// The creatives on an ad account.
class AdCreativesResult {
  /// Creates a result.
  const AdCreativesResult({this.creatives = const [], this.workspaceId});

  /// Reads a result.
  factory AdCreativesResult.fromJson(Map<String, dynamic> json) =>
      AdCreativesResult(
        creatives: asModelList(json['creatives'], AdCreative.fromJson),
        workspaceId: asString(json['workspaceId']),
      );

  /// The creatives.
  final List<AdCreative> creatives;

  /// The workspace the connection belongs to.
  final String? workspaceId;

  @override
  String toString() => 'AdCreativesResult(${creatives.length})';
}

/// One card of a carousel creative.
class AdCreativeCard {
  /// Creates a card. [mediaUrl] is a media library image.
  const AdCreativeCard({
    required this.mediaUrl,
    this.destinationUrl,
    this.headline,
    this.description,
  });

  /// A media library image.
  final String mediaUrl;

  /// Where the card links to.
  final String? destinationUrl;

  /// The card's headline.
  final String? headline;

  /// The card's description.
  final String? description;

  /// Renders the card for a request body.
  Map<String, dynamic> toJson() => pruned({
        'mediaUrl': mediaUrl,
        'destinationUrl': destinationUrl,
        'headline': headline,
        'description': description,
      });

  @override
  String toString() => 'AdCreativeCard($mediaUrl)';
}

/// How many people a targeting spec could reach.
class ReachEstimate {
  /// Creates an estimate.
  const ReachEstimate({this.lower, this.upper, this.ready = false});

  /// Reads an estimate.
  factory ReachEstimate.fromJson(Map<String, dynamic> json) => ReachEstimate(
        lower: asInt(json['lower']),
        upper: asInt(json['upper']),
        ready: asBool(json['ready']) ?? false,
      );

  /// The lower bound.
  final int? lower;

  /// The upper bound.
  final int? upper;

  /// False while the platform is still estimating.
  final bool ready;

  @override
  String toString() => 'ReachEstimate($lower-$upper)';
}

/// Delivery numbers over a date range.
class InsightsMetrics {
  /// Creates metrics.
  const InsightsMetrics({
    this.impressions = 0,
    this.reach = 0,
    this.clicks = 0,
    this.spendMinor = 0,
    this.ctr = 0,
    this.leads = 0,
  });

  /// Reads metrics.
  factory InsightsMetrics.fromJson(Map<String, dynamic> json) =>
      InsightsMetrics(
        impressions: asInt(json['impressions']) ?? 0,
        reach: asInt(json['reach']) ?? 0,
        clicks: asInt(json['clicks']) ?? 0,
        spendMinor: asInt(json['spendMinor']) ?? 0,
        ctr: asDouble(json['ctr']) ?? 0,
        leads: asInt(json['leads']) ?? 0,
      );

  /// Times shown.
  final int impressions;

  /// People reached.
  final int reach;

  /// Clicks.
  final int clicks;

  /// Spend, in minor units of the ad account's currency.
  final int spendMinor;

  /// Clicks per impression, as a percentage.
  final double ctr;

  /// Leads collected.
  final int leads;

  @override
  String toString() => 'InsightsMetrics($impressions impressions)';
}

/// One slice of a broken-down report, or one day of a daily one.
class InsightsRow {
  /// Creates a row.
  const InsightsRow({required this.key, required this.metrics});

  /// Reads a row; [keyField] is `key` for a breakdown, `date` for a day.
  factory InsightsRow.fromJson(Map<String, dynamic> json, String keyField) =>
      InsightsRow(
        key: asString(json[keyField]) ?? '',
        metrics: InsightsMetrics.fromJson(asMap(json['metrics'])),
      );

  /// The slice, e.g. `25-34`, or the day as `YYYY-MM-DD`.
  final String key;

  /// The numbers for it.
  final InsightsMetrics metrics;

  @override
  String toString() => 'InsightsRow($key)';
}

/// Insights for one campaign, ad set or ad over a date range.
class AdInsightsReport {
  /// Creates a report.
  const AdInsightsReport({
    required this.objectId,
    required this.since,
    required this.until,
    this.currency,
    this.breakdownBy,
    this.totals,
    this.breakdown = const [],
    this.timeline = const [],
  });

  /// Reads a report.
  factory AdInsightsReport.fromJson(Map<String, dynamic> json) =>
      AdInsightsReport(
        objectId: asString(json['objectId']) ?? '',
        since: asString(json['since']) ?? '',
        until: asString(json['until']) ?? '',
        currency: asString(json['currency']),
        breakdownBy: asString(json['breakdownBy']),
        totals: json['totals'] is Map
            ? InsightsMetrics.fromJson(asMap(json['totals']))
            : null,
        breakdown: asModelList(
            json['breakdown'], (row) => InsightsRow.fromJson(row, 'key')),
        timeline: asModelList(
            json['timeline'], (row) => InsightsRow.fromJson(row, 'date')),
      );

  /// The object the report is for.
  final String objectId;

  /// The first day, `YYYY-MM-DD`.
  final String since;

  /// The last day, `YYYY-MM-DD`.
  final String until;

  /// The ad account's currency.
  final String? currency;

  /// One of [AdInsightsBreakdown], when the report is split.
  final String? breakdownBy;

  /// The totals; null when nothing was delivered.
  final InsightsMetrics? totals;

  /// One row per slice, when the report is split.
  final List<InsightsRow> breakdown;

  /// One row per day, when asked for daily.
  final List<InsightsRow> timeline;

  @override
  String toString() => 'AdInsightsReport($objectId, $since..$until)';
}

/// An instant lead form with its settings.
class LeadFormDetail {
  /// Creates a form.
  const LeadFormDetail({
    required this.id,
    required this.name,
    this.status,
    this.leadsCount = 0,
    this.createdAt,
    this.questions = const [],
    this.pageId,
    this.privacyPolicyUrl,
    this.locale,
  });

  /// Reads a form.
  factory LeadFormDetail.fromJson(Map<String, dynamic> json) => LeadFormDetail(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        status: asString(json['status']),
        leadsCount: asInt(json['leadsCount']) ?? 0,
        createdAt: asString(json['createdAt']),
        questions: asStringList(json['questions']),
        pageId: asString(json['pageId']),
        privacyPolicyUrl: asString(json['privacyPolicyUrl']),
        locale: asString(json['locale']),
      );

  /// The form's id.
  final String id;

  /// The form's name.
  final String name;

  /// The status the platform reports.
  final String? status;

  /// How many leads it has collected.
  final int leadsCount;

  /// When it was created, as the platform formats it.
  final String? createdAt;

  /// The questions it asks.
  final List<String> questions;

  /// The Page it lives on.
  final String? pageId;

  /// The privacy policy it links to.
  final String? privacyPolicyUrl;

  /// The form's locale.
  final String? locale;

  @override
  String toString() => 'LeadFormDetail($id, $name)';
}

/// A lead stored from a subscribed Page.
class FeedLead {
  /// Creates a lead.
  const FeedLead({
    required this.id,
    required this.leadId,
    this.connectionId,
    this.pageId,
    this.formId,
    this.adId,
    this.adName,
    this.campaignName,
    this.platform,
    this.isOrganic,
    this.fields = const [],
    this.submittedAt,
    this.workspaceId,
  });

  /// Reads a lead.
  factory FeedLead.fromJson(Map<String, dynamic> json) => FeedLead(
        id: asString(json['id']) ?? '',
        leadId: asString(json['leadId']) ?? '',
        connectionId: asString(json['connectionId']),
        pageId: asString(json['pageId']),
        formId: asString(json['formId']),
        adId: asString(json['adId']),
        adName: asString(json['adName']),
        campaignName: asString(json['campaignName']),
        platform: asString(json['platform']),
        isOrganic: asBool(json['isOrganic']),
        fields: asModelList(json['fields'], LeadField.fromJson),
        submittedAt: asDate(json['submittedAt']),
        workspaceId: asString(json['workspaceId']),
      );

  /// FoPost's id for the stored lead.
  final String id;

  /// The platform's lead id.
  final String leadId;

  /// The ad connection it arrived through.
  final String? connectionId;

  /// The Page it came from.
  final String? pageId;

  /// The form it came from.
  final String? formId;

  /// The ad it came through.
  final String? adId;

  /// The ad's name.
  final String? adName;

  /// The campaign's name.
  final String? campaignName;

  /// The network it came from.
  final String? platform;

  /// Whether it came from an unpaid placement.
  final bool? isOrganic;

  /// The answers.
  final List<LeadField> fields;

  /// When it was submitted.
  final DateTime? submittedAt;

  /// The workspace it belongs to.
  final String? workspaceId;

  @override
  String toString() => 'FeedLead($id)';
}

/// One page of the stored leads feed.
class LeadsFeedPage {
  /// Creates a page.
  const LeadsFeedPage({this.leads = const [], this.nextCursor});

  /// Reads a page.
  factory LeadsFeedPage.fromJson(Map<String, dynamic> json) => LeadsFeedPage(
        leads: asModelList(json['leads'], FeedLead.fromJson),
        nextCursor: asString(json['nextCursor']),
      );

  /// The leads on this page.
  final List<FeedLead> leads;

  /// Pass back as `cursor` for the next page; null on the last.
  final String? nextCursor;

  /// Whether another page follows this one.
  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  @override
  String toString() => 'LeadsFeedPage(${leads.length})';
}

/// A Page whose leads are stored into the feed as they arrive.
class LeadPage {
  /// Creates a subscribed Page.
  const LeadPage({
    required this.pageId,
    this.connectionId,
    this.pageName,
    this.createdAt,
    this.workspaceId,
  });

  /// Reads a subscribed Page.
  factory LeadPage.fromJson(Map<String, dynamic> json) => LeadPage(
        pageId: asString(json['pageId']) ?? '',
        connectionId: asString(json['connectionId']),
        pageName: asString(json['pageName']),
        createdAt: asDate(json['createdAt']),
        workspaceId: asString(json['workspaceId']),
      );

  /// The Page's id.
  final String pageId;

  /// The ad connection it is read through.
  final String? connectionId;

  /// The Page's name.
  final String? pageName;

  /// When it was subscribed.
  final DateTime? createdAt;

  /// The workspace it belongs to.
  final String? workspaceId;

  @override
  String toString() => 'LeadPage($pageId)';
}

/// What subscribing a Page returned.
class LeadPageSubscription {
  /// Creates a result.
  const LeadPageSubscription({required this.pageId, this.backfilled = 0});

  /// Reads a result.
  factory LeadPageSubscription.fromJson(Map<String, dynamic> json) =>
      LeadPageSubscription(
        pageId: asString(json['pageId']) ?? '',
        backfilled: asInt(json['backfilled']) ?? 0,
      );

  /// The Page's id.
  final String pageId;

  /// Recent leads stored on subscribing.
  final int backfilled;

  @override
  String toString() => 'LeadPageSubscription($pageId, $backfilled)';
}

/// A Business Center, or the network's equivalent grouping of ad accounts.
class AdBusinessCenter {
  /// Creates a Business Center.
  const AdBusinessCenter({required this.id, required this.name, this.role});

  /// Reads one.
  factory AdBusinessCenter.fromJson(Map<String, dynamic> json) =>
      AdBusinessCenter(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        role: asString(json['role']),
      );

  /// The network's own id for it.
  final String id;

  /// Its name.
  final String name;

  /// The grant's role in it, when the network says.
  final String? role;
}

/// The account an ad runs as. Meta calls it a Page, TikTok an identity; an
/// identity id is what every route calls a `pageId`.
class AdIdentity {
  /// Creates an identity.
  const AdIdentity({
    required this.id,
    required this.type,
    required this.name,
    this.avatarUrl,
  });

  /// Reads one.
  factory AdIdentity.fromJson(Map<String, dynamic> json) => AdIdentity(
        id: asString(json['id']) ?? '',
        type: asString(json['type']) ?? '',
        name: asString(json['name']) ?? '',
        avatarUrl: asString(json['avatarUrl']),
      );

  /// The network's own id for it.
  final String id;

  /// The network's own identity kind, e.g. `CUSTOMIZED_USER`.
  final String type;

  /// Its display name.
  final String name;

  /// Its avatar, when the network has one.
  final String? avatarUrl;
}

/// A post already live on the network, offered as the source of a Spark ad.
class SparkPost {
  /// Creates a post.
  const SparkPost({
    required this.id,
    required this.identityId,
    this.caption,
    this.thumbnailUrl,
    this.createdAt,
    this.views,
  });

  /// Reads one.
  factory SparkPost.fromJson(Map<String, dynamic> json) => SparkPost(
        id: asString(json['id']) ?? '',
        identityId: asString(json['identityId']) ?? '',
        caption: asString(json['caption']),
        thumbnailUrl: asString(json['thumbnailUrl']),
        createdAt: asString(json['createdAt']),
        views: asInt(json['views']),
      );

  /// The post's id on the network.
  final String id;

  /// The identity that owns it.
  final String identityId;

  /// Its caption.
  final String? caption;

  /// Its cover image.
  final String? thumbnailUrl;

  /// When it went up.
  final String? createdAt;

  /// How many times it has been watched.
  final int? views;
}

/// A comment on an ad, read live from the network and never stored.
class AdComment {
  /// Creates a comment.
  const AdComment({
    required this.id,
    required this.text,
    required this.likes,
    required this.replyCount,
    required this.hidden,
    this.adId,
    this.authorName,
    this.authorAvatarUrl,
    this.createdAt,
    this.parentId,
  });

  /// Reads one.
  factory AdComment.fromJson(Map<String, dynamic> json) => AdComment(
        id: asString(json['id']) ?? '',
        text: asString(json['text']) ?? '',
        likes: asInt(json['likes']) ?? 0,
        replyCount: asInt(json['replyCount']) ?? 0,
        hidden: asBool(json['hidden']) ?? false,
        adId: asString(json['adId']),
        authorName: asString(json['authorName']),
        authorAvatarUrl: asString(json['authorAvatarUrl']),
        createdAt: asString(json['createdAt']),
        parentId: asString(json['parentId']),
      );

  /// The comment's id on the network.
  final String id;

  /// What it says.
  final String text;

  /// How many people liked it.
  final int likes;

  /// How many replies hang off it.
  final int replyCount;

  /// Whether it is hidden from the public.
  final bool hidden;

  /// The ad it sits on.
  final String? adId;

  /// Who wrote it.
  final String? authorName;

  /// Their avatar.
  final String? authorAvatarUrl;

  /// When it was written.
  final String? createdAt;

  /// The comment this one answers, when it is not on the ad itself.
  final String? parentId;
}

/// One page of an ad's comments; pass [nextCursor] back as `after`.
class AdCommentsPage {
  /// Creates a page.
  const AdCommentsPage({required this.comments, this.nextCursor});

  /// Reads one.
  factory AdCommentsPage.fromJson(Map<String, dynamic> json) => AdCommentsPage(
        comments: (json['comments'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(AdComment.fromJson)
            .toList(),
        nextCursor: asString(json['nextCursor']),
      );

  /// The comments on this page.
  final List<AdComment> comments;

  /// The cursor for the next page, or null at the end.
  final String? nextCursor;
}
