import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:footprint3/BarcodeScannerPage.dart';
import 'package:footprint3/DocumentDetailsPage.dart';
import 'package:footprint3/Notifications_page.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class ReceiveDocumentPage extends StatefulWidget {

  final TrackableDocument document;
  const ReceiveDocumentPage({Key? key, required this.document}) : super(key: key);

  @override
  _ReceiveDocumentPageState createState() => _ReceiveDocumentPageState();
}

class _ReceiveDocumentPageState extends State<ReceiveDocumentPage> {
  String scannedCode = '';
  int currentPage = 0; // Track current image index
  List<XFile> imageFiles = [];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Receive Document",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.document.imageRefs.isNotEmpty)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: widget.document.imageRefs.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Image.memory(
                          base64Decode(widget.document.imageRefs[index]),
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      '${currentPage + 1}/${widget.document.imageRefs.length}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),


            Text(
              "Tracking Number: ${widget.document.key}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Status
            Row(
              children: [
                Text("Status: ", style: TextStyle(fontSize: 16)),
                Chip(
                  label: Text(widget.document.status.label),
                  backgroundColor: Colors.orange[100],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Current Holder
            FutureBuilder(
            future: getTrackerUsingKey(widget.document.currentHolderKey),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Loading holder...');
              } else if (snapshot.hasError) {
                return Text('Error fetching holder');
              } else if (!snapshot.hasData) {
                return Text('No holder found');
              } else {
                final tracker = snapshot.data!;
                return Text(
              "Current Holder: ${tracker.username}",
              style: TextStyle(fontSize: 16),
            );
              }
            },
          ),
            if(widget.document.status == DocumentStatus.forwarded) ...[
            FutureBuilder(
            future: widget.document.records.last.receiverKey != null 
                ? getTrackerUsingKey(widget.document.records.last.receiverKey!) 
                : Future.error('Receiver key is null'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Loading holder...');
              } else if (snapshot.hasError) {
                return Text('Error fetching holder');
              } else if (!snapshot.hasData) {
                return Text('No holder found');
              } else {
                final tracker = snapshot.data!;
                return Text('Forwarded to: ${tracker.username}', style: TextStyle(fontSize: 16),);
              }
            },
          ),
          ],
          if (widget.document.remarks.isNotEmpty)
              Text(
                "Remarks: ${widget.document.remarks}",
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Text("Scan Option:", style: TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: Text(widget.document.scanOption.label),
                    backgroundColor: Colors.blue[100],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (){
                    if (widget.document.scanOption == ScanOptions.OCR) {
                      scanDocument();
                    } else {
                      scanBarcode();
                    }
                  },
                  icon: Icon(widget.document.scanOption == ScanOptions.qrCode ? Icons.qr_code_scanner: Icons.barcode_reader),
                  label: Text("Scan ${widget.document.scanOption.label}"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Spacer(), 
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(mainOrange)
                    ),
                    onPressed: () async {
                      if (widget.document.isScanRequiredUponReceiving) {
                        if (widget.document.scanOption == ScanOptions.OCR) {
                          // todo here
                          receiveDocument();
                        }
                        else{
                          if(scannedCode == widget.document.scancode){
                            receiveDocument();
                          }
                        }
                      }
                      else{
                        receiveDocument();
                      }
                    },
                    child: Text("Receive", style: TextStyle(color: Colors.white),),
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }


  Future<void> scanDocument() async {
    try {
      DocumentScannerOptions documentOptions = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.filter,
        pageLimit: 100,
        isGalleryImport: true,
      );

      final documentScanner = DocumentScanner(options: documentOptions);
      DocumentScanningResult result = await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        for (String imagePath in result.images) {
          setState(() {
            imageFiles.add(XFile(imagePath));
          });
        }
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
      });
    }
  }

  void receiveDocument(){
    String previousHolder = widget.document.currentHolderKey;
      widget.document.receivedDocument(curTracker.key, "remarks");// here
      updateDocument(widget.document);
      addNotification(NotificationItem(
        key: '', 
        documentKey: widget.document.key, 
        trackerKey: previousHolder,
        title: 'Document received', 
        time: DateTime.now().toString(), 
        isRead: false,
        content: "${widget.document.title} has been received by ${curTracker.username}.",
        )
        );

        addNotification(NotificationItem(
        key: '', 
        documentKey: widget.document.key, 
        trackerKey: previousHolder!,
        title: 'Document received', 
        time: DateTime.now().toString(), 
        isRead: false,
        content: "You have received the ${widget.document.title}.",
        )
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document sent successfully!')),
        );
        Navigator.pop(context);
  }

  Future<void> scanBarcode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Barcodescannerpage(),
        ),
      );

      // You can optionally use the returned result after popping
      if (result != null) {
        setState(() {
          scannedCode = result;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to scan"),
        ),
      );
    }
  }
}
