import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:footprint3/CameraApp.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footprint3/CancelTransfer_page.dart';
import 'package:footprint3/ReceiveDocument_page.dart';
import 'package:footprint3/SendDocument_page.dart';
import 'package:footprint3/TrackDocumentPage.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class UpdateDocumentPage extends StatefulWidget {
  final String documentKey;

  const UpdateDocumentPage({Key? key, required this.documentKey}) : super(key: key);

  @override
  _UpdateDocumentPageState createState() => _UpdateDocumentPageState();
}

class _UpdateDocumentPageState extends State<UpdateDocumentPage> {
  int currentPage = 0;
  List<String> checklistItems = [];
  List<bool> checklistStatus = [];
  List<XFile> imageFiles = [];


  @override
  void initState() {
    super.initState();
    updateChecklistItems();
  }

  Future<void> updateChecklistItems() async {
    try {
      TrackableDocument? doc = await getDocument(widget.documentKey);
      if (doc != null) {
        List<String> items = [];
        List<bool> status = doc.checklistStatus ?? [];

        if (doc.type == "Completion Form") {
          items = ["Signed by Student", "Graded", "Signed by Instructor", "Signed by Director"];
        } else if (doc.type == "General Clearance") {
          items = ["Signed by Campus Librarian", "Signed by Campus PTC", "Signed by Campus Registrar", "Signed by Campus Director"];
        }

        if (status.isEmpty || status.length != items.length) {
          status = List<bool>.filled(items.length, false);
        }

        setState(() {
          checklistItems = items;
          checklistStatus = status;
        });
      }
    } catch (e) {
      print('Error loading checklist items: $e');
    }
  }

  Future<void> scanDocument() async {
  // ──────────────────────────── 1. Handle CAMERA permission on Web ──────────────
  if (kIsWeb) {
    final perm = await html.window.navigator.permissions?.query({'name': 'camera'});

    Future<void> _showSnack(String msg, Color color) async =>
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: color),
        );

