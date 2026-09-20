import '../json.dart';

/// The kinds of item the inbox collects.
abstract final class InboxItemType {
  /// A comment on one of the account's posts.
  static const String comment = 'comment';

  /// A post the account was tagged in.
  static const String mention = 'mention';

  /// A direct message.
  static const String dm = 'dm';

  /// A rating left on the business: a Google Business review or a Facebook
  /// Page recommendation.
  static const String review = 'review';
}

/// The states an inbox item moves through.
abstract final class InboxItemState {
  /// Nobody has looked at it yet.
  static const String unread = 'unread';

  /// Seen, still open.
  static const String read = 'read';

  /// Dealt with.
  static const String resolved = 'resolved';

  /// Hidden until `snoozedUntil`.
  static const String snoozed = 'snoozed';
}

/// The orders an inbox list can be returned in.
abstract final class InboxSort {
  /// Latest first, the default.
  static const String newest = 'newest';

  /// Oldest first.
  static const String oldest = 'oldest';

  /// Items with no reply first.
  static const String unanswered = 'unanswered';
}

/// The connected account an inbox row belongs to.
class InboxAccountRef {
  /// Creates a reference.
  const InboxAccountRef({
    required this.id,
    required this.platform,
    this.username,
    this.name,
    this.avatar,
  });

  /// Reads the reference.
  factory InboxAccountRef.fromJson(Map<String, dynamic> json) =>
      InboxAccountRef(
        id: asString(json['id']) ?? '',
        platform: asString(json['platform']) ?? '',
        username: asString(json['username']),
        name: asString(json['name']),
        avatar: asString(json['avatar']),
      );

  /// The account's id.
  final String id;

  /// The account's network.
  final String platform;

  /// The account's handle.
  final String? username;

  /// The account's display name.
  final String? name;

  /// The account's avatar URL.
  final String? avatar;

  @override
  String toString() => 'InboxAccountRef($platform, $id)';
}

/// A file attached to an inbox item.
class InboxAttachment {
  /// Creates an attachment.
  const InboxAttachment({
    required this.kind,
    this.name,
    this.width,
    this.height,
    this.link,
    this.url,
    this.previewUrl,
  });

  /// Reads an attachment.
  factory InboxAttachment.fromJson(Map<String, dynamic> json) =>
      InboxAttachment(
        kind: asString(json['kind']) ?? '',
        name: asString(json['name']),
        width: asInt(json['width']),
        height: asInt(json['height']),
        link: asString(json['link']),
        url: asString(json['url']),
        previewUrl: asString(json['previewUrl']),
      );

  /// What the attachment is, e.g. `image` or `video`.
  final String kind;

  /// The file name, when the platform sent one.
  final String? name;

  /// Pixel width, when known.
  final int? width;

  /// Pixel height, when known.
  final int? height;

  /// A link the attachment points at.
  final String? link;

  /// Where to fetch the file, served by the API rather than the platform.
  final String? url;

  /// A smaller rendition of [url].
  final String? previewUrl;

  @override
  String toString() => 'InboxAttachment($kind)';
}

/// The platform post an item sits under, whoever published it.
class InboxPostContext {
  /// Creates a post context.
  const InboxPostContext({
    this.externalId,
    this.isOwn,
    this.text,
    this.authorName,
    this.authorHandle,
    this.authorAvatarUrl,
    this.thumbnailUrl,
    this.permalink,
    this.publishedAt,
    this.published,
  });

  /// Reads a post context.
  factory InboxPostContext.fromJson(Map<String, dynamic> json) =>
      InboxPostContext(
        externalId: asString(json['externalId']),
        isOwn: asBool(json['isOwn']),
        text: asString(json['text']),
        authorName: asString(json['authorName']),
        authorHandle: asString(json['authorHandle']),
        authorAvatarUrl: asString(json['authorAvatarUrl']),
        thumbnailUrl: asString(json['thumbnailUrl']),
        permalink: asString(json['permalink']),
        publishedAt: asDate(json['publishedAt']),
        published: asMapOrNull(json['published']),
      );

  /// The post's id on the platform.
  final String? externalId;

  /// Whether the connected account published it.
  final bool? isOwn;

  /// The post's text.
  final String? text;

  /// Who published it.
  final String? authorName;

  /// The publisher's handle.
  final String? authorHandle;

  /// The publisher's avatar URL.
  final String? authorAvatarUrl;

  /// A thumbnail of the post's media.
  final String? thumbnailUrl;

  /// The post's URL on the platform.
  final String? permalink;

