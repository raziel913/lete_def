import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:mobile_scanner_example/screens/mobile_scanner_advanced.dart';


/// Implementation of Mobile Scanner example with simple configuration
/// Implementation of Mobile Scanner example with simple configuration
class B2 extends StatefulWidget {
  @override
  MyHomeState createState() => MyHomeState();
}

class MyHomeState extends State<B2> with SingleTickerProviderStateMixin {
  Barcode? _barcode;
      final MobileScannerController controller= MobileScannerController(
    autoStart: false
  );

  Widget _barcodePreview(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
  }

    Future<void> _startScanner() async {
    await controller.start();          // ▶️ Avvia camera
    await controller.toggleTorch();    // 🔦 Accende torcia automaticamente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simple Mobile Scanner')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner( controller: controller,
            onDetect: _handleBarcode,),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: _barcodePreview(_barcode))),
                ],
              ),
            ),
          ),
        ],
      ),
            floatingActionButton: FloatingActionButton(
          child: const Text("Camera off", textAlign: TextAlign.center),
          onPressed: () {
            setState(() {
              _startScanner();
              // camState = false; // Disabilita la camera
              // qr = null;
            });
          },
        ),
    );
  }
}


 