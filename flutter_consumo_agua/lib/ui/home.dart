import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/caminhadas.dart';
import '../root/file.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<ConsumoAgua> registros = [];

  String data = "";
  String quantidadeEmMl = "";
  String pesoAtualKg = "";

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  String _hojeFormatado() {
    final agora = DateTime.now();
    final dia = agora.day.toString().padLeft(2, '0');
    final mes = agora.month.toString().padLeft(2, '0');
    return '$dia/$mes/${agora.year}';
  }

  double _toDouble(String valor) {
    return double.tryParse(valor.replaceAll(',', '.')) ?? 0;
  }

  Future<void> carregarDados() async {
    final conteudo = await GerenciarArquivo.abrir();
    if (conteudo.isEmpty) {
      if (!mounted) return;
      setState(() {
        registros = [];
      });
      return;
    }

    final dados = jsonDecode(conteudo) as List<dynamic>;
    if (!mounted) return;
    setState(() {
      registros = dados
          .map((item) => ConsumoAgua.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> salvarDados() async {
    final conteudo = jsonEncode(registros.map((r) => r.toJson()).toList());
    await GerenciarArquivo.salvar(conteudo);
  }

  void limparCampos() {
    data = "";
    quantidadeEmMl = "";
    pesoAtualKg = "";
  }

  List<ConsumoAgua> _registrosDoDia() {
    final hoje = _hojeFormatado();
    return registros.where((registro) => registro.data == hoje).toList();
  }

  double _totalHoje() {
    return _registrosDoDia()
        .fold(0, (total, registro) => total + registro.quantidadeEmMl);
  }

  double _metaHoje() {
    final registrosHoje = _registrosDoDia();
    if (registrosHoje.isEmpty) return 0;
    return registrosHoje.last.metaDiariaMl;
  }

  double _percentualMetaHoje() {
    final meta = _metaHoje();
    if (meta == 0) return 0;
    return (_totalHoje() / meta) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consumo de Água"),
        actions: [
          GestureDetector(
            onTap: () {
              limparCampos();
              cadastrar();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
              child: const Icon(Icons.add, size: 40, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total de hoje",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${_totalHoje().toStringAsFixed(0)} ml",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Meta atingida",
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${_percentualMetaHoje().toStringAsFixed(0)}%",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: registros.isEmpty
                ? const Center(child: Text("Nenhum consumo registrado"))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemBuilder: (context, i) => Card(
                      child: ListTile(
                        title: Text(
                          '${registros[i].data} - ${registros[i].quantidadeEmMl.toStringAsFixed(0)} ml',
                        ),
                        subtitle: Text(
                          'Peso: ${registros[i].pesoAtualKg.toStringAsFixed(1)} kg  •  '
                          'Meta do registro: ${registros[i].metaDiariaMl.toStringAsFixed(0)} ml',
                        ),
                        trailing: GestureDetector(
                          onTap: () => excluir(i),
                          child: const Icon(Icons.delete),
                        ),
                        onTap: () => alterar(i),
                      ),
                    ),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemCount: registros.length,
                  ),
          ),
          graficoComparativo(),
        ],
      ),
    );
  }

  Widget graficoComparativo() {
    if (registros.isEmpty) return const SizedBox.shrink();

    double maiorValor = registros
        .map((registro) => registro.quantidadeEmMl)
        .reduce((a, b) => a > b ? a : b);
    if (maiorValor == 0) maiorValor = 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Relatório de consumo de água",
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          ...registros.asMap().entries.map((entry) {
            final indice = entry.key;
            final registro = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('${indice + 1}'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: registro.quantidadeEmMl / maiorValor,
                        minHeight: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${registro.quantidadeEmMl.toStringAsFixed(0)} ml'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void cadastrar() {
    data = _hojeFormatado();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo consumo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: data),
              decoration: const InputDecoration(hintText: "Data"),
              onChanged: (value) => data = value,
            ),
            TextField(
              decoration: const InputDecoration(hintText: "Quantidade (ml)"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => quantidadeEmMl = value,
            ),
            TextField(
              decoration: const InputDecoration(hintText: "Peso atual (kg)"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => pesoAtualKg = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                registros.add(
                  ConsumoAgua(
                    data: data.isEmpty ? _hojeFormatado() : data,
                    quantidadeEmMl: _toDouble(quantidadeEmMl),
                    pesoAtualKg: _toDouble(pesoAtualKg),
                  ),
                );
              });
              await salvarDados();
            },
            child: const Text("Cadastrar"),
          ),
        ],
      ),
    );
  }

  void alterar(int indice) {
    data = registros[indice].data;
    quantidadeEmMl = registros[indice].quantidadeEmMl.toString();
    pesoAtualKg = registros[indice].pesoAtualKg.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar consumo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: data),
              decoration: const InputDecoration(hintText: "Data"),
              onChanged: (value) => data = value,
            ),
            TextField(
              controller: TextEditingController(text: quantidadeEmMl),
              decoration: const InputDecoration(hintText: "Quantidade (ml)"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => quantidadeEmMl = value,
            ),
            TextField(
              controller: TextEditingController(text: pesoAtualKg),
              decoration: const InputDecoration(hintText: "Peso atual (kg)"),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => pesoAtualKg = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                registros[indice] = ConsumoAgua(
                  data: data,
                  quantidadeEmMl: _toDouble(quantidadeEmMl),
                  pesoAtualKg: _toDouble(pesoAtualKg),
                );
              });
              await salvarDados();
            },
            child: const Text("Salvar alteração"),
          ),
        ],
      ),
    );
  }

  void excluir(int indice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir consumo'),
        content: const Text('Confirma a exclusão deste registro?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                registros.removeAt(indice);
              });
              await salvarDados();
            },
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }
}
