import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../providers/pantry_provider.dart';
import '../providers/location_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? existingProduct;
  final String? prefilledNome;
  final String? prefilledCategoria;

  const ProductFormScreen({
    super.key,
    this.existingProduct,
    this.prefilledNome,
    this.prefilledCategoria,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _quantitaController;
  String _unita = 'pz';
  String _categoria = 'Altro';
  String _posizione = 'Dispensa';
  DateTime? _dataScadenza;

  final List<String> _unita_options = ['pz', 'g', 'kg', 'l'];
  final List<String> _categorie = ['Latticini', 'Verdura', 'Carne', 'Altro'];

  bool get _isEditing => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;

    _nomeController = TextEditingController(
      text: p?.nome ?? widget.prefilledNome ?? '',
    );
    _quantitaController =
        TextEditingController(text: p?.quantita.toString() ?? '1');

    if (p != null) {
      _unita = p.unita;
      _categoria = p.categoria;
      _posizione = p.posizione;
      _dataScadenza = p.dataScadenza;
    } else if (widget.prefilledCategoria != null &&
        _categorie.contains(widget.prefilledCategoria)) {
      _categoria = widget.prefilledCategoria!;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantitaController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataScadenza ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _dataScadenza = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PantryProvider>();

    if (_isEditing) {
      final p = widget.existingProduct!;
      p.nome = _nomeController.text;
      p.quantita = double.parse(_quantitaController.text);
      p.unita = _unita;
      p.categoria = _categoria;
      p.posizione = _posizione;
      p.dataScadenza = _dataScadenza;
      provider.updateProduct(p);
    } else {
      final newProduct = Product(
        id: const Uuid().v4(),
        nome: _nomeController.text,
        quantita: double.parse(_quantitaController.text),
        unita: _unita,
        categoria: _categoria,
        posizione: _posizione,
        dataAcquisto: DateTime.now(),
        dataScadenza: _dataScadenza,
      );
      provider.addProduct(newProduct);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prodotto salvato')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica prodotto' : 'Nuovo prodotto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome prodotto'),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Inserisci un nome' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantitaController,
                      keyboardType: TextInputType.number,
                      decoration:
                      const InputDecoration(labelText: 'Quantità'),
                      validator: (v) =>
                      (v == null || double.tryParse(v) == null)
                          ? 'Numero non valido'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unita,
                      decoration: const InputDecoration(labelText: 'Unità'),
                      items: _unita_options
                          .map((u) =>
                          DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unita = v!),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _categoria,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: _categorie
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  final posizioniDisponibili =
                  locationProvider.locations.map((l) => l.nome).toList();

                  if (posizioniDisponibili.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Nessuno spazio disponibile: creane uno dalla '
                            'schermata "Gestisci spazi".',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!posizioniDisponibili.contains(_posizione)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _posizione = posizioniDisponibili.first);
                    });
                  }

                  return DropdownButtonFormField<String>(
                    value: posizioniDisponibili.contains(_posizione)
                        ? _posizione
                        : null,
                    decoration: const InputDecoration(labelText: 'Posizione'),
                    items: posizioniDisponibili
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _posizione = v!),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_dataScadenza == null
                    ? 'Nessuna data di scadenza'
                    : 'Scadenza: ${_dataScadenza!.day}/${_dataScadenza!.month}/${_dataScadenza!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Salva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}