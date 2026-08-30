import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/product_card.dart';
import 'product_form_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isFlashOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Sfondo scuro per simulare la fotocamera
      body: Stack(
        children: [
          // 1. Mirino dello scanner centrale
          Center(
            child: _buildViewfinder(),
          ),

          // 2. Pulsanti superiori (Flash e Chiudi)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlButton(
                    icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                  ),
                  _buildControlButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // 3. Pannello inferiore "Carrello"
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildCartBottomSheet(context),
          ),
        ],
      ),
    );
  }

  // Costruttore dei pulsanti fluttuanti circolari
  Widget _buildControlButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  // Costruttore del mirino (angoli e raggio laser)
  Widget _buildViewfinder() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _buildCorner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _buildCorner(top: true, left: false)),
          Positioned(bottom: 0, left: 0, child: _buildCorner(top: false, left: true)),
          Positioned(bottom: 0, right: 0, child: _buildCorner(top: false, left: false)),

          // Linea laser centrale
          Center(
            child: Container(
              width: double.infinity,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Disegna un singolo angolo del mirino
  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(16) : Radius.zero,
          topRight: top && !left ? const Radius.circular(16) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(16) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }

  // Pannello bianco inferiore scorrevole
  Widget _buildCartBottomSheet(BuildContext context) {
    final provider = context.watch<ShoppingListProvider>();
    final cartItems = provider.giaPreso; // Legge i prodotti segnati come "nel carrello"

    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // Maniglia di trascinamento visiva
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Titolo
          const Center(
            child: Text(
              'CARRELLO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Griglia delle card
          Expanded(
            child: cartItems.isEmpty
                ? Center(
              child: Text(
                'Nessun prodotto nel carrello',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return ProductCard(
                  name: item.nome,
                  onTap: () {
                    // Chiude la schermata scanner e apre il form passando il nome precompilato
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => ProductFormScreen(
                          prefilledNome: item.nome, // Pre-compila l'input "Nome Prodotto"
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}