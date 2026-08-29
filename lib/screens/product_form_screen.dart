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
        TextEditingController(text: p?.quantita.toInt().toString() ?? '1');

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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Placeholder Immagine
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.black87, width: 1.5),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.image, size: 40, color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Nome Prodotto
              TextFormField(
                controller: _nomeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'NOME PRODOTTO',
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.black87, width: 1.5),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.black87, width: 1.5),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Colors.black87, width: 2.0),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
              ),
              const SizedBox(height: 40),

              // Scadenza
              _buildFormRow(
                'SCADENZA',
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatDate(_dataScadenza),
                      style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quantità e Unità
              _buildFormRow(
                'QUANTITÀ',
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantitaController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? '!' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _unita,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        items: _unita_options
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setState(() => _unita = v!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categoria
              _buildFormRow(
                'CATEGORIA',
                DropdownButtonFormField<String>(
                  value: _categoria,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  ),
                  items: _categorie
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoria = v!),
                ),
              ),
              const SizedBox(height: 24),

              // Alloca in (Posizione)
              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  final posizioniDisponibili = locationProvider.locations.map((l) => l.nome).toList();

                  if (!posizioniDisponibili.contains(_posizione) && posizioniDisponibili.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() => _posizione = posizioniDisponibili.first);
                    });
                  }

                  return _buildFormRow(
                    'ALLOCA IN',
                    DropdownButtonFormField<String>(
                      value: posizioniDisponibili.contains(_posizione) ? _posizione : null,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      ),
                      items: posizioniDisponibili
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setState(() => _posizione = v!),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              // Tasto finale Modifica/Inserisci
              InkWell(
                onTap: _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _isEditing ? 'MODIFICA' : 'INSERISCI',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Costruttore righe con label a sinistra e input a destra
  Widget _buildFormRow(String label, Widget inputWidget) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 12,
          ),
        ),
        SizedBox(
          width: 160,
          child: inputWidget,
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '- / - / -';
    return '${date.day.toString().padLeft(2, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.year.toString().substring(2)}';
  }
}