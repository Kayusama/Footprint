import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// CameraApp is the Main Application.

class CameraHome extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraHome({super.key, required this.cameras});

  @override
  State<CameraHome> createState() => _CameraHomeState();
}

class _CameraHomeState extends State<CameraHome> {
  late CameraController controller;
  bool _isTakingPicture = false;
  List<XFile> images = [];

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );
    controller.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Captures a photo and saves it to the temporary directory.
  Future<void> _takePicture() async {
    if (_isTakingPicture) return;       // guard
    setState(() => _isTakingPicture = true);

    try {
      final XFile raw = await controller.takePicture();
      images.add(raw);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Document"),
      ),
      body: Stack(
        children: [
          CameraPreview(controller),
          // Capture button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: _isTakingPicture ? null : _takePicture,
                    tooltip: 'Capture',
                    child: const Icon(Icons.camera_alt),
                  ),
                  FloatingActionButton(
                    onPressed: (){
                      Navigator.pop(context, images);
                    },
                    tooltip: 'Done',
                    child: const Icon(Icons.check),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
