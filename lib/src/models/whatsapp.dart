import '../json.dart';

/// The business profile on a WhatsApp number, plus how the platform rates it.
class WhatsappProfile {
  /// Creates a profile.
  const WhatsappProfile({
    this.about,
    this.address,
    this.description,
    this.email,
    this.vertical,
    this.websites = const [],
    this.profilePictureUrl,
    this.displayName,
    this.displayNameStatus,
    this.username,
    this.qualityRating,
    this.messagingLimitTier,
  });

  /// Reads a profile.
  factory WhatsappProfile.fromJson(Map<String, dynamic> json) =>
      WhatsappProfile(
        about: asString(json['about']),
        address: asString(json['address']),
        description: asString(json['description']),
        email: asString(json['email']),
        vertical: asString(json['vertical']),
        websites: asStringList(json['websites']),
        profilePictureUrl:
            asString(json['profilePictureUrl'] ?? json['profile_picture_url']),
        displayName: asString(json['displayName'] ?? json['display_name']),
        displayNameStatus:
            asString(json['displayNameStatus'] ?? json['display_name_status']),
        username: asString(json['username']),
        qualityRating:
            asString(json['qualityRating'] ?? json['quality_rating']),
        messagingLimitTier: asString(
            json['messagingLimitTier'] ?? json['messaging_limit_tier']),
      );

  /// The short "about" line on the profile.
  final String? about;

  /// The business address.
  final String? address;

  /// The longer description.
  final String? description;

  /// The contact address on the profile, as the platform reports it.
  final String? email;

  /// The business category.
  final String? vertical;

  /// Up to two websites.
  final List<String> websites;

  /// The profile picture, where the platform serves one.
  final String? profilePictureUrl;

  /// The name shown to customers.
  final String? displayName;

  /// The platform's review state for the display name.
  final String? displayNameStatus;

  /// The public username, where the account has one.
  final String? username;

  /// The platform's quality rating for the number.
  final String? qualityRating;

  /// How many conversations the number may start per day.
  final String? messagingLimitTier;
}

/// A message template. [status] is the review outcome the platform assigned;
/// nothing marks a template approved but the platform.
class WhatsappTemplate {
  /// Creates a template.
  const WhatsappTemplate({
    required this.id,
    required this.name,
    required this.language,
    required this.category,
    required this.status,
    this.rejectedReason,
    this.components = const [],
    this.qualityScore,
  });

  /// Reads a template.
  factory WhatsappTemplate.fromJson(Map<String, dynamic> json) =>
      WhatsappTemplate(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        language: asString(json['language']) ?? '',
        category: asString(json['category']) ?? '',
        status: asString(json['status']) ?? '',
        rejectedReason:
            asString(json['rejectedReason'] ?? json['rejected_reason']),
        components: json['components'] is List
            ? List<Object?>.from(json['components'] as List)
            : const [],
        qualityScore: asString(json['qualityScore'] ?? json['quality_score']),
      );

  /// The platform's id for the template.
  final String id;

  /// The template name, in lowercase with underscores.
  final String name;

  /// The language code, e.g. `en_US`.
  final String language;

  /// `MARKETING`, `UTILITY` or `AUTHENTICATION`.
  final String category;

  /// The review status the platform assigned.
  final String status;

  /// Why the platform rejected or paused it.
  final String? rejectedReason;

  /// The template's components, as the platform stores them.
  final List<Object?> components;

  /// The platform's quality read once the template has traffic.
  final String? qualityScore;
}

/// A group on the business number. Participation is invite-only: no endpoint
/// adds anyone, so [inviteLink] is how they join.
class WhatsappGroup {
  /// Creates a group.
  const WhatsappGroup({
    required this.id,
    required this.subject,
    this.description,
    this.participantCount,
    this.inviteLink,
    this.createdAt,
  });

  /// Reads a group.
  factory WhatsappGroup.fromJson(Map<String, dynamic> json) => WhatsappGroup(
        id: asString(json['id']) ?? '',
        subject: asString(json['subject']) ?? '',
        description: asString(json['description']),
        participantCount:
            asInt(json['participantCount'] ?? json['participant_count']),
        inviteLink: asString(json['inviteLink'] ?? json['invite_link']),
        createdAt: asDate(json['createdAt'] ?? json['created_at']),
      );

