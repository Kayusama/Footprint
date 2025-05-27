import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:footprint3/Notifications_page.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/DocumentRecord_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';

class CancelTransferPage extends StatefulWidget {
  final TrackableDocument document;
  const CancelTransferPage({Key? key, required this.document}) : super(key: key);

  @override
  _CancelTransferPageState createState() => _CancelTransferPageState();
}

class _CancelTransferPageState extends State<CancelTransferPage> {
  String scannedCode = '';
  int currentPage = 0; // Track current image index
  TextEditingController remarksController = TextEditingController(); // Controller for remarks input

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Cancel Transfer",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                                return FutureBuilder<String?>(
                                  future: getImage(widget.document.imageRefs[index]),
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
                    if (widget.document.status == DocumentStatus.forwarded) ...[
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
                            return Text(
                              'Forwarded to: ${tracker.username}',
                              style: TextStyle(fontSize: 16),
                            );
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
                    TextField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: 'Enter Remarks',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.red)),
                    onPressed: () async {
                      cancelDocument();
                    },
                    child: Text(
                      "Cancel Transfer",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void cancelDocument() {
    String previousHolder = widget.document.currentHolderKey;
    String remarks = remarksController.text; // Get remarks text from controller

    widget.document.cancelTransfer(remarks);

    updateDocument(widget.document);

    addNotification(NotificationItem(
      key: '',
      documentKey: widget.document.key,
      trackerKey: widget.document.currentHolderKey,
      title: 'Document Transfer Cancelled',
      time: DateTime.now().toString(),
      isRead: false,
      content: "${widget.document.title} transfer has been cancelled by ${curTracker.username}.",
    ));

    addNotification(NotificationItem(
      key: '',
      documentKey: widget.document.key,
      trackerKey: previousHolder,
      title: 'Document Transfer Cancelled',
      time: DateTime.now().toString(),
      isRead: false,
      content: "Your transfer of ${widget.document.title} has been cancelled.",
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document transfer cancelled!')),
    );
    Navigator.pop(context);
  }
}