  /// When it went live.
  final DateTime? publishedAt;

  /// The FoPost post it was published from, when it was.
  final Map<String, dynamic>? published;

  @override
  String toString() => 'InboxPostContext($externalId)';
}

/// A comment, mention, review or direct message on a connected account.
class InboxItem {
  /// Creates an item.
  const InboxItem({
    required this.id,
    required this.platform,
    required this.type,
    required this.state,
    this.workspaceId,
    this.direction,
    this.conversationId,
    this.authorName,
    this.authorHandle,
    this.authorAvatarUrl,
    this.text,
    this.rating,
    this.attachments = const [],
    this.permalink,
    this.postExternalId,
    this.parentExternalId,
    this.platformCreatedAt,
    this.snoozedUntil,
    this.repliedAt,
    this.createdAt,
    this.canReply,
    this.hidden,
    this.liked,
    this.pinned,
    this.reaction,
    this.editedAt,
    this.canHide,
    this.canDelete,
    this.canLike,
    this.canPin,
    this.canEdit,
    this.canReact,
    this.canSendMedia,
    this.canQuickReply,
    this.canPrivateReply,
    this.post,
    this.postContext,
    this.account,
  });

  /// Reads an item.
  factory InboxItem.fromJson(Map<String, dynamic> json) => InboxItem(
        id: asString(json['id']) ?? '',
        platform: asString(json['platform']) ?? '',
        type: asString(json['type']) ?? '',
        state: asString(json['state']) ?? '',
        workspaceId: asString(json['workspaceId']),
        direction: asString(json['direction']),
        conversationId: asString(json['conversationId']),
        authorName: asString(json['authorName']),
        authorHandle: asString(json['authorHandle']),
        authorAvatarUrl: asString(json['authorAvatarUrl']),
        text: asString(json['text']),
        rating: asInt(json['rating']),
        attachments: asModelList(json['attachments'], InboxAttachment.fromJson),
        permalink: asString(json['permalink']),
        postExternalId: asString(json['postExternalId']),
        parentExternalId: asString(json['parentExternalId']),
        platformCreatedAt: asDate(json['platformCreatedAt']),
        snoozedUntil: asDate(json['snoozedUntil']),
        repliedAt: asDate(json['repliedAt']),
        createdAt: asDate(json['createdAt']),
        canReply: asBool(json['canReply']),
        hidden: asBool(json['hidden']),
        liked: asBool(json['liked']),
        pinned: asBool(json['pinned']),
        reaction: asString(json['reaction']),
        editedAt: asDate(json['editedAt']),
        canHide: asBool(json['canHide']),
        canDelete: asBool(json['canDelete']),
        canLike: asBool(json['canLike']),
        canPin: asBool(json['canPin']),
        canEdit: asBool(json['canEdit']),
        canReact: asBool(json['canReact']),
        canSendMedia: asBool(json['canSendMedia']),
        canQuickReply: asBool(json['canQuickReply']),
        canPrivateReply: asBool(json['canPrivateReply']),
        post: asMapOrNull(json['post']),
        postContext: _postContext(json['postContext']),
        account: _accountRef(json['account']),
      );

  /// The item's id.
  final String id;

  /// The network it came from.
  final String platform;

  /// One of [InboxItemType].
  final String type;

  /// One of [InboxItemState].
  final String state;

  /// The workspace the account lives in.
  final String? workspaceId;

  /// `inbound` or `outbound`.
  final String? direction;

  /// The DM thread it belongs to, for a `dm`.
  final String? conversationId;

  /// Who wrote it.
  final String? authorName;

  /// The author's handle.
  final String? authorHandle;

  /// The author's avatar URL.
  final String? authorAvatarUrl;

  /// The item's text.
  final String? text;

  /// Stars on a review, 1-5. Null on every other type.
  final int? rating;

  /// Files attached to it.
  final List<InboxAttachment> attachments;

  /// Its URL on the platform.
  final String? permalink;

  /// The platform post it sits under.
  final String? postExternalId;

  /// The comment it replies to, when nested.
  final String? parentExternalId;

  /// When the platform recorded it.
  final DateTime? platformCreatedAt;

  /// When a snoozed item resurfaces.
  final DateTime? snoozedUntil;

  /// When the account replied.
  final DateTime? repliedAt;

  /// When FoPost stored it.
  final DateTime? createdAt;

  /// Whether the platform lets the account reply.
  final bool? canReply;

  /// Whether the comment is hidden on the platform.
  final bool? hidden;

