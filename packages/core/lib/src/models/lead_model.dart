class LeadModel {
  final String id;
  final String tenantId;
  final String nome;
  final String telefone;
  final String origem;
  final String status;
  final DateTime dataCriacao;
  final String? observacoes;
  final String? funcionarioResponsavelNome;
  final String? funcionarioId;
  final String? fotoUrl;

  // Extension map to hold module-specific data without changing the core model
  final Map<String, dynamic> metadata;

  LeadModel({
    required this.id,
    required this.tenantId,
    required this.nome,
    required this.telefone,
    required this.origem,
    required this.status,
    required this.dataCriacao,
    this.observacoes,
    this.funcionarioResponsavelNome,
    this.funcionarioId,
    this.fotoUrl,
    this.metadata = const {},
  });

  factory LeadModel.fromMap(Map<String, dynamic> map, [String? id]) {
    // Helper function to safely parse dates regardless of origin (Firestore, JSON, etc)
    DateTime parseDate(dynamic dateData) {
      if (dateData == null) return DateTime.now();
      if (dateData is DateTime) return dateData;
      // Handle Firestore Timestamp dynamically without importing cloud_firestore
      if (dateData.runtimeType.toString() == 'Timestamp') {
        try {
          return dateData.toDate();
        } catch (_) {}
      }
      if (dateData is String) {
        return DateTime.tryParse(dateData) ?? DateTime.now();
      }
      if (dateData is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateData);
      }
      return DateTime.now();
    }

    // Extract core fields to separate them from metadata
    final coreKeys = {
      'id',
      'tenant_id',
      'nome',
      'telefone',
      'origem',
      'status',
      'data_criacao',
      'observacoes',
      'funcionarioResponsavelNome',
      'funcionario',
      'funcionarioId',
      'fotoUrl',
      'metadata'
    };

    // Any field not in coreKeys goes into metadata
    final Map<String, dynamic> extractedMetadata = map.containsKey('metadata')
        ? Map<String, dynamic>.from(map['metadata'] as Map)
        : {};

    map.forEach((key, value) {
      if (!coreKeys.contains(key)) {
        extractedMetadata[key] = value;
      }
    });

    return LeadModel(
      id: id ?? map['id'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      origem: map['origem'] ?? 'Outros',
      status: map['status'] ?? 'Novo',
      dataCriacao: parseDate(map['data_criacao']),
      observacoes: map['observacoes'],
      funcionarioResponsavelNome:
          map['funcionarioResponsavelNome'] ?? map['funcionario'],
      funcionarioId: map['funcionarioId'],
      fotoUrl: map['fotoUrl'],
      metadata: extractedMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'tenant_id': tenantId,
      'nome': nome,
      'telefone': telefone,
      'origem': origem,
      'status': status,
      // Pass DateTime directly. The Data Mapper/Repository should convert it to Timestamp if using Firestore
      'data_criacao': dataCriacao,
      'observacoes': observacoes,
      'funcionarioResponsavelNome': funcionarioResponsavelNome,
      'funcionarioId': funcionarioId,
      'fotoUrl': fotoUrl,
      'metadata': metadata,
    };

    // Also flatten metadata into the main map for NoSQL databases that prefer flat structures
    metadata.forEach((key, value) {
      if (!map.containsKey(key)) {
        map[key] = value;
      }
    });

    return map;
  }

  LeadModel copyWith({
    String? id,
    String? tenantId,
    String? nome,
    String? telefone,
    String? origem,
    String? status,
    DateTime? dataCriacao,
    String? observacoes,
    String? funcionarioResponsavelNome,
    String? funcionarioId,
    String? fotoUrl,
    Map<String, dynamic>? metadata,
  }) {
    return LeadModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      origem: origem ?? this.origem,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      observacoes: observacoes ?? this.observacoes,
      funcionarioResponsavelNome:
          funcionarioResponsavelNome ?? this.funcionarioResponsavelNome,
      funcionarioId: funcionarioId ?? this.funcionarioId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper to get a specific metadata value
  T? getMeta<T>(String key) {
    if (metadata.containsKey(key)) {
      return metadata[key] as T?;
    }
    return null;
  }

  /// Helper to set/update a specific metadata value, returning a new instance
  LeadModel copyWithMeta(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }
}