  /// The platform's id for the group.
  final String id;

  /// The group name customers see.
  final String subject;

  /// The group description.
  final String? description;

  /// How many people are in the group.
  final int? participantCount;

  /// The link someone joins with.
  final String? inviteLink;

  /// When the group was created.
  final DateTime? createdAt;
}

/// What the platform took and what it refused.
class WhatsappBlockResult {
  /// Creates a block result.
  const WhatsappBlockResult({
    this.blocked = const [],
    this.unblocked = const [],
    this.failed = const [],
  });

  /// Reads a block result.
  factory WhatsappBlockResult.fromJson(Map<String, dynamic> json) =>
      WhatsappBlockResult(
        blocked: asStringList(json['blocked']),
        unblocked: asStringList(json['unblocked']),
        failed: asStringList(json['failed']),
      );

  /// Numbers the platform blocked.
  final List<String> blocked;

  /// Numbers the platform unblocked.
  final List<String> unblocked;

  /// Numbers the platform refused.
  final List<String> failed;
}

/// Whether the cart and catalog show on the number, and which catalog is linked.
class WhatsappCommerceSettings {
  /// Creates commerce settings.
  const WhatsappCommerceSettings({
    this.cartEnabled,
    this.catalogVisible,
    this.catalogId,
  });

  /// Reads commerce settings.
  factory WhatsappCommerceSettings.fromJson(Map<String, dynamic> json) =>
      WhatsappCommerceSettings(
        cartEnabled: asBool(json['cartEnabled'] ?? json['cart_enabled']),
        catalogVisible:
            asBool(json['catalogVisible'] ?? json['catalog_visible']),
        catalogId: asString(json['catalogId'] ?? json['catalog_id']),
      );

  /// Whether the cart is on.
  final bool? cartEnabled;

  /// Whether the catalog is visible.
  final bool? catalogVisible;

  /// The catalog linked to the number.
  final String? catalogId;
}

/// One problem the platform found in a flow definition.
class WhatsappFlowValidationError {
  /// Creates a validation error.
  const WhatsappFlowValidationError(
      {required this.error, required this.message});

  /// Reads a validation error.
  factory WhatsappFlowValidationError.fromJson(Map<String, dynamic> json) =>
      WhatsappFlowValidationError(
        error: asString(json['error']) ?? '',
        message: asString(json['message']) ?? '',
      );

  /// The platform's code for the problem.
  final String error;

  /// What the platform said about it.
  final String message;
}

/// An in-chat form. The platform validates it and owns its status.
class WhatsappFlow {
  /// Creates a flow.
  const WhatsappFlow({
    required this.id,
    required this.name,
    required this.status,
    this.categories = const [],
    this.validationErrors = const [],
    this.endpointUri,
    this.jsonVersion,
    this.previewUrl,
    this.previewExpiresAt,
  });

  /// Reads a flow.
  factory WhatsappFlow.fromJson(Map<String, dynamic> json) => WhatsappFlow(
        id: asString(json['id']) ?? '',
        name: asString(json['name']) ?? '',
        status: asString(json['status']) ?? '',
        categories: asStringList(json['categories']),
        validationErrors:
            _errors(json['validationErrors'] ?? json['validation_errors']),
        endpointUri: asString(json['endpointUri'] ?? json['endpoint_uri']),
        jsonVersion: asString(json['jsonVersion'] ?? json['json_version']),
        previewUrl: asString(json['previewUrl'] ?? json['preview_url']),
        previewExpiresAt:
            asDate(json['previewExpiresAt'] ?? json['preview_expires_at']),
      );

  /// The platform's id for the flow.
  final String id;

  /// The flow name.
  final String name;

  /// `DRAFT`, `PUBLISHED`, `DEPRECATED` or `BLOCKED`.
  final String status;

  /// The categories the flow declares.
  final List<String> categories;

  /// What the platform found wrong with the definition.
  final List<WhatsappFlowValidationError> validationErrors;

  /// Where the platform calls back for a flow that reads live data.
  final String? endpointUri;

  /// The flow JSON version the definition uses.
  final String? jsonVersion;

  /// A short-lived preview of the flow.
  final String? previewUrl;

