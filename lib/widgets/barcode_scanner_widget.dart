
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Widget para escanear códigos de barras o QR
class BarcodeScannerWidget extends StatefulWidget {
  /// Función que se ejecuta cuando detecta un código
  final Function(String) onDetect;

  const BarcodeScannerWidget({
    super.key,
    required this.onDetect,
  });

  @override
  State<BarcodeScannerWidget> createState() =>
      _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState
    extends State<BarcodeScannerWidget> {

  final MobileScannerController controller =
      MobileScannerController();

  @override
  void dispose() {
    // Liberar cámara
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Código'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: Stack(
        children: [
          // 📷 Cámara
          MobileScanner(
            controller: controller,

            onDetect: (barcodeCapture) {
              final barcode = barcodeCapture.barcodes.first;
              final String code = barcode.rawValue ?? '';

              if (code.isNotEmpty) {
                widget.onDetect(code);

                // Cerrar pantalla automáticamente
                Navigator.pop(context);
              }
            },
          ),

          // 🔳 Overlay (cuadro visual)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.orange,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // 📝 Texto guía
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Apunta al código de barras',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

