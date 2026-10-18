import 'package:meta/meta.dart';

import '../http.dart';
import '../models/whatsapp.dart';
import 'base.dart';

/// A WhatsApp Business connection: a number the customer already owns.
///
/// The platform owns templates, flows, the business profile and the commerce
/// settings, so every method here is a live read or write against the customer's
/// own WhatsApp Business Account. Nothing is cached, and all of it answers 503
/// until WhatsApp is set up on the deployment. Every method needs the `accounts`
/// scope, except the sandbox, which sends a template and needs `publish`.
///
/// Reach it as `client.whatsapp`.
class WhatsappResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  WhatsappResource(this._http);

  final FoPostHttp _http;

  String _base(String accountId) => '/accounts/${segment(accountId)}/whatsapp';

  // ─── Profile ──────────────────────────────────────────────────────────

  /// The profile on the number, plus its quality rating and limit tier.
  ///
  /// Wraps the API's `getWhatsappProfile` operation.
  Future<WhatsappProfile> profile(String accountId) async =>
      WhatsappProfile.fromJson(
          await _http.object('GET', '${_base(accountId)}/profile'));

  /// A partial update: omitted arguments keep their value.
  ///
  /// Wraps the API's `updateWhatsappProfile` operation.
  Future<WhatsappProfile> updateProfile(
    String accountId, {
    String? about,
    String? address,
    String? description,
    String? vertical,
    List<String>? websites,
    String? profilePictureMediaId,
  }) async {
    final body = <String, dynamic>{
      if (about != null) 'about': about,
      if (address != null) 'address': address,
      if (description != null) 'description': description,
      if (vertical != null) 'vertical': vertical,
      if (websites != null) 'websites': websites,
      if (profilePictureMediaId != null)
        'profile_picture_media_id': profilePictureMediaId,
    };
    return WhatsappProfile.fromJson(
        await _http.object('PATCH', '${_base(accountId)}/profile', body: body));
  }

  /// A review, not a write: the number keeps its old name until it passes.
  ///
  /// Wraps the API's `requestWhatsappDisplayName` operation.
  Future<void> requestDisplayName(String accountId, String displayName) =>
      _http.discard('POST', '${_base(accountId)}/profile/display-name',
          body: {'display_name': displayName});

  /// Sets the public username on the number.
  ///
  /// Wraps the API's `setWhatsappUsername` operation.
  Future<WhatsappProfile> setUsername(
          String accountId, String username) async =>
      WhatsappProfile.fromJson(await _http.object(
          'PUT', '${_base(accountId)}/profile/username',
          body: {'username': username}));

  // ─── Templates ────────────────────────────────────────────────────────

  /// Every template on the account, with its review status.
  ///
  /// Wraps the API's `listWhatsappTemplates` operation.
  Future<List<WhatsappTemplate>> templates(String accountId,
      {String? after}) async {
    final rows = await _http.objects('GET', '${_base(accountId)}/templates',
        query: {'after': after});
    return rows.map(WhatsappTemplate.fromJson).toList();
  }

  /// The pre-written templates the platform offers, for adapting.
  ///
  /// Wraps the API's `listWhatsappTemplateLibrary` operation.
  Future<List<Map<String, dynamic>>> templateLibrary(String accountId,
          {String? search}) =>
      _http.objects('GET', '${_base(accountId)}/templates/library',
          query: {'search': search});

  /// One template and the review status it currently has.
  ///
  /// Wraps the API's `getWhatsappTemplate` operation.
  Future<WhatsappTemplate> template(
          String accountId, String templateId) async =>
      WhatsappTemplate.fromJson(await _http.object(
          'GET', '${_base(accountId)}/templates/${segment(templateId)}'));

  /// Files a template for review. The result carries the status the platform
  /// assigned, which is `PENDING` on a normal submission.
  ///
  /// Wraps the API's `createWhatsappTemplate` operation.
  Future<WhatsappTemplate> createTemplate(
    String accountId, {
    required String name,
    required String language,
    required String category,
    required List<Map<String, dynamic>> components,
    bool? allowCategoryChange,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'language': language,
      'category': category,
      'components': components,
      if (allowCategoryChange != null)
        'allow_category_change': allowCategoryChange,
    };
    return WhatsappTemplate.fromJson(await _http
        .object('POST', '${_base(accountId)}/templates', body: body));
  }

  /// Creates a template from one of the platform's library entries.
  ///
  /// Wraps the API's `importWhatsappTemplate` operation.
  Future<WhatsappTemplate> importTemplate(
    String accountId, {
    required String libraryTemplateName,
    required String name,
    required String language,
    required String category,
    List<Map<String, dynamic>>? libraryTemplateButtonInputs,
  }) async {
    final body = <String, dynamic>{
      'library_template_name': libraryTemplateName,
      'name': name,
      'language': language,
      'category': category,
      if (libraryTemplateButtonInputs != null)
        'library_template_button_inputs': libraryTemplateButtonInputs,
    };
    return WhatsappTemplate.fromJson(await _http
        .object('POST', '${_base(accountId)}/templates/import', body: body));
  }

  /// Edits a template. The name cannot change; create a new one instead.
  ///
  /// Wraps the API's `updateWhatsappTemplate` operation.
  Future<WhatsappTemplate> updateTemplate(
    String accountId,
    String templateId, {
    String? category,
    List<Map<String, dynamic>>? components,
  }) async {
    final body = <String, dynamic>{
      if (category != null) 'category': category,
      if (components != null) 'components': components,
    };
    return WhatsappTemplate.fromJson(await _http.object(
        'PATCH', '${_base(accountId)}/templates/${segment(templateId)}',
        body: body));
  }

  /// The name is required: it is what the platform deletes by.
  ///
  /// Wraps the API's `deleteWhatsappTemplate` operation.
  Future<void> deleteTemplate(
    String accountId,
    String templateId, {
    required String name,
  }) =>
      _http.discard(
          'DELETE', '${_base(accountId)}/templates/${segment(templateId)}',
          query: {'name': name});

  // ─── Groups ───────────────────────────────────────────────────────────

  /// The groups this number created.
  ///
  /// Wraps the API's `listWhatsappGroups` operation.
  Future<List<WhatsappGroup>> groups(String accountId) async {
    final rows = await _http.objects('GET', '${_base(accountId)}/groups');
    return rows.map(WhatsappGroup.fromJson).toList();
  }

  /// Participation is invite-only: send the invite link, there is no add.
  ///
  /// Wraps the API's `createWhatsappGroup` operation.
  Future<WhatsappGroup> createGroup(
    String accountId, {
    required String subject,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'subject': subject,
      if (description != null) 'description': description,
    };
    return WhatsappGroup.fromJson(
        await _http.object('POST', '${_base(accountId)}/groups', body: body));
  }

  /// One group and its participant count.
  ///
  /// Wraps the API's `getWhatsappGroup` operation.
  Future<WhatsappGroup> group(String accountId, String groupId) async =>
      WhatsappGroup.fromJson(await _http.object(
          'GET', '${_base(accountId)}/groups/${segment(groupId)}'));

  /// Changes a group's subject or description.
  ///
  /// Wraps the API's `updateWhatsappGroup` operation.
  Future<WhatsappGroup> updateGroup(
    String accountId,
    String groupId, {
    String? subject,
    String? description,
  }) async {
    final body = <String, dynamic>{
      if (subject != null) 'subject': subject,
      if (description != null) 'description': description,
    };
    return WhatsappGroup.fromJson(await _http.object(
        'PATCH', '${_base(accountId)}/groups/${segment(groupId)}',
        body: body));
  }

  /// Removes the group.
  ///
  /// Wraps the API's `deleteWhatsappGroup` operation.
  Future<void> deleteGroup(String accountId, String groupId) =>
      _http.discard('DELETE', '${_base(accountId)}/groups/${segment(groupId)}');

  /// The link someone joins the group with.
  Future<String?> groupInviteLink(String accountId, String groupId) async {
    final body = await _http.object(
        'GET', '${_base(accountId)}/groups/${segment(groupId)}/invite-link');
    return body['inviteLink'] as String?;
  }

  /// Issues a new link and invalidates the old one.
  Future<String?> resetGroupInviteLink(String accountId, String groupId) async {
    final body = await _http.object(
        'POST', '${_base(accountId)}/groups/${segment(groupId)}/invite-link');
    return body['inviteLink'] as String?;
  }

  /// Removes people from the group. There is no matching add.
  Future<void> removeGroupParticipants(
    String accountId,
    String groupId,
    List<String> users,
  ) =>
      _http.discard('DELETE',
          '${_base(accountId)}/groups/${segment(groupId)}/participants',
          body: {'users': users});

  // ─── Blocking ─────────────────────────────────────────────────────────

  /// The numbers this account has blocked.
  ///
  /// Wraps the API's `listWhatsappBlocked` operation.
  Future<List<String>> blocked(String accountId, {String? after}) async {
    final decoded = await _http
        .json('GET', '${_base(accountId)}/block', query: {'after': after});
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList();
  }

  /// Blocks up to 100 numbers, and names the ones the platform refused.
  ///
  /// Wraps the API's `blockWhatsappUsers` operation.
  Future<WhatsappBlockResult> blockUsers(
          String accountId, List<String> users) async =>
      WhatsappBlockResult.fromJson(await _http
          .object('POST', '${_base(accountId)}/block', body: {'users': users}));

  /// Unblocks up to 100 numbers.
  ///
  /// Wraps the API's `unblockWhatsappUsers` operation.
  Future<WhatsappBlockResult> unblockUsers(
          String accountId, List<String> users) async =>
      WhatsappBlockResult.fromJson(await _http.object(
          'DELETE', '${_base(accountId)}/block',
          body: {'users': users}));

  // ─── Commerce ─────────────────────────────────────────────────────────

  /// Whether the cart and catalog show on the number.
  ///
  /// Wraps the API's `getWhatsappCommerce` operation.
  Future<WhatsappCommerceSettings> commerceSettings(String accountId) async =>
      WhatsappCommerceSettings.fromJson(
          await _http.object('GET', '${_base(accountId)}/commerce'));

  /// Turns the cart or the catalog on or off.
  ///
  /// Wraps the API's `updateWhatsappCommerce` operation.
  Future<WhatsappCommerceSettings> updateCommerceSettings(
    String accountId, {
    bool? cartEnabled,
    bool? catalogVisible,
  }) async {
    final body = <String, dynamic>{
      if (cartEnabled != null) 'is_cart_enabled': cartEnabled,
      if (catalogVisible != null) 'is_catalog_visible': catalogVisible,
    };
    return WhatsappCommerceSettings.fromJson(await _http
        .object('PATCH', '${_base(accountId)}/commerce', body: body));
  }

  /// Points the number at a catalog the customer already owns.
  ///
  /// Wraps the API's `linkWhatsappCatalog` operation.
  Future<WhatsappCommerceSettings> linkCatalog(
          String accountId, String catalogId) async =>
      WhatsappCommerceSettings.fromJson(await _http.object(
          'POST', '${_base(accountId)}/commerce/catalog',
          body: {'catalog_id': catalogId}));

  // ─── Flows ────────────────────────────────────────────────────────────

  /// The in-chat forms on this account, with their validation errors.
  ///
  /// Wraps the API's `listWhatsappFlows` operation.
  Future<List<WhatsappFlow>> flows(String accountId) async {
    final rows = await _http.objects('GET', '${_base(accountId)}/flows');
    return rows.map(WhatsappFlow.fromJson).toList();
  }

  /// One flow and what the platform found wrong with it.
  ///
  /// Wraps the API's `getWhatsappFlow` operation.
  Future<WhatsappFlow> flow(String accountId, String flowId) async =>
      WhatsappFlow.fromJson(await _http.object(
          'GET', '${_base(accountId)}/flows/${segment(flowId)}'));

  /// Creates a draft flow; its screens are uploaded separately.
  ///
  /// Wraps the API's `createWhatsappFlow` operation.
  Future<WhatsappFlow> createFlow(
    String accountId, {
    required String name,
    required List<String> categories,
    String? endpointUri,
    String? cloneFlowId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'categories': categories,
      if (endpointUri != null) 'endpoint_uri': endpointUri,
      if (cloneFlowId != null) 'clone_flow_id': cloneFlowId,
    };
    return WhatsappFlow.fromJson(
        await _http.object('POST', '${_base(accountId)}/flows', body: body));
  }

  /// Changes a flow's name, categories or endpoint.
  ///
  /// Wraps the API's `updateWhatsappFlow` operation.
  Future<WhatsappFlow> updateFlow(
    String accountId,
    String flowId, {
    String? name,
    List<String>? categories,
    String? endpointUri,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (categories != null) 'categories': categories,
      if (endpointUri != null) 'endpoint_uri': endpointUri,
    };
    return WhatsappFlow.fromJson(await _http.object(
        'PATCH', '${_base(accountId)}/flows/${segment(flowId)}',
        body: body));
  }

  /// Drafts only; a published flow is deprecated instead.
  ///
  /// Wraps the API's `deleteWhatsappFlow` operation.
  Future<void> deleteFlow(String accountId, String flowId) =>
      _http.discard('DELETE', '${_base(accountId)}/flows/${segment(flowId)}');

  /// Replaces the flow's screens. The platform answers with its validation
  /// errors rather than refusing, so they come back as data.
  Future<WhatsappFlowJsonResult> uploadFlowJson(
    String accountId,
    String flowId,
    Map<String, dynamic> flowJson,
  ) async =>
      WhatsappFlowJsonResult.fromJson(await _http.object(
          'PUT', '${_base(accountId)}/flows/${segment(flowId)}/json',
          body: {'flow_json': flowJson}));

  /// Makes the flow sendable. A published flow can no longer be deleted.
  Future<WhatsappFlow> publishFlow(String accountId, String flowId) async =>
      WhatsappFlow.fromJson(await _http.object(
          'POST', '${_base(accountId)}/flows/${segment(flowId)}/publish'));

  /// Retires a published flow.
  Future<WhatsappFlow> deprecateFlow(String accountId, String flowId) async =>
      WhatsappFlow.fromJson(await _http.object(
          'POST', '${_base(accountId)}/flows/${segment(flowId)}/deprecate'));

  /// What people submitted through this account's flows.
  ///
  /// Wraps the API's `listWhatsappFlowResponses` operation.
  Future<List<WhatsappFlowResponse>> flowResponses(String accountId) async {
    final rows =
        await _http.objects('GET', '${_base(accountId)}/flows/responses');
    return rows.map(WhatsappFlowResponse.fromJson).toList();
  }

  /// Whether a business public key is registered, and how it was judged.
  ///
  /// Wraps the API's `getWhatsappEncryptionKey` operation.
  Future<WhatsappEncryptionKeyStatus> encryptionKeyStatus(
          String accountId) async =>
      WhatsappEncryptionKeyStatus.fromJson(await _http.object(
          'GET', '${_base(accountId)}/flows/encryption-key'));

  /// Registers the public half of the key the platform encrypts a flow
  /// endpoint's payloads with. The private half stays with the customer.
  ///
  /// Wraps the API's `setWhatsappEncryptionKey` operation.
  Future<WhatsappEncryptionKeyStatus> setEncryptionKey(
    String accountId,
    String businessPublicKey,
  ) async =>
      WhatsappEncryptionKeyStatus.fromJson(await _http.object(
          'PUT', '${_base(accountId)}/flows/encryption-key',
          body: {'business_public_key': businessPublicKey}));

  // ─── Account state and sandbox ────────────────────────────────────────

  /// The account review state and the number's quality and limit tier.
  ///
  /// Wraps the API's `getWhatsappAccountEvents` operation.
  Future<Map<String, dynamic>> accountEvents(String accountId) =>
      _http.object('GET', '${_base(accountId)}/events');

  /// Sandbox invitations for a workspace.
  Future<List<WhatsappSandboxSession>> sandboxSessions({
    required String workspaceId,
  }) async {
    final rows = await _http.objects('GET', '/whatsapp/sandbox/sessions',
        query: {'workspaceId': workspaceId});
    return rows.map(WhatsappSandboxSession.fromJson).toList();
  }

  /// Invites one tester to the platform-owned test number. Inviting sends a
  /// template, so it needs the `publish` scope.
  Future<WhatsappSandboxSession> createSandboxSession({
    required String workspaceId,
    required String phoneNumber,
  }) async =>
      WhatsappSandboxSession.fromJson(
          await _http.object('POST', '/whatsapp/sandbox/sessions', body: {
        'workspaceId': workspaceId,
        'phoneNumber': phoneNumber,
      }));
}
