class ConsumoAgua {
  String data;
  double quantidadeEmMl;
  double pesoAtualKg;

  ConsumoAgua({
    required this.data,
    required this.quantidadeEmMl,
    required this.pesoAtualKg,
  });

  double get metaDiariaMl => pesoAtualKg * 35;

  double get percentualMetaAtingida {
    if (metaDiariaMl == 0) return 0;
    return (quantidadeEmMl / metaDiariaMl) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'quantidadeEmMl': quantidadeEmMl,
      'pesoAtualKg': pesoAtualKg,
    };
  }

  factory ConsumoAgua.fromJson(Map<String, dynamic> json) {
    return ConsumoAgua(
      data: json['data']?.toString() ?? '',
      quantidadeEmMl:
          double.tryParse(json['quantidadeEmMl'].toString()) ?? 0,
      pesoAtualKg: double.tryParse(json['pesoAtualKg'].toString()) ?? 0,
    );
  }
}
