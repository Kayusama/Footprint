import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


class QrSaveExample extends StatefulWidget {
  final String qrData;
  const QrSaveExample({Key? key, required this.qrData}) : super(key: key);
  @override
  _QrSaveExampleState createState() => _QrSaveExampleState();
}

class _QrSaveExampleState extends State<QrSaveExample> {
  final GlobalKey _qrKey = GlobalKey();

  Future<void> _saveQrToFile() async {
  final status = await Permission.storage.request();
  final photoStatus = await Permission.photos.request();

  if (!status.isGranted && !photoStatus.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permission denied')),
    );
    return;
  }

  try {
    // Wait until rendering is complete
    await Future.delayed(const Duration(milliseconds: 300));
    RenderRepaintBoundary boundary =
        _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // final result = await ImageGallerySaver.saveImage(
    //   pngBytes,
    //   quality: 100,
    //   name: "qr_code_${DateTime.now().millisecondsSinceEpoch}",
    // );

    // if (result['isSuccess'] == true || result['filePath'] != null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Saved to gallery')),
    //   );
    // } else {
    //   throw Exception('Save failed');
    // }
  } catch (e) {
    print("Error saving QR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to save QR')),
    );
  }

}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("QR Code Generator")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                height: 300,
                width: 300,
                child: Card(
                  child: Column(
                    children: [
                      SizedBox(height:  30),
                      Center(child: Text(widget.qrData,)),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: QrImageView(
                          data: widget.qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveQrToFile,
              child: Text("Save QR Code as PNG"),
            ),
          ],
        ),
      ),
    );
  }
}
