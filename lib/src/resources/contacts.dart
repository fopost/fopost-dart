import 'package:meta/meta.dart';

import '../http.dart';
import '../json.dart';
import '../models/common.dart';
import '../models/contact.dart';
import 'base.dart';

/// Contacts, the people behind the inbox.
///
/// One row per human, however many handles they write from. Contacts are built
/// for you: an inbound inbox item files its author, a reply files whoever you
/// answered, and both fold into whatever is already on file.
///
/// Everything here needs the `inbox` scope — a key that may read a message may
/// read who sent it — except [conversationAnalytics], which answers counts and
/// reads under `analytics`.
///
/// Reach it as `client.contacts`.
class ContactsResource {
  /// Wired by the FoPost client; do not construct this yourself.
  @internal
  ContactsResource(this._http);

  final FoPostHttp _http;

  /// Returns contacts, most recently active first.
  ///
  /// [search] matches a display name or any of their handles; [platform]
  /// narrows to contacts with a handle on that network; [source] is `inbox`,
  /// `radar` or `import`.
  Future<Page<Contact>> list({
    String? workspaceId,
    String? search,
    String? platform,
    String? source,
    int? page,
    int? perPage,
  }) async {
    // `raw` rather than `object`: the envelope carries the counters beside
    // `data`, and unwrapping would drop them.
    final body = await _http.raw('GET', '/contacts', query: {
      'workspace_id': workspaceId,
      'search': search,
      'platform': platform,
      'source': source,
      'page': page,
      'per_page': perPage,
    });
    final envelope = body is Map<String, dynamic> ? body : const {};
    // This list names its counters `pagination` rather than `meta`.
    return Page<Contact>.fromJson(
      {'data': envelope['data'], 'meta': asMap(envelope['pagination'])},
      Contact.fromJson,
    );
  }

  /// Returns one contact.
  ///
  /// A contact in a workspace the key cannot reach answers `404`, exactly as
  /// an id that never existed does.
  Future<Contact> get(String id) async =>
      Contact.fromJson(await _http.object('GET', '/contacts/${segment(id)}'));

  /// Files a person by hand.
  ///
  /// Folds into the contact that already holds the first channel, so this
  /// cannot duplicate someone the inbox has already met.
  Future<Contact> create({
    required String workspaceId,
    required List<ContactChannel> channels,
    String? displayName,
    String? note,
    Map<String, String>? fields,
  }) async {
    final body = pruned({
      'workspace_id': workspaceId,
      'channels': channels.map((c) => c.toJson()).toList(),
      'display_name': displayName,
      'note': note,
      'fields': fields,
    });
    return Contact.fromJson(
        await _http.object('POST', '/contacts', body: body));
  }

  /// Changes a contact.
  ///
  /// Only what you pass is written. A value in [fields] set to null clears it,
  /// and passing [channels] replaces the list.
  Future<Contact> update(
    String id, {
    String? displayName,
    List<ContactChannel>? channels,
    String? note,
    Map<String, String?>? fields,
  }) async {
    final body = pruned({
      'display_name': displayName,
      'channels': channels?.map((c) => c.toJson()).toList(),
      'note': note,
      'fields': fields,
    });
    return Contact.fromJson(
        await _http.object('PATCH', '/contacts/${segment(id)}', body: body));
  }

  /// Removes a contact. The messages stay in the inbox, and a later one files
  /// the person again.
  Future<void> delete(String id) =>
      _http.discard('DELETE', '/contacts/${segment(id)}');

  /// Returns the inbox threads one contact appears in, newest first.
  Future<List<ContactConversation>> conversations(String id,
      {int? limit}) async {
    final rows = await _http.objects(
      'GET',
      '/contacts/${segment(id)}/conversations',
      query: {'limit': limit},
    );
    return rows.map(ContactConversation.fromJson).toList();
  }

  /// Imports contacts from CSV text.
  ///
  /// `platform` and `handle` are required columns; `external_id`,
  /// `display_name` and `note` are optional, and every other column is read as
  /// a custom field key. A column matching no field is reported back rather
  /// than stored.
  Future<ContactImportResult> import({
    required String workspaceId,
    required String csv,
  }) async {
    final body = {'workspace_id': workspaceId, 'csv': csv};
    return ContactImportResult.fromJson(
        await _http.object('POST', '/contacts/import', body: body));
  }

  /// Returns the columns this workspace keeps about a contact, in display
  /// order.
  Future<List<ContactField>> listFields(String workspaceId) async {
    final rows = await _http.objects('GET', '/contacts/fields',
        query: {'workspace_id': workspaceId});
    return rows.map(ContactField.fromJson).toList();
  }

  /// Adds a column.
  ///
  /// [key] is lower-case letters, digits and underscores, starting with a
  /// letter, and is fixed once created. A `select` field needs at least one
  /// option. A duplicate key answers `409`.
  Future<ContactField> createField({
    required String workspaceId,
    required String key,
    required String name,
    String? type,
    List<String>? options,
  }) async {
    final body = pruned({
      'workspace_id': workspaceId,
      'key': key,
      'name': name,
      'type': type,
      'options': options,
    });
    return ContactField.fromJson(await _http.object(
      'POST',
      '/contacts/fields',
      body: body,
      query: {'workspace_id': workspaceId},
    ));
  }

  /// Renames a field, changes its options, or moves it. The key and the type
  /// are fixed once created.
  Future<ContactField> updateField(
    String id, {
    String? name,
    List<String>? options,
    int? position,
  }) async {
    final body =
        pruned({'name': name, 'options': options, 'position': position});
    return ContactField.fromJson(await _http
        .object('PATCH', '/contacts/fields/${segment(id)}', body: body));
  }

  /// Removes a field and every contact answer to it.
  Future<void> deleteField(String id) =>
      _http.discard('DELETE', '/contacts/fields/${segment(id)}');

  /// Returns inbox volume and reply time per thread.
  ///
  /// This one needs the `analytics` scope rather than `inbox`. [days] is the
  /// reporting period, 1 to 365, and the API defaults to 7; [sort] is
  /// `volume`, `slowest` or `recent`.
  Future<ConversationAnalytics> conversationAnalytics({
    String? workspaceId,
    String? accountId,
    int? days,
    String? sort,
    int? page,
    int? perPage,
  }) async {
    final body =
        await _http.object('GET', '/analytics/inbox/conversations', query: {
      'workspace_id': workspaceId,
      'accountId': accountId,
      'days': days,
      'sort': sort,
      'page': page,
      'per_page': perPage,
    });
    return ConversationAnalytics.fromJson(body);
  }
}
