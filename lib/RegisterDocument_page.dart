import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:footprint3/BarcodeScannerPage.dart';
import 'package:footprint3/CameraApp.dart';
import 'package:footprint3/DocumentRecord_class.dart';
import 'package:footprint3/QrSaveExample_page.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;

class RegisterdocumentPage extends StatefulWidget {
  @override
  _RegisterdocumentPageState createState() => _RegisterdocumentPageState();
}

class _RegisterdocumentPageState extends State<RegisterdocumentPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool textScanning = false;
  List<XFile> imageFiles = [];
  List<String> scannedText = [];
  String scannedCode = '';
  final List<String> types = ["Completion Form", "General Clearance", "Others"];
  String selectedType = "Completion Form";

  List<ScanOptions> scanOptions = ScanOptions.values;
  ScanOptions selectedRequiredScans = ScanOptions.None;
  bool isScanRequiredUponReceiving = false;
  List<String> privacyOptions = [
  "Public",
  "Previous Holders + Receiver",
  "Current Holder + Receiver",
];
  int privacyIndex = 0;

  @override
  void dispose() {
    titleController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Register Document",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 40),
              _buildTextField(titleController, "Title"),
              SizedBox(height: 20),
              DropdownButton<String>(
                hint: const Text('Type'),
                value: selectedType,
                items: types.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue!;
                  });
                },
              ),
              SizedBox(height: 20),
              _buildTextField(remarksController, "Remarks", maxLines: 5),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => scanDocument(),
                  icon: Icon(Icons.camera_alt, color: mainOrange,),
                  label: Text("Scan Document", style: TextStyle(color: mainOrange),),
                ),
              ),
              SizedBox(height: 20),
              _buildScanRequirements(),
              selectedRequiredScans != ScanOptions.None ? CheckboxListTile(
                title: const Text('Require scanning upon receiving.'),
                value: isScanRequiredUponReceiving,
                onChanged: (bool? value) {
                  setState(() {
                    isScanRequiredUponReceiving = value ?? false;
                  });
                },
              ): Container(),
              selectedRequiredScans == ScanOptions.qrCode || selectedRequiredScans == ScanOptions.barcode ? Container(
                width: double.infinity,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                  onPressed: ()=>scanBarcode(),
                  icon: Icon(selectedRequiredScans == ScanOptions.qrCode ? Icons.qr_code_scanner: Icons.barcode_reader),
                  label: Text("Scan ${selectedRequiredScans.label}"),
                ),
                ElevatedButton.icon(
                  onPressed: (){
                    String qrData = generateUnique6DigitCode();
                    scannedCode = qrData;
                    setState(() {});
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QrSaveExample(
                          qrData: qrData,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.qr_code),
                  label: Text("Generate ${selectedRequiredScans.label}"),
                ),
                  ],
                )
              ): Container(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Code: ${scannedCode}"),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
  width: double.infinity,
  child: Center(
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Privacy",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: privacyIndex,
                hint: Text('Select privacy'),
                onChanged: (int? newIndex) {
                  setState(() {
                    privacyIndex = newIndex!;
                    print("Selected privacy: ${privacyIndex}");
                  });
                },
                items: List.generate(privacyOptions.length, (index) {
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(privacyOptions[index]),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

              if (textScanning) CircularProgressIndicator(),
              if (imageFiles.isNotEmpty)
                kIsWeb?
                Column(
                  children: imageFiles.map((file) => Image.network(file.path, height: 150)).toList(),
                )
                :
                Column(
                  children: imageFiles.map((file) => Image.file(File(file.path), height: 150)).toList(),
                ),
              SizedBox(height: 20),
              _buildRegisterButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> scanBarcode() async {
    
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Barcodescannerpage(),
        ),
      );

      if (result != null) {
        setState(() {
          scannedCode = result;
        });
      }
      
    } catch (e) {
      print(e.toString());
    }
  }


  Widget _buildScanRequirements() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Select scan option:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      DropdownButtonFormField<ScanOptions>(
        value: selectedRequiredScans,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: scanOptions.map((ScanOptions option) {
          return DropdownMenuItem<ScanOptions>(
            value: option,
            child: Text(option.label),
          );
        }).toList(),
        onChanged: (ScanOptions? newValue) {
          if (newValue != null) {
            setState(() {
              selectedRequiredScans = newValue;
            });
          }
        },
      ),
    ],
  );
}


  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildRegisterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: registerDocument,
          style: ElevatedButton.styleFrom(backgroundColor: textScanning ? Colors.green : mainOrange),
          child: Text('Register', style: TextStyle(color: Colors.white)),
        ),
        SizedBox(width: 16),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel', style: TextStyle(color: mainOrange)),
        ),
      ],
    );
  }

  

  Future<void> scanDocument() async {
  if (kIsWeb) {
    final perm = await html.window.navigator.permissions?.query({'name': 'camera'});

    Future<void> _showSnack(String msg, Color color) async =>
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: color),
        );

    switch (perm?.state) {
      case 'granted':
        break;

      case 'prompt':
        try {
          await html.window.navigator.mediaDevices
              ?.getUserMedia({'video': true});
          await _showSnack('Camera access granted!', Colors.green);
        } catch (_) {
          await _showSnack('User denied camera access.', Colors.red);
          return; 
        }
        break;

      case 'denied':
        await _showSnack('Oops! Camera access denied!', Colors.orangeAccent);
        return;

      default:
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
            textScanning = true;
            imageFiles.add(image);
          });
        if (selectedRequiredScans == ScanOptions.OCR) {
          await getRecognisedText(image.path);
        }
      }
    }
  }
  else{
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
            textScanning = true;
            imageFiles.add(XFile(imagePath));
          });

          if (selectedRequiredScans == ScanOptions.OCR) {
            await getRecognisedText(imagePath);
          }
        }
      }
    } catch (e, st) {
      debugPrint('Document scan error: $e\n$st');
      setState(() => textScanning = false);
    }
  }

  
}


  Future<void> getRecognisedText(String imagePath) async {
    

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String lineText = line.text.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ');
        if (lineText.trim().isNotEmpty) {
          scannedText.add(lineText);
        }
      }
    }

    textScanning = false;
    await textRecognizer.close();
    setState(() {});
  }

  Future<void> registerDocument() async {
  String trackingCode = "";
  String randomNums = generateUnique6DigitCode();

    if (selectedType == "Completion Form") {
      trackingCode = "COM-${randomNums}";
    }
    else if (selectedType == "General Clearance") {
        trackingCode = "GEN-${randomNums}";
    }
    else {
      trackingCode = "FDOC-${randomNums}";
    }

  // Validate required fields
  if (titleController.text.isEmpty ||
      selectedType == null ||
      imageFiles.isEmpty ||
      curTracker.key.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all required fields.')),
    );
    return;
  }

  List<String> imageBase64Refs = [];
  for (var file in imageFiles) {
    final filePath = file.path;
    if (selectedRequiredScans == ScanOptions.OCR) {
      await getRecognisedText(filePath);
    }
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

  DocumentRecord newRecord = DocumentRecord(
    holder: curTracker.key,
    status: DocumentStatus.registered,
    date: DateTime.now(),
    remarks: remarksController.text, 
    checklistStatus: [],
    imageRefs: [],
  );

  TrackableDocument newDocument = TrackableDocument(
    title: titleController.text,
    records: [newRecord],
    status: DocumentStatus.onHold,
    type: selectedType,
    createdDate: DateTime.now(),
    lastUpdatedDate: DateTime.now(),
    remarks: remarksController.text,
    key: '',
    embeddings: scannedText,
    currentHolderKey: curTracker.key,
    scanOption: selectedRequiredScans,
    isScanRequiredUponReceiving: isScanRequiredUponReceiving,
    scancode: scannedCode,
    privacy: privacyIndex, 
    imageRefs: imageBase64Refs, 
    trackingCode: trackingCode,
  );

  addDocument(newDocument);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Document sent successfully!')),
  );
  Navigator.pop(context);
}
}