    switch (perm?.state) {
      case 'granted':
        // Already allowed → nothing to ask; go straight to scanning.
        break;

      case 'prompt':
        // First‑time request → trigger prompt.
        try {
          await html.window.navigator.mediaDevices
              ?.getUserMedia({'video': true});
          await _showSnack('Camera access granted!', Colors.green);
        } catch (_) {
          await _showSnack('User denied camera access.', Colors.red);
          return; // Stop – scanning won’t work without the camera.
        }
        break;

      case 'denied':
        // Previously blocked → inform user & stop (can’t re‑prompt programmatically).
        await _showSnack('Oops! Camera access denied!', Colors.orangeAccent);
        return;

      default:
        // Fall‑through for browsers that don’t support the Permissions API.
        break;
    }
    List<CameraDescription> cameras = await availableCameras();
    List<XFile> images = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraHome(cameras: cameras,),
        ),
      );
    
    if (images.isNotEmpty) {
      for (var image in images) {
        setState(() {
            imageFiles.add(image);
          });
      }
    }
  }
  else{
    // ──────────────────────────── 2. Proceed with Document Scanner ────────────────
    try {
      final documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: DocumentFormat.jpeg,
          mode: ScannerMode.filter,
          pageLimit: 100,
          isGalleryImport: true,
        ),
      );

      final result = await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        for (final imagePath in result.images) {
          setState(() {
            imageFiles.add(XFile(imagePath));
          });
        }
      }
    } catch (e, st) {
      debugPrint('Document scan error: $e\n$st');
    }
  }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Update Document",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<TrackableDocument?>(
        stream: getDocumentStream(widget.documentKey),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading document'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Document not found'));
          }

          final document = snapshot.data!;

          return Padding(
  padding: const EdgeInsets.all(16.0),
  child: SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(document.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: document.key));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tracking number copied to clipboard!")),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text("Tracking Number:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Icon(Icons.copy),
                ],
              ),
              Text(document.key,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const Text("Status: ", style: TextStyle(fontSize: 16)),
            Chip(
              label: Text(document.status.label),
              backgroundColor: backgroundColor,
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text("Document Type: ${document.type}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),

        const SizedBox(height: 8),

        FutureBuilder(
          future: getTrackerUsingKey(document.currentHolderKey),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading holder...');
            } else if (snapshot.hasError) {
              return const Text('Error fetching holder');
            } else if (!snapshot.hasData) {
              return const Text('No holder found');
            } else {
              final tracker = snapshot.data!;
              return Text("Current Holder: ${tracker.fullName}",
                  style: const TextStyle(fontSize: 16));
            }
          },
        ),

        if (document.status == DocumentStatus.forwarded)
          FutureBuilder(
            future: document.records.last.receiverKey != null
                ? getTrackerUsingKey(document.records.last.receiverKey!)
                : Future.error('Receiver key is null'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Loading forwarded to...');
              } else if (snapshot.hasError) {
                return const Text('Error fetching receiver');
              } else if (!snapshot.hasData) {
                return const Text('No receiver found');
              } else {
                final tracker = snapshot.data!;
                return Text('Forwarded to: ${tracker.fullName}',
                    style: const TextStyle(fontSize: 16));
              }
            },
          ),

        

        if (document.imageRefs.isNotEmpty) ...[
          const SizedBox(height: 16),
          Column(
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: document.imageRefs.length,
                  onPageChanged: (index) {
                    
                  },
                  itemBuilder: (context, index) {
                    return FutureBuilder<String?>(
                      future: getImage(document.imageRefs[index]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(base64Decode(snapshot.data!), fit: BoxFit.cover);
                        } else {
                          return Center(child: Text('Image not available'));
                        }
                      },
                    );
                  }
                ),
              ),
              
            ],
          ),
        ],
        Center(                   child: Text('Swipe to view images', style: TextStyle(color: Colors.grey[600]))),
        if (imageFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Column(
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: imageFiles.length,
                  onPageChanged: (index) {
                    
                  },
                  itemBuilder: (context, index) {
                    return Image.file(File(imageFiles[index].path), fit: BoxFit.cover);
                  }
                ),
              ),
              
            ],
          ),
        ],
        SizedBox(height: 16),
        Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => scanDocument(),
                  icon: Icon(Icons.camera_alt, color: mainOrange,),
                  label: Text("Scan Document", style: TextStyle(color: mainOrange),),
                ),
              ),
        const Text("Checklist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (checklistItems.isNotEmpty)
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: List.generate(checklistItems.length, (index) {
    bool canBeChecked = index == 0 || (checklistStatus[index - 1] == true);
    
    // Safely handle null or out-of-bounds
    List<bool>? savedStatus = document.records.last.checklistStatus;
    bool isCheckedInDocument = savedStatus != null &&
        index < savedStatus.length &&
        savedStatus[index] == true;

    bool isDisabled = isCheckedInDocument || !canBeChecked;

    return CheckboxListTile(
      title: Text(checklistItems[index]),
      value: (checklistStatus.length > index && checklistStatus[index]) || isCheckedInDocument,
      onChanged: isDisabled
          ? null
          : (bool? value) {
              setState(() {
                if (checklistStatus.length > index) {
                  checklistStatus[index] = value ?? false;
                }
              });
            },
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: mainOrange,
    );
  }),
),



          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                    onPressed: () async {
                      document.checklistStatus = checklistStatus;
                      if (imageFiles.isNotEmpty) {
                          List<String> imageBase64Refs = [];
                            for (var file in imageFiles) {
                              final bytes = await file.readAsBytes();
                              final compressedBytes = await compressAndResizeImage(bytes);
                              if (compressedBytes != null) {
                                String imageBase64 = base64Encode(compressedBytes as List<int>);
                                var ref = await uploadImage(imageBase64);
                                if (ref != null) {
                                  imageBase64Refs.add(ref);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to upload image.')),
                                  );
                                  return;
                                }
                              }
                            }
                            document.imageRefs = imageBase64Refs;
                      }
                      updateDocument(document);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Document updated successfully!")),
                      );
                    },
                    label: const Text('Update', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: mainOrange),
                  ),
            ),
          ),
      ],
      
    ),
  ),
);

        },
      ),
    );
  }
}
