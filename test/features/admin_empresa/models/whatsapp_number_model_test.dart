import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/features/admin_empresa/src/models/whatsapp_number_model.dart';

void main() {
  group('MetaQualityRating Enum Tests', () {
    test('fromString parses all valid case variations and defaults to unknown', () {
      expect(MetaQualityRating.fromString('GREEN'), equals(MetaQualityRating.green));
      expect(MetaQualityRating.fromString('green'), equals(MetaQualityRating.green));
      expect(MetaQualityRating.fromString('  Yellow  '), equals(MetaQualityRating.yellow));
      expect(MetaQualityRating.fromString('RED'), equals(MetaQualityRating.red));
      expect(MetaQualityRating.fromString('INVALID'), equals(MetaQualityRating.unknown));
      expect(MetaQualityRating.fromString(null), equals(MetaQualityRating.unknown));
    });

    test('toApiValue produces uppercase string matching Meta API', () {
      expect(MetaQualityRating.green.toApiValue(), equals('GREEN'));
      expect(MetaQualityRating.yellow.toApiValue(), equals('YELLOW'));
      expect(MetaQualityRating.red.toApiValue(), equals('RED'));
      expect(MetaQualityRating.unknown.toApiValue(), equals('UNKNOWN'));
    });

    test('UI getters return valid labels and distinct colors', () {
      for (final rating in MetaQualityRating.values) {
        expect(rating.label, isNotEmpty);
        expect(rating.badgeLabel, isNotEmpty);
        expect(rating.color, isA<Color>());
        expect(rating.backgroundColor, isA<Color>());
        expect(rating.borderColor, isA<Color>());
      }
    });
  });

  group('MetaMessagingTier Enum Tests', () {
    test('fromString parses all tiers and defaults to unknown', () {
      expect(MetaMessagingTier.fromString('TIER_50'), equals(MetaMessagingTier.tier50));
      expect(MetaMessagingTier.fromString('tier_250'), equals(MetaMessagingTier.tier250));
      expect(MetaMessagingTier.fromString('TIER_1K'), equals(MetaMessagingTier.tier1k));
      expect(MetaMessagingTier.fromString('TIER_10K'), equals(MetaMessagingTier.tier10k));
      expect(MetaMessagingTier.fromString('TIER_100K'), equals(MetaMessagingTier.tier100k));
      expect(MetaMessagingTier.fromString('TIER_UNLIMITED'), equals(MetaMessagingTier.tierUnlimited));
      expect(MetaMessagingTier.fromString('OTHER'), equals(MetaMessagingTier.unknown));
      expect(MetaMessagingTier.fromString(null), equals(MetaMessagingTier.unknown));
    });

    test('toApiValue produces uppercase string', () {
      expect(MetaMessagingTier.tier50.toApiValue(), equals('TIER_50'));
      expect(MetaMessagingTier.tier1k.toApiValue(), equals('TIER_1K'));
      expect(MetaMessagingTier.tierUnlimited.toApiValue(), equals('TIER_UNLIMITED'));
    });

    test('maxConversationsPer24h matches Meta tier limits', () {
      expect(MetaMessagingTier.tier50.maxConversationsPer24h, equals(50));
      expect(MetaMessagingTier.tier250.maxConversationsPer24h, equals(250));
      expect(MetaMessagingTier.tier1k.maxConversationsPer24h, equals(1000));
      expect(MetaMessagingTier.tier10k.maxConversationsPer24h, equals(10000));
      expect(MetaMessagingTier.tier100k.maxConversationsPer24h, equals(100000));
      expect(MetaMessagingTier.tierUnlimited.maxConversationsPer24h, equals(1000000));
      expect(MetaMessagingTier.unknown.maxConversationsPer24h, equals(0));
    });

    test('UI labels and badgeText are non-empty', () {
      for (final tier in MetaMessagingTier.values) {
        expect(tier.label, isNotEmpty);
        expect(tier.badgeText, isNotEmpty);
      }
    });
  });

  group('WhatsAppNumberModel Domain Tests', () {
    final now = DateTime(2026, 11, 8, 12, 0);

    final sampleModel = WhatsAppNumberModel(
      id: '109283746511223',
      tenantId: 'tenant_epi_01',
      wabaId: '998877665544332',
      phoneNumberId: '109283746511223',
      displayPhoneNumber: '+55 11 98877-6655',
      verifiedName: 'EPI Forte Comercial',
      qualityRating: MetaQualityRating.green,
      messagingLimitTier: MetaMessagingTier.tier1k,
      codeVerificationStatus: 'VERIFIED',
      status: 'connected',
      webhookSubscribed: true,
      isDefault: true,
      iaAtivaNesteNumero: true,
      connectedByUid: 'user_123',
      connectedAt: now,
      lastSyncAt: now,
    );

    test('Operational getters reflect connection and verification status correctly', () {
      expect(sampleModel.isOperational, isTrue);
      expect(sampleModel.isHighQuality, isTrue);
      expect(sampleModel.isVerified, isTrue);
      expect(sampleModel.isDisconnected, isFalse);
      expect(sampleModel.statusLabel, equals('Conectado'));
      expect(sampleModel.statusColor, equals(const Color(0xFF16A34A)));

      final disconnected = sampleModel.copyWith(status: 'disconnected', webhookSubscribed: false);
      expect(disconnected.isOperational, isFalse);
      expect(disconnected.isDisconnected, isTrue);
      expect(disconnected.statusLabel, equals('Desconectado'));
      expect(disconnected.statusColor, equals(const Color(0xFFDC2626)));
    });

    test('Serialization toMap and toFirestoreMap round-trip cleanly', () {
      final map = sampleModel.toMap();
      expect(map['id'], equals('109283746511223'));
      expect(map['quality_rating'], equals('GREEN'));
      expect(map['messaging_limit_tier'], equals('TIER_1K'));
      expect(map['connected_at'], isA<Timestamp>());

      final firestoreMap = sampleModel.toFirestoreMap();
      expect(firestoreMap['connected_at'], equals(now.toIso8601String()));

      final reconstructed = WhatsAppNumberModel.fromMap(firestoreMap);
      expect(reconstructed.id, equals(sampleModel.id));
      expect(reconstructed.displayPhoneNumber, equals(sampleModel.displayPhoneNumber));
      expect(reconstructed.qualityRating, equals(sampleModel.qualityRating));
      expect(reconstructed.messagingLimitTier, equals(sampleModel.messagingLimitTier));
    });

    test('fromMap handles both camelCase and snake_case keys resiliently', () {
      final camelData = {
        'id': 'phone_camel_1',
        'tenantId': 'tenant_01',
        'wabaId': 'waba_01',
        'phoneNumberId': 'phone_camel_1',
        'displayPhoneNumber': '+55 11 9999-8888',
        'verifiedName': 'Camel Case Name',
        'qualityRating': 'YELLOW',
        'messagingLimitTier': 'TIER_50',
        'codeVerificationStatus': 'VERIFIED',
        'status': 'connected',
        'webhookSubscribed': true,
        'isDefault': false,
        'iaAtiva': false,
        'connectedAt': now.toIso8601String(),
        'lastSyncAt': now.toIso8601String(),
      };

      final model = WhatsAppNumberModel.fromMap(camelData);
      expect(model.id, equals('phone_camel_1'));
      expect(model.verifiedName, equals('Camel Case Name'));
      expect(model.qualityRating, equals(MetaQualityRating.yellow));
      expect(model.messagingLimitTier, equals(MetaMessagingTier.tier50));
      expect(model.iaAtivaNesteNumero, isFalse);
    });

    test('Resilient date parser converts Timestamp, DateTime, String, int and null', () {
      final dataWithTimestamp = {
        'id': 'p1',
        'connected_at': Timestamp.fromDate(now),
        'last_sync_at': now,
      };
      final m1 = WhatsAppNumberModel.fromMap(dataWithTimestamp);
      expect(m1.connectedAt.year, equals(2026));

      final dataWithEpoch = {
        'id': 'p2',
        'connected_at': now.millisecondsSinceEpoch,
        'last_sync_at': null,
      };
      final m2 = WhatsAppNumberModel.fromMap(dataWithEpoch);
      expect(m2.connectedAt.year, equals(2026));
    });

    test('copyWith creates modified instance preserving other fields', () {
      final updated = sampleModel.copyWith(
        verifiedName: 'Novo Nome Comercial',
        iaAtivaNesteNumero: false,
      );

      expect(updated.verifiedName, equals('Novo Nome Comercial'));
      expect(updated.iaAtivaNesteNumero, isFalse);
      expect(updated.id, equals(sampleModel.id));
      expect(updated.qualityRating, equals(sampleModel.qualityRating));
    });

    test('Value equality and hashCode contract', () {
      final clone = sampleModel.copyWith();
      expect(clone, equals(sampleModel));
      expect(clone.hashCode, equals(sampleModel.hashCode));

      final different = sampleModel.copyWith(id: 'different_id');
      expect(different, isNot(equals(sampleModel)));
    });
  });
}
