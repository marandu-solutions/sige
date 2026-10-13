import 'package:cloud_firestore/cloud_firestore.dart';

class TenantModel {
  final String id;
  final String nomeFantasia;
  final String documentoFiscal;
  final String status;
  final List<String> modulosAtivos;
  final Map<String, dynamic> config;
  final int tempoAtendimento;
  final Map<String, dynamic> branding;
  final Map<String, dynamic> kanbanConfig;
  final Map<String, dynamic> iaConfig;

  TenantModel({
    required this.id,
    required this.nomeFantasia,
    required this.documentoFiscal,
    required this.status,
    required this.modulosAtivos,
    required this.config,
    this.tempoAtendimento = 0,
    this.branding = const {},
    this.kanbanConfig = const {},
    this.iaConfig = const {},
  });

  factory TenantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TenantModel.fromMap(data, doc.id);
  }

  factory TenantModel.fromMap(Map<String, dynamic> map, [String? id]) {
    final configMap = Map<String, dynamic>.from(map['config'] ?? {});

    // Branding can be top-level or nested in config
    final brandingMap = Map<String, dynamic>.from(
      map['branding'] ?? configMap['branding'] ?? {},
    );

    // Kanban config can be top-level or nested in config
    final kanbanConfigMap = Map<String, dynamic>.from(
      map['kanban_config'] ?? configMap['kanban_config'] ?? {},
    );

    // IA config can be top-level or nested in config
    final iaConfigMap = Map<String, dynamic>.from(
      map['ia_config'] ?? configMap['ia_config'] ?? {},
    );

    return TenantModel(
      id: id ?? map['id'] ?? map['tenant_id'] ?? '',
      nomeFantasia: map['nome_fantasia'] ?? map['nome'] ?? '',
      documentoFiscal: map['documento_fiscal'] ?? '',
      status: map['status'] ?? 'ativo',
      modulosAtivos: List<String>.from(map['modulos_ativos'] ?? []),
      config: configMap,
      tempoAtendimento: map['tempo_atendimento'] ?? 0,
      branding: brandingMap,
      kanbanConfig: kanbanConfigMap,
      iaConfig: iaConfigMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tenant_id': id,
      'nome_fantasia': nomeFantasia,
      'documento_fiscal': documentoFiscal,
      'status': status,
      'modulos_ativos': modulosAtivos,
      'config': config,
      'tempo_atendimento': tempoAtendimento,
      'branding': branding,
      'kanban_config': kanbanConfig,
      'ia_config': iaConfig,
    };
  }

  String? get corPrimaria => branding['cor_primaria'] as String?;
  String? get logoUrl => branding['logo_url'] as String?;

  bool hasModulo(String modulo) {
    if (modulosAtivos.contains(modulo)) return true;
    if (modulo.startsWith('module_') && modulosAtivos.contains(modulo.replaceFirst('module_', ''))) {
      return true;
    }
    if (!modulo.startsWith('module_') && modulosAtivos.contains('module_$modulo')) {
      return true;
    }
    return false;
  }

  TenantModel copyWith({
    String? id,
    String? nomeFantasia,
    String? documentoFiscal,
    String? status,
    List<String>? modulosAtivos,
    Map<String, dynamic>? config,
    int? tempoAtendimento,
    Map<String, dynamic>? branding,
    Map<String, dynamic>? kanbanConfig,
    Map<String, dynamic>? iaConfig,
  }) {
    return TenantModel(
      id: id ?? this.id,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      documentoFiscal: documentoFiscal ?? this.documentoFiscal,
      status: status ?? this.status,
      modulosAtivos: modulosAtivos ?? this.modulosAtivos,
      config: config ?? this.config,
      tempoAtendimento: tempoAtendimento ?? this.tempoAtendimento,
      branding: branding ?? this.branding,
      kanbanConfig: kanbanConfig ?? this.kanbanConfig,
      iaConfig: iaConfig ?? this.iaConfig,
    );
  }
}
