import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footprint3/CancelTransfer_page.dart';
import 'package:footprint3/ReceiveDocument_page.dart';
import 'package:footprint3/SendDocument_page.dart';
import 'package:footprint3/TrackDocumentPage.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/UpdateDocument_page.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';
import 'package:intl/intl.dart';

class DocumentDetailsPage extends StatefulWidget {
  final String documentKey;

  const DocumentDetailsPage({Key? key, required this.documentKey}) : super(key: key);

  @override
  _DocumentDetailsPageState createState() => _DocumentDetailsPageState();
}

class _DocumentDetailsPageState extends State<DocumentDetailsPage> {
  int currentPage = 0;
  List<String> checklistItems = [];
  List<bool> checklistStatus = [];

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Document Details",
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
                  Text(document.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: document.trackingCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Tracking number copied to clipboard!")),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text("Tracking Number:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            Icon(Icons.copy),
                          ],
                        ),
                        Text(document.trackingCode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Text("Status: ", style: TextStyle(fontSize: 16)),
                      Chip(label: Text(document.status.label), backgroundColor: backgroundColor),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text("Document Type: ${document.type}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),

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
                        return Text("Current Holder: ${tracker.fullName}", style: const TextStyle(fontSize: 16));
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
                          return Text('Forwarded to: ${tracker.fullName}', style: const TextStyle(fontSize: 16));
                        }
                      },
                    ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (document.status == DocumentStatus.onHold &&
                          document.currentHolderKey == curTracker.key)
                        _buildActionButton("Send", Icons.send, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SendDocumentPage(document: document)));
                        }),
                      if (document.status == DocumentStatus.forwarded &&
                          document.records.last.receiverKey == curTracker.key)
                        _buildActionButton("Receive", Icons.receipt, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiveDocumentPage(document: document)));
                        }),
                      if (document.status == DocumentStatus.forwarded &&
                          (document.records.last.receiverKey == curTracker.key || document.currentHolderKey == curTracker.key))
                        _buildActionButton("Cancel", Icons.cancel, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CancelTransferPage(document: document)));
                        }),
                      if (document.status == DocumentStatus.onHold &&
                          document.currentHolderKey == curTracker.key &&
                          document.records.length < 2)
                        _buildActionButton("Delete", Icons.delete, () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Document"),
                              content: const Text("Are you sure you want to delete this document? This action cannot be undone."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                                TextButton(
                                  onPressed: () async {
                                    await deleteDocument(document.key);
                                    Navigator.pop(context); // close dialog
                                    Navigator.pop(context); // go back
                                  },
                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),

                  if (document.remarks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text("Remarks: ${document.remarks}",
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                  ],

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
                  Center(child: Text('Swipe to view images', style: TextStyle(color: Colors.grey[600]))),

                  if (document.status == DocumentStatus.onHold &&
                      document.currentHolderKey == curTracker.key)
                    _buildActionButton("Update Document", Icons.edit, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateDocumentPage(documentKey: document.key),
                        ),
                      );
                    }),

                  const SizedBox(height: 16),
                  const Text("History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  document.records.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 1,
                          itemBuilder: (context, index) {
                            final latestRecord = document.records.last;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => TrackDocumentPage(trackableDocument: document)),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 2,
                                child: ListTile(
                                  leading: Icon(Icons.history, color: mainOrange),
                                  title: Text(latestRecord.holder),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Status: ${latestRecord.status.label}"),
                                      Text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(latestRecord.date)}",
                                          style: TextStyle(color: Colors.grey[600])),
                                      if (latestRecord.remarks.isNotEmpty)
                                        Text("Remarks: ${latestRecord.remarks}",
                                            style: const TextStyle(fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text("No history records found.", style: TextStyle(color: Colors.grey, fontSize: 16))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: mainOrange),
      ),
    );
  }
}
