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
