import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Meta WhatsApp Quality Rating for business phone numbers.
/// Reference: Meta Graph API v21.0 & MD07 §4.1
enum MetaQualityRating {
  green,
  yellow,
  red,
  unknown;

  /// Resilient parser converting string values (case-insensitive) to enum
  static MetaQualityRating fromString(String? value) {
    switch (value?.toUpperCase().trim()) {
      case 'GREEN':
        return MetaQualityRating.green;
      case 'YELLOW':
        return MetaQualityRating.yellow;
      case 'RED':
        return MetaQualityRating.red;
      default:
        return MetaQualityRating.unknown;
    }
  }

  /// Uppercase string representation matching Meta Graph API
  String toApiValue() => name.toUpperCase();

  /// Portuguese descriptive label
  String get label {
    switch (this) {
      case MetaQualityRating.green:
        return 'Alta';
      case MetaQualityRating.yellow:
        return 'Média';
      case MetaQualityRating.red:
        return 'Baixa';
      case MetaQualityRating.unknown:
        return 'Desconhecida';
    }
  }

  /// Full badge label with status icon
  String get badgeLabel {
    switch (this) {
      case MetaQualityRating.green:
        return '🟢 ALTA (GREEN)';
      case MetaQualityRating.yellow:
        return '🟡 MÉDIA (YELLOW)';
      case MetaQualityRating.red:
        return '🔴 BAIXA (RED)';
      case MetaQualityRating.unknown:
        return '⚪ DESCONHECIDA';
    }
  }

  /// Primary color for UI chip and icon
  Color get color {
    switch (this) {
      case MetaQualityRating.green:
        return const Color(0xFF16A34A); // Emerald/Green-600
      case MetaQualityRating.yellow:
        return const Color(0xFFCA8A04); // Yellow-600
      case MetaQualityRating.red:
        return const Color(0xFFDC2626); // Red-600
      case MetaQualityRating.unknown:
        return const Color(0xFF64748B); // Slate-500
    }
  }

  /// Tint background color for UI badges
  Color get backgroundColor {
    switch (this) {
      case MetaQualityRating.green:
        return const Color(0xFFDCFCE7); // Green-100
      case MetaQualityRating.yellow:
        return const Color(0xFFFEF9C3); // Yellow-100
      case MetaQualityRating.red:
        return const Color(0xFFFEE2E2); // Red-100
      case MetaQualityRating.unknown:
        return const Color(0xFFF1F5F9); // Slate-100
    }
  }

  /// Border color for UI chips
  Color get borderColor {
    switch (this) {
      case MetaQualityRating.green:
        return const Color(0xFF86EFAC); // Green-300
      case MetaQualityRating.yellow:
        return const Color(0xFFFDE047); // Yellow-300
      case MetaQualityRating.red:
        return const Color(0xFFFCA5A5); // Red-300
      case MetaQualityRating.unknown:
        return const Color(0xFFCBD5E1); // Slate-300
    }
  }
}

/// Meta WhatsApp Messaging Limit Tier (24h rolling conversation limit).
/// Reference: Meta Graph API v21.0 & MD07 §4.1
enum MetaMessagingTier {
  tier50,
  tier250,
  tier1k,
  tier10k,
  tier100k,
  tierUnlimited,
  unknown;

  /// Resilient parser converting string values (case-insensitive) to enum
  static MetaMessagingTier fromString(String? value) {
    switch (value?.toUpperCase().trim()) {
      case 'TIER_50':
        return MetaMessagingTier.tier50;
      case 'TIER_250':
        return MetaMessagingTier.tier250;
      case 'TIER_1K':
        return MetaMessagingTier.tier1k;
      case 'TIER_10K':
        return MetaMessagingTier.tier10k;
      case 'TIER_100K':
        return MetaMessagingTier.tier100k;
      case 'TIER_UNLIMITED':
        return MetaMessagingTier.tierUnlimited;
      default:
        return MetaMessagingTier.unknown;
    }
  }

  /// Uppercase string representation matching Meta Graph API
  String toApiValue() {
    switch (this) {
      case MetaMessagingTier.tier50:
        return 'TIER_50';
      case MetaMessagingTier.tier250:
        return 'TIER_250';
      case MetaMessagingTier.tier1k:
        return 'TIER_1K';
      case MetaMessagingTier.tier10k:
        return 'TIER_10K';
      case MetaMessagingTier.tier100k:
        return 'TIER_100K';
      case MetaMessagingTier.tierUnlimited:
        return 'TIER_UNLIMITED';
      case MetaMessagingTier.unknown:
        return 'UNKNOWN';
    }
  }