  /// Whether the account has liked it.
  final bool? liked;

  /// Whether our own comment is pinned.
  final bool? pinned;

  /// Our reaction on a DM.
  final String? reaction;

  /// When our own comment was last edited.
  final DateTime? editedAt;

  /// Whether the platform lets the account hide it.
  final bool? canHide;

  /// Whether the platform lets the account delete it: a comment someone left,
  /// or our own reply.
  final bool? canDelete;

  /// Whether the platform lets the account like it.
  final bool? canLike;

  /// Whether the platform lets the account pin it (our own comment only).
  final bool? canPin;

  /// Whether the platform lets the account edit it (our own comment only).
  final bool? canEdit;

  /// Whether the platform lets the account react to it.
  final bool? canReact;

  /// Whether a reply can carry media.
  final bool? canSendMedia;

  /// Whether a reply can carry quick replies.
  final bool? canQuickReply;

  /// Whether a DM can be opened with `startConversation(commentId: ...)`.
  final bool? canPrivateReply;

  /// The FoPost post it sits under, when it was published through FoPost.
  final Map<String, dynamic>? post;

  /// The platform post it sits under, whoever published it.
  final InboxPostContext? postContext;

  /// The account it arrived on.
  final InboxAccountRef? account;

  @override
  String toString() => 'InboxItem($id, $type, $state)';
}

/// One platform post and the comments it has collected, or one review left
/// on the business.
class InboxThread {
  /// Creates a thread.
  const InboxThread({
    required this.accountId,
    this.workspaceId,
    this.postExternalId,
    this.commentCount = 0,
    this.unreadCount = 0,
    this.lastCommentAt,
    this.lastCommentText,
    this.lastCommentAuthor,
    this.rating,
    this.post,
    this.account,
  });

  /// Reads a thread.
  factory InboxThread.fromJson(Map<String, dynamic> json) => InboxThread(
        accountId: asString(json['accountId']) ?? '',
        workspaceId: asString(json['workspaceId']),
        postExternalId: asString(json['postExternalId']),
        commentCount: asInt(json['commentCount']) ?? 0,
        unreadCount: asInt(json['unreadCount']) ?? 0,
        lastCommentAt: asDate(json['lastCommentAt']),
        lastCommentText: asString(json['lastCommentText']),
        lastCommentAuthor: asString(json['lastCommentAuthor']),
        rating: asInt(json['rating']),
        post: _postContext(json['post']),
        account: _accountRef(json['account']),
      );

  /// The account the post belongs to.
  final String accountId;

  /// The workspace the account lives in.
  final String? workspaceId;

  /// The post's id on the platform.
  final String? postExternalId;

  /// How many comments the post has.
  final int commentCount;

  /// How many of them are unread.
  final int unreadCount;

  /// When the latest comment arrived.
  final DateTime? lastCommentAt;

  /// The latest comment's text.
  final String? lastCommentText;

  /// Who wrote the latest comment.
  final String? lastCommentAuthor;

  /// Stars, on a review thread. Null on comments and mentions.
  final int? rating;

  /// The post itself.
  final InboxPostContext? post;

  /// The account it lives on.
  final InboxAccountRef? account;

  @override
  String toString() => 'InboxThread($postExternalId, $commentCount comments)';
}

/// The other side of a direct-message thread.
class InboxParticipant {
  /// Creates a participant.
  const InboxParticipant({this.name, this.handle, this.avatarUrl});

  /// Reads a participant.
  factory InboxParticipant.fromJson(Map<String, dynamic> json) =>
      InboxParticipant(
        name: asString(json['name']),
        handle: asString(json['handle']),
        avatarUrl: asString(json['avatarUrl']),
      );

  /// Their display name.
  final String? name;

  /// Their handle.
  final String? handle;

  /// Their avatar URL.
  final String? avatarUrl;

  @override
  String toString() => 'InboxParticipant($handle)';
}

/// One direct-message thread.
class InboxConversation {
  /// Creates a conversation.
  const InboxConversation({
    required this.accountId,
    required this.conversationId,
    this.workspaceId,
    this.messageCount = 0,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageOutbound,
    this.participant,
    this.account,
  });