  /// When that preview stops working.
  final DateTime? previewExpiresAt;
}

/// The platform's verdict on an uploaded definition. It answers with the errors
/// rather than refusing the upload, so they arrive as data.
class WhatsappFlowJsonResult {
  /// Creates an upload result.
  const WhatsappFlowJsonResult({
    required this.success,
    this.validationErrors = const [],
  });

  /// Reads an upload result.
  factory WhatsappFlowJsonResult.fromJson(Map<String, dynamic> json) =>
      WhatsappFlowJsonResult(
        success: asBool(json['success']) ?? false,
        validationErrors:
            _errors(json['validationErrors'] ?? json['validation_errors']),
      );

  /// Whether the platform accepted the definition.
  final bool success;

  /// What it found wrong with it.
  final List<WhatsappFlowValidationError> validationErrors;
}

List<WhatsappFlowValidationError> _errors(Object? value) => value is List
    ? value
        .whereType<Map>()
        .map((e) =>
            WhatsappFlowValidationError.fromJson(Map<String, dynamic>.from(e)))
        .toList()
    : const [];

/// What one person submitted through a flow.
class WhatsappFlowResponse {
  /// Creates a flow answer.
  const WhatsappFlowResponse({
    required this.messageId,
    this.waId,
    this.flowToken,
    this.answers = const {},
    this.respondedAt,
  });

  /// Reads a flow answer.
  factory WhatsappFlowResponse.fromJson(Map<String, dynamic> json) =>
      WhatsappFlowResponse(
        messageId: asString(json['messageId'] ?? json['message_id']) ?? '',
        waId: asString(json['waId'] ?? json['wa_id']),
        flowToken: asString(json['flowToken'] ?? json['flow_token']),
        answers: asMap(json['answers']),
        respondedAt: asDate(json['respondedAt'] ?? json['responded_at']),
      );

  /// The message the answer arrived on.
  final String messageId;

  /// The person's WhatsApp id.
  final String? waId;

  /// The token the flow carried, where it had one.
  final String? flowToken;

  /// Whatever the flow's screens collected.
  final Map<String, dynamic> answers;

  /// When they submitted it.
  final DateTime? respondedAt;
}

/// Whether a business public key is registered. The key itself never comes back.
class WhatsappEncryptionKeyStatus {
  /// Creates a key status.
  const WhatsappEncryptionKeyStatus({
    required this.hasKey,
    this.signatureStatus,
  });

  /// Reads a key status.
  factory WhatsappEncryptionKeyStatus.fromJson(Map<String, dynamic> json) =>
      WhatsappEncryptionKeyStatus(
        hasKey: asBool(json['hasKey'] ?? json['has_key']) ?? false,
        signatureStatus:
            asString(json['signatureStatus'] ?? json['signature_status']),
      );

  /// Whether a key is registered at all.
  final bool hasKey;

  /// How the platform judged the signature.
  final String? signatureStatus;
}

/// A sandbox invitation. Only the last four digits of the tester's number
/// travel; the number itself is never stored.
class WhatsappSandboxSession {
  /// Creates a sandbox session.
  const WhatsappSandboxSession({
    required this.id,
    required this.status,
    required this.phoneNumberLast4,
    this.invitedAt,
    this.activatedAt,
    this.expiresAt,
  });

  /// Reads a sandbox session.
  factory WhatsappSandboxSession.fromJson(Map<String, dynamic> json) =>
      WhatsappSandboxSession(
        id: asString(json['id']) ?? '',
        status: asString(json['status']) ?? '',
        phoneNumberLast4:
            asString(json['phoneNumberLast4'] ?? json['phone_number_last4']) ??
                '',
        invitedAt: asDate(json['invitedAt'] ?? json['invited_at']),
        activatedAt: asDate(json['activatedAt'] ?? json['activated_at']),
        expiresAt: asDate(json['expiresAt'] ?? json['expires_at']),
      );

  /// The session id.
  final String id;

  /// `invited`, `active` or `expired`.
  final String status;

  /// The last four digits of the tester's number.
  final String phoneNumberLast4;

  /// When the invitation went out.
  final DateTime? invitedAt;

  /// When the tester replied and opened the window.
  final DateTime? activatedAt;

  /// When the session stops working.
  final DateTime? expiresAt;
}