  /// Maximum business-initiated conversations allowed per rolling 24 hours
  int get maxConversationsPer24h {
    switch (this) {
      case MetaMessagingTier.tier50:
        return 50;
      case MetaMessagingTier.tier250:
        return 250;
      case MetaMessagingTier.tier1k:
        return 1000;
      case MetaMessagingTier.tier100k:
        return 100000;
      case MetaMessagingTier.tier10k:
        return 10000;
      case MetaMessagingTier.tierUnlimited:
        return 1000000;
      case MetaMessagingTier.unknown:
        return 0;
    }
  }

  /// Portuguese descriptive label for UI
  String get label {
    switch (this) {
      case MetaMessagingTier.tier50:
        return '50 conversas/24h (TIER_50)';
      case MetaMessagingTier.tier250:
        return '250 conversas/24h (TIER_250)';
      case MetaMessagingTier.tier1k:
        return '1.000 conversas/24h (TIER_1K)';
      case MetaMessagingTier.tier10k:
        return '10.000 conversas/24h (TIER_10K)';
      case MetaMessagingTier.tier100k:
        return '100.000 conversas/24h (TIER_100K)';
      case MetaMessagingTier.tierUnlimited:
        return 'Ilimitado (TIER_UNLIMITED)';
      case MetaMessagingTier.unknown:
        return 'Limite desconhecido';
    }
  }

  /// Short badge label for card headers
  String get badgeText {
    switch (this) {
      case MetaMessagingTier.tier50:
        return '⚡ 50/dia';
      case MetaMessagingTier.tier250:
        return '⚡ 250/dia';
      case MetaMessagingTier.tier1k:
        return '⚡ 1.000/dia';
      case MetaMessagingTier.tier10k:
        return '🚀 10.000/dia';
      case MetaMessagingTier.tier100k:
        return '🚀 100.000/dia';
      case MetaMessagingTier.tierUnlimited:
        return '♾️ Ilimitado';
      case MetaMessagingTier.unknown:
        return 'N/A';
    }
  }
}

/// Domain model representing an official Meta WhatsApp Business phone number
/// connected to a tenant (`tenant/{tenantId}/whatsapp_numbers/{phoneNumberId}`).
/// Reference: MD07 §4.1, PROJECT.md Feature #16
class WhatsAppNumberModel {
  /// Unique document ID (matches [phoneNumberId])
  final String id;

  /// Identifier of the tenant owning this number
  final String tenantId;

  /// WhatsApp Business Account ID (WABA) from Meta
  final String wabaId;

  /// WhatsApp Phone Number ID from Meta
  final String phoneNumberId;

  /// Official formatted phone number returned by Meta (e.g. `+55 11 98877-6655`)
  final String displayPhoneNumber;

  /// Officially verified business display name approved by Meta
  final String verifiedName;

  /// Current Meta quality rating (GREEN, YELLOW, RED, UNKNOWN)
  final MetaQualityRating qualityRating;

  /// Current 24h messaging limit tier
  final MetaMessagingTier messagingLimitTier;

  /// Code verification status (e.g. `VERIFIED`, `NOT_VERIFIED`)
  final String codeVerificationStatus;

  /// Overall operational status (`connected`, `disconnected`, `pending`)
  final String status;

  /// Whether the WABA is subscribed to webhooks via `subscribed_apps`
  final bool webhookSubscribed;

  /// Whether this number is the primary default communication channel for the tenant
  final bool isDefault;

  /// Whether AI automation (bot 24/7) is active on this specific number
  final bool iaAtivaNesteNumero;

  /// Firebase Auth UID of the manager who connected the number
  final String connectedByUid;

  /// When this number was first connected
  final DateTime connectedAt;

  /// When metadata was last synchronized with Meta Graph API
  final DateTime lastSyncAt;

  /// When this Firestore document was last updated
  final DateTime? updatedAt;

