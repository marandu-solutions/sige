/// Modelo de endereço estruturado para Clientes PJ e PF
class ClientAddressModel {
  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String uf;

  const ClientAddressModel({
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });

  factory ClientAddressModel.fromMap(Map<String, dynamic> map) {
    String parseStr(dynamic v) => v == null ? '' : v.toString().trim();
    return ClientAddressModel(
      cep: parseStr(map['cep']),
      logradouro: parseStr(map['logradouro']),
      numero: parseStr(map['numero']),
      complemento:
          map['complemento'] != null ? parseStr(map['complemento']) : null,
      bairro: parseStr(map['bairro']),
      cidade: parseStr(map['cidade']),
      uf: parseStr(map['uf']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'uf': uf,
    };
  }

  String get formatado {
    if (logradouro.isEmpty) return 'Endereço não informado';
    final comp = (complemento != null && complemento!.isNotEmpty)
        ? ' - $complemento'
        : '';
    final numStr = numero.isNotEmpty ? ', $numero' : ', S/N';
    return '$logradouro$numStr$comp - $bairro, $cidade/$uf (CEP: $cep)';
  }
}