  /// Reads a conversation.
  factory InboxConversation.fromJson(Map<String, dynamic> json) =>
      InboxConversation(
        accountId: asString(json['accountId']) ?? '',
        conversationId: asString(json['conversationId']) ?? '',
        workspaceId: asString(json['workspaceId']),
        messageCount: asInt(json['messageCount']) ?? 0,
        unreadCount: asInt(json['unreadCount']) ?? 0,
        lastMessageAt: asDate(json['lastMessageAt']),
        lastMessageText: asString(json['lastMessageText']),
        lastMessageOutbound: asBool(json['lastMessageOutbound']),
        participant: json['participant'] is Map
            ? InboxParticipant.fromJson(asMap(json['participant']))
            : null,
        account: _accountRef(json['account']),
      );

  /// The account the thread is on.
  final String accountId;

  /// The thread's id on the platform.
  final String conversationId;

  /// The workspace the account lives in.
  final String? workspaceId;

  /// How many messages the thread holds.
  final int messageCount;

  /// How many of them are unread.
  final int unreadCount;

  /// When the latest message arrived.
  final DateTime? lastMessageAt;

  /// The latest message's text.
  final String? lastMessageText;

  /// Whether the account sent the latest message.
  final bool? lastMessageOutbound;

  /// Who the account is talking to.
  final InboxParticipant? participant;

  /// The account it lives on.
  final InboxAccountRef? account;

  @override
  String toString() => 'InboxConversation($conversationId)';
}

/// A connected account, flagged with what the inbox can read for it.
class InboxAccount {
  /// Creates an account.
  const InboxAccount({
    required this.id,
    required this.platform,
    this.workspaceId,
    this.username,
    this.name,
    this.avatar,
    this.inboxSupported,
    this.pendingReason,
    this.dmSupported,
    this.dmPendingReason,
    this.canStartConversation,
  });

  /// Reads an account.
  factory InboxAccount.fromJson(Map<String, dynamic> json) => InboxAccount(
        id: asString(json['id']) ?? '',
        platform: asString(json['platform']) ?? '',
        workspaceId: asString(json['workspaceId']),
        username: asString(json['username']),
        name: asString(json['name']),
        avatar: asString(json['avatar']),
        inboxSupported: asBool(json['inboxSupported']),
        pendingReason: asString(json['pendingReason']),
        dmSupported: asBool(json['dmSupported']),
        dmPendingReason: asString(json['dmPendingReason']),
        canStartConversation: asBool(json['canStartConversation']),
      );

  /// The account's id.
  final String id;

  /// The account's network.
  final String platform;

  /// The workspace it lives in.
  final String? workspaceId;

  /// The account's handle.
  final String? username;

  /// The account's display name.
  final String? name;

  /// The account's avatar URL.
  final String? avatar;

  /// Whether comments and mentions can be read for it.
  final bool? inboxSupported;

  /// Why comments are not available yet, when they are not.
  final String? pendingReason;

  /// Whether direct messages can be read for it.
  final bool? dmSupported;

  /// Why DMs are not available yet, when they are not.
  final String? dmPendingReason;

  /// Whether a new DM can be opened from it by handle.
  final bool? canStartConversation;

  @override
  String toString() => 'InboxAccount($platform, $id)';
}

/// What the inbox supports on one network.
class InboxPlatform {
  /// Creates a platform row.
  const InboxPlatform(
      {required this.platform, required this.comments, required this.dms});

  /// Reads a platform row.
  factory InboxPlatform.fromJson(Map<String, dynamic> json) => InboxPlatform(
        platform: asString(json['platform']) ?? '',
        comments: asString(json['comments']) ?? 'none',
        dms: asString(json['dms']) ?? 'none',
      );

  /// The network.
  final String platform;

  /// `live`, `soon` or `none`.
  final String comments;

  /// `live`, `soon` or `none`.
  final String dms;

  @override
  String toString() => 'InboxPlatform($platform)';
}

/// A drafted reply a person still has to send.
class InboxApproval {
  /// Creates an approval.
  const InboxApproval({
    required this.id,
    required this.reply,
    this.workspaceId,
    this.source,
    this.createdAt,
    this.item,
  });

  /// Reads an approval.
  factory InboxApproval.fromJson(Map<String, dynamic> json) => InboxApproval(
        id: asInt(json['id']) ?? 0,
        reply: asString(json['reply']) ?? '',
        workspaceId: asString(json['workspaceId']),
        source: asString(json['source']),
        createdAt: asDate(json['createdAt']),
        item: asMapOrNull(json['item']),
      );

  /// The approval's id.
  final int id;

  /// The drafted text.
  final String reply;

  /// The workspace it belongs to.
  final String? workspaceId;

  /// What drafted it.
  final String? source;

  /// When it was drafted.
  final DateTime? createdAt;