  const WhatsAppNumberModel({
    required this.id,
    required this.tenantId,
    required this.wabaId,
    required this.phoneNumberId,
    required this.displayPhoneNumber,
    required this.verifiedName,
    required this.qualityRating,
    required this.messagingLimitTier,
    this.codeVerificationStatus = 'VERIFIED',
    this.status = 'connected',
    this.webhookSubscribed = true,
    this.isDefault = false,
    this.iaAtivaNesteNumero = true,
    this.connectedByUid = '',
    required this.connectedAt,
    required this.lastSyncAt,
    this.updatedAt,
  });

  /// True if the number is connected and receiving webhooks
  bool get isOperational => status == 'connected' && webhookSubscribed;

  /// True if Meta quality rating is green
  bool get isHighQuality => qualityRating == MetaQualityRating.green;

  /// True if phone number code is officially verified by Meta
  bool get isVerified => codeVerificationStatus.toUpperCase() == 'VERIFIED';

  /// True if the number is disconnected or paused
  bool get isDisconnected => status != 'connected';

  /// User-friendly Portuguese status text
  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'connected':
        return 'Conectado';
      case 'disconnected':
        return 'Desconectado';
      case 'pending':
        return 'Pendente';
      default:
        return status;
    }
  }

  /// UI color representing operational connection state
  Color get statusColor =>
      isOperational ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  /// Helper to parse multiple date representations (Timestamp, DateTime, String, int)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  /// Constructs a [WhatsAppNumberModel] from a generic data map (snake_case or camelCase).
  factory WhatsAppNumberModel.fromMap(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    final effectiveId = docId ??
        data['id'] as String? ??
        data['phone_number_id'] as String? ??
        data['phoneNumberId'] as String? ??
        '';

    return WhatsAppNumberModel(
      id: effectiveId,
      tenantId: data['tenant_id'] as String? ?? data['tenantId'] as String? ?? '',
      wabaId: data['waba_id'] as String? ?? data['wabaId'] as String? ?? '',
      phoneNumberId: data['phone_number_id'] as String? ??
          data['phoneNumberId'] as String? ??
          effectiveId,
      displayPhoneNumber: data['display_phone_number'] as String? ??
          data['displayPhoneNumber'] as String? ??
          '',
      verifiedName: data['verified_name'] as String? ??
          data['verifiedName'] as String? ??
          'WhatsApp Business',
      qualityRating: MetaQualityRating.fromString(
        data['quality_rating'] as String? ?? data['qualityRating'] as String?,
      ),
      messagingLimitTier: MetaMessagingTier.fromString(
        data['messaging_limit_tier'] as String? ??
            data['messagingLimitTier'] as String?,
      ),
      codeVerificationStatus: data['code_verification_status'] as String? ??
          data['codeVerificationStatus'] as String? ??
          'VERIFIED',
      status: data['status'] as String? ?? 'connected',
      webhookSubscribed: data['webhook_subscribed'] as bool? ??
          data['webhookSubscribed'] as bool? ??
          false,
      isDefault: data['is_default'] as bool? ?? data['isDefault'] as bool? ?? false,
      iaAtivaNesteNumero: data['ia_ativa_neste_numero'] as bool? ??
          data['iaAtivaNesteNumero'] as bool? ??
          data['ia_ativa'] as bool? ??
          data['iaAtiva'] as bool? ??
          true,
      connectedByUid: data['connected_by_uid'] as String? ??
          data['connectedByUid'] as String? ??
          '',
      connectedAt: _parseDateTime(data['connected_at'] ?? data['connectedAt']),
      lastSyncAt: _parseDateTime(data['last_sync_at'] ?? data['lastSyncAt']),
      updatedAt: data['updated_at'] != null || data['updatedAt'] != null
          ? _parseDateTime(data['updated_at'] ?? data['updatedAt'])
          : null,
    );
  }

  /// Factory for Firestore DocumentSnapshot
  factory WhatsAppNumberModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WhatsAppNumberModel.fromMap(doc.data() ?? {}, doc.id);
  }

  /// Factory for contract/fixture compatibility
  factory WhatsAppNumberModel.fromFirestoreMap(
    String docId,
    Map<String, dynamic> data,
  ) {
    return WhatsAppNumberModel.fromMap(data, docId);
  }

  /// Converts the model to a Firestore-compliant map with snake_case keys.
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'id': id,
      'tenant_id': tenantId,
      'waba_id': wabaId,
      'phone_number_id': phoneNumberId,
      'display_phone_number': displayPhoneNumber,
      'verified_name': verifiedName,
      'quality_rating': qualityRating.toApiValue(),
      'messaging_limit_tier': messagingLimitTier.toApiValue(),
      'code_verification_status': codeVerificationStatus,
      'status': status,
      'webhook_subscribed': webhookSubscribed,
      'is_default': isDefault,
      'ia_ativa_neste_numero': iaAtivaNesteNumero,
      'connected_by_uid': connectedByUid,
      'connected_at': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(connectedAt),
      'last_sync_at': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(lastSyncAt),
      if (updatedAt != null || useServerTimestamp)
        'updated_at': useServerTimestamp
            ? FieldValue.serverTimestamp()
            : (updatedAt != null ? Timestamp.fromDate(updatedAt!) : Timestamp.now()),
    };
  }

  /// Serialization to primitive map for tests and JSON serialization
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'waba_id': wabaId,
      'phone_number_id': phoneNumberId,
      'display_phone_number': displayPhoneNumber,
      'verified_name': verifiedName,
      'quality_rating': qualityRating.toApiValue(),
      'messaging_limit_tier': messagingLimitTier.toApiValue(),
      'code_verification_status': codeVerificationStatus,
      'status': status,
      'webhook_subscribed': webhookSubscribed,
      'is_default': isDefault,
      'ia_ativa_neste_numero': iaAtivaNesteNumero,
      'connected_by_uid': connectedByUid,
      'connected_at': connectedAt.toIso8601String(),
      'last_sync_at': lastSyncAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Immutability copyWith helper
  WhatsAppNumberModel copyWith({
    String? id,
    String? tenantId,
    String? wabaId,
    String? phoneNumberId,
    String? displayPhoneNumber,
    String? verifiedName,
    MetaQualityRating? qualityRating,
    MetaMessagingTier? messagingLimitTier,
    String? codeVerificationStatus,
    String? status,
    bool? webhookSubscribed,
    bool? isDefault,
    bool? iaAtivaNesteNumero,
    String? connectedByUid,
    DateTime? connectedAt,
    DateTime? lastSyncAt,
    DateTime? updatedAt,
  }) {
    return WhatsAppNumberModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      wabaId: wabaId ?? this.wabaId,
      phoneNumberId: phoneNumberId ?? this.phoneNumberId,
      displayPhoneNumber: displayPhoneNumber ?? this.displayPhoneNumber,
      verifiedName: verifiedName ?? this.verifiedName,
      qualityRating: qualityRating ?? this.qualityRating,
      messagingLimitTier: messagingLimitTier ?? this.messagingLimitTier,
      codeVerificationStatus: codeVerificationStatus ?? this.codeVerificationStatus,
      status: status ?? this.status,
      webhookSubscribed: webhookSubscribed ?? this.webhookSubscribed,
      isDefault: isDefault ?? this.isDefault,
      iaAtivaNesteNumero: iaAtivaNesteNumero ?? this.iaAtivaNesteNumero,
      connectedByUid: connectedByUid ?? this.connectedByUid,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WhatsAppNumberModel &&
        other.id == id &&
        other.tenantId == tenantId &&
        other.wabaId == wabaId &&
        other.phoneNumberId == phoneNumberId &&
        other.displayPhoneNumber == displayPhoneNumber &&
        other.verifiedName == verifiedName &&
        other.qualityRating == qualityRating &&
        other.messagingLimitTier == messagingLimitTier &&
        other.codeVerificationStatus == codeVerificationStatus &&
        other.status == status &&
        other.webhookSubscribed == webhookSubscribed &&
        other.isDefault == isDefault &&
        other.iaAtivaNesteNumero == iaAtivaNesteNumero &&
        other.connectedByUid == connectedByUid;
  }

  @override
  int get hashCode => Object.hash(
        id,
        tenantId,
        wabaId,
        phoneNumberId,
        displayPhoneNumber,
        verifiedName,
        qualityRating,
        messagingLimitTier,
        codeVerificationStatus,
        status,
        webhookSubscribed,
        isDefault,
        iaAtivaNesteNumero,
        connectedByUid,
      );

  @override
  String toString() {
    return 'WhatsAppNumberModel(id: $id, phone: $displayPhoneNumber, name: $verifiedName, quality: ${qualityRating.name}, tier: ${messagingLimitTier.name}, operational: $isOperational)';
  }
}

/// Compatibility typedef matching contract nomenclature in test suites
typedef WhatsAppNumberModelContract = WhatsAppNumberModel;
