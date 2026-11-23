import '../json.dart';

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
