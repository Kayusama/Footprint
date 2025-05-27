import 'package:flutter/material.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/Notifications_page.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';

class SendDocumentPage extends StatefulWidget {
  final TrackableDocument document;

  const SendDocumentPage({Key? key, required this.document}) : super(key: key);

  @override
  State<SendDocumentPage> createState() => _SendDocumentPageState();
}

class _SendDocumentPageState extends State<SendDocumentPage> {
  List<HolderTracker> allHolders = [];
  String? selectedReceiver;
  String? selectedReceiverKey;  // Add this to store the receiver key
  String? searchText;

  TextEditingController noteController = TextEditingController();
  TextEditingController receiverController = TextEditingController();
  bool isLoading = true;

  FocusNode receiverFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    loadHolders();

    receiverFocusNode.addListener(() {
      if (!receiverFocusNode.hasFocus) {
        setState(() {
          searchText = null;
        });
      }
    });
  }

  Future<void> loadHolders() async {
    allHolders = await getAllTrackers();
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    receiverFocusNode.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEAE5),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Navigation
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: mainOrange),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Send Document',
                              style: TextStyle(
                                color: mainOrange,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Document Info
                    Text(
                      widget.document.key,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '"${widget.document.title}"',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          'May 21, 2024', // Ideally use widget.document.date
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.black, thickness: 1),
                    const SizedBox(height: 24),

                    // Receiver Field
                    Text(
                      'Receiver',
                      style: TextStyle(
                        color: mainOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: mainOrange),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: receiverController,
                            focusNode: receiverFocusNode,
                            onChanged: (value) {
                              setState(() {
                                searchText = value;
                              });
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search Receiver',
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (searchText != null && searchText!.isNotEmpty)
                            SizedBox(
                              height: 150,
                              child: ListView(
                                children: allHolders
                                  .where((holder) =>
                                      holder.uid != curTracker.uid &&
                                      holder.fullName.toLowerCase().contains(searchText!.toLowerCase()))
                                  .take(5)
                                  .map((holder) => ListTile(
                                        title: Text(holder.fullName),
                                        onTap: () {
                                          setState(() {
                                            receiverController.text = holder.fullName;
                                            selectedReceiver = holder.fullName;
                                            selectedReceiverKey = holder.key;
                                            searchText = null;
                                          });
                                          loseFocus();
                                        },
                                      ))
                                  .toList(),

                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Note Field
                    Text(
                      'Note',
                      style: TextStyle(
                        color: mainOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: mainOrange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: noteController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter note here...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (selectedReceiverKey != null) {
                                widget.document.forwardDocument(selectedReceiverKey!, noteController.text);
                                updateDocument(widget.document);
                                addNotification(NotificationItem(
                                  key: '', 
                                  documentKey: widget.document.key, 
                                  trackerKey: selectedReceiverKey!,
                                  title: 'Document to be received', 
                                  time: DateTime.now().toString(), 
                                  isRead: false,
                                  content: "${widget.document.title} has been forwarded to you by ${curTracker.fullName}.",
                                  )
                                  );
                                addNotification(NotificationItem(
                                  key: '', 
                                  documentKey: widget.document.key, 
                                  trackerKey: curTracker.key,
                                  title: 'Document has been sent', 
                                  time: DateTime.now().toString(), 
                                  isRead: false,
                                  content: "You have forwarded ${widget.document.title} to ${selectedReceiver!}.",

                                  )
                                  );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Document sent successfully!')),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a receiver.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainOrange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Send Document',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: mainOrange,
                              side: BorderSide(color: mainOrange),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