  /// The inbox item the reply answers.
  final Map<String, dynamic>? item;

  @override
  String toString() => 'InboxApproval($id)';
}

/// The outcome of approving or rejecting a drafted reply.
class InboxDecision {
  /// Creates a decision.
  const InboxDecision({required this.id, required this.outcome});

  /// Reads a decision.
  factory InboxDecision.fromJson(Map<String, dynamic> json) => InboxDecision(
        id: asInt(json['id']) ?? 0,
        outcome: asString(json['outcome']) ?? '',
      );

  /// The approval's id.
  final int id;

  /// What happened to it.
  final String outcome;

  @override
  String toString() => 'InboxDecision($id, $outcome)';
}

/// Where a reply landed on the platform.
class InboxReplyRef {
  /// Creates a reference.
  const InboxReplyRef({this.externalId, this.externalUrl});

  /// Reads a reference.
  factory InboxReplyRef.fromJson(Map<String, dynamic> json) => InboxReplyRef(
        externalId: asString(json['externalId']),
        externalUrl: asString(json['externalUrl']),
      );

  /// The reply's id on the platform.
  final String? externalId;

  /// The reply's URL on the platform.
  final String? externalUrl;

  @override
  String toString() => 'InboxReplyRef($externalId)';
}

/// What a reply produced: the updated item and where the reply landed.
class InboxReplyResult {
  /// Creates a result.
  const InboxReplyResult({required this.item, required this.reply});

  /// Reads a result.
  factory InboxReplyResult.fromJson(Map<String, dynamic> json) =>
      InboxReplyResult(
        item: InboxItem.fromJson(asMap(json['item'])),
        reply: InboxReplyRef.fromJson(asMap(json['reply'])),
      );

  /// The item, now marked replied.
  final InboxItem item;

  /// Where the reply landed.
  final InboxReplyRef reply;

  @override
  String toString() => 'InboxReplyResult(${item.id})';
}

/// What opening a DM produced.
class InboxConversationStart {
  /// Creates a result.
  const InboxConversationStart({this.conversationId, this.item});

  /// Reads a result.
  factory InboxConversationStart.fromJson(Map<String, dynamic> json) =>
      InboxConversationStart(
        conversationId: asString(json['conversationId']),
        item: json['item'] is Map
            ? InboxItem.fromJson(asMap(json['item']))
            : null,
      );

  /// The DM thread the message opened, when the platform returned one.
  final String? conversationId;

  /// The message that was sent, when it was stored.
  final InboxItem? item;

  @override
  String toString() => 'InboxConversationStart($conversationId)';
}

/// An account whose DM access must be granted again.
class InboxDmReconnect {
  /// Creates a reconnect notice.
  const InboxDmReconnect({required this.platform, required this.account});

  /// Reads a reconnect notice.
  factory InboxDmReconnect.fromJson(Map<String, dynamic> json) =>
      InboxDmReconnect(
        platform: asString(json['platform']) ?? '',
        account: asString(json['account']) ?? '',
      );

  /// The network.
  final String platform;

  /// The account that needs reconnecting.
  final String account;

  @override
  String toString() => 'InboxDmReconnect($platform, $account)';
}

/// What a manual inbox refresh did.
class InboxRefreshResult {
  /// Creates a result.
  const InboxRefreshResult({
    this.accountsPolled = 0,
    this.newItems = 0,
    this.rateLimited = 0,
    this.dmReconnect = const [],
  });

  /// Reads a result.
  factory InboxRefreshResult.fromJson(Map<String, dynamic> json) =>
      InboxRefreshResult(
        accountsPolled: asInt(json['accountsPolled']) ?? 0,
        newItems: asInt(json['newItems']) ?? 0,
        rateLimited: asInt(json['rateLimited']) ?? 0,
        dmReconnect:
            asModelList(json['dmReconnect'], InboxDmReconnect.fromJson),
      );

  /// How many accounts were polled.
  final int accountsPolled;

  /// How many new items arrived.
  final int newItems;

  /// How many accounts the platform rate-limited.
  final int rateLimited;

  /// Accounts whose DM access must be granted again.
  final List<InboxDmReconnect> dmReconnect;

  @override
  String toString() => 'InboxRefreshResult($newItems new)';
}

InboxPostContext? _postContext(Object? value) =>
    value is Map ? InboxPostContext.fromJson(asMap(value)) : null;

InboxAccountRef? _accountRef(Object? value) =>
    value is Map ? InboxAccountRef.fromJson(asMap(value)) : null;
