import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:footprint3/utils.dart';

class Barcodescannerpage extends StatefulWidget {
  const Barcodescannerpage({Key? key}) : super(key: key);

  @override
  State<Barcodescannerpage> createState() => _BarcodescannerpageState();
}

class _BarcodescannerpageState extends State<Barcodescannerpage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _screenOpened = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Scanner",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_off : Icons.flash_on, color: Colors.white,),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: cameraController.facing == CameraFacing.front ? Icon(Icons.camera_front, color: Colors.white,) : Icon(Icons.photo_camera_back, color: Colors.white,),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (BarcodeCapture capture) {
              final Barcode? barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
              if (barcode != null) {
                _foundBarcode(barcode, capture);
              }
            },
          ),
          // Scanner overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _foundBarcode(Barcode barcode, BarcodeCapture capture) async {
    final String? code = barcode.rawValue;
    if (code == null || _screenOpened) return;
    _screenOpened = true;

    Navigator.pop(context, code);
  }
}
