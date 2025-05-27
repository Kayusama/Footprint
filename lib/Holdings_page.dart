import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:footprint3/DocumentDetailsPage.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/utils.dart';

class HoldingsPage extends StatefulWidget {
  @override
  _HoldingsPageState createState() => _HoldingsPageState();
}

class _HoldingsPageState extends State<HoldingsPage> {
  late Future<List<TrackableDocument>> _onHoldDocumentsFuture;
  late Future<List<TrackableDocument>> _forwardedDocumentsFuture;
  late Future<List<TrackableDocument>> _toReceiveDocumentsFuture;
  late Future<List<TrackableDocument>> _cancelledDocumentsFuture;

  @override
  void initState() {
    super.initState();
    _onHoldDocumentsFuture = _fetchDocumentsByStatus(DocumentStatus.onHold);
    _forwardedDocumentsFuture = _fetchDocumentsByStatus(DocumentStatus.forwarded);
    _toReceiveDocumentsFuture = getToReceive();
    _cancelledDocumentsFuture = _fetchDocumentsByStatus(DocumentStatus.cancelled);
  }

  Future<List<TrackableDocument>> _fetchDocumentsByStatus(DocumentStatus status) async {
    List<TrackableDocument> documents = await getDocumentsByStatus(status);
    return documents;
  }

  Future<List<TrackableDocument>> getDocumentsByStatus(DocumentStatus status) {
    return getHoldersDocuments().then((documents) {
      return documents.where((doc) => doc.status == status).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainOrange,
          title: const Text("Holdings",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'OnHold'),
              Tab(text: 'Forwarded'),
              Tab(text: 'To receive'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<List<TrackableDocument>>(
              future: _onHoldDocumentsFuture,
              builder: (context, snapshot) {
                return HoldingsList(snapshot: snapshot);
              },
            ),
            FutureBuilder<List<TrackableDocument>>(
              future: _forwardedDocumentsFuture,
              builder: (context, snapshot) {
                return HoldingsList(snapshot: snapshot);
              },
            ),
            FutureBuilder<List<TrackableDocument>>(
              future: _toReceiveDocumentsFuture,
              builder: (context, snapshot) {
                return HoldingsList(snapshot: snapshot);
              },
            ),
            FutureBuilder<List<TrackableDocument>>(
              future: _cancelledDocumentsFuture,
              builder: (context, snapshot) {
                return HoldingsList(snapshot: snapshot);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Simple memory cache for base64 images
final Map<String, Image> _imageCache = {};

class HoldingsList extends StatelessWidget {
  final AsyncSnapshot<List<TrackableDocument>> snapshot;

  HoldingsList({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return const Center(child: Text('Error loading documents'));
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(child: Text('No documents found'));
    } else {
      List<TrackableDocument> documents = snapshot.data!;

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return GestureDetector(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    color: Colors.orange[50],
                    child: ListTile(
                      leading: doc.imageRefs.isNotEmpty && doc.imageRefs[0].isNotEmpty
                          ? Card(
                              child: FutureBuilder<Image?>(
                                future: _getCachedImage(doc.imageRefs[0]),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  } else if (snapshot.hasData) {
                                    return SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: snapshot.data,
                                    );
                                  } else {
                                    return const SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: Center(child: Text('No Image')),
                                    );
                                  }
                                },
                              ),
                            )
                          : null,
                      title: Text(doc.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String>(
                            future: _getHolderName(doc),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Current Holder: loading...');
                              } else if (snapshot.hasError) {
                                return const Text('Current Holder: error');
                              } else {
                                return Text('Current Holder: ${snapshot.data}');
                              }
                            },
                          ),
                          if (doc.status == DocumentStatus.forwarded)
                            FutureBuilder<String>(
                              future: _getForwardedToName(doc),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Forwarded to: loading...');
                                } else if (snapshot.hasError) {
                                  return const Text('Forwarded to: error');
                                } else {
                                  return Text('Forwarded to: ${snapshot.data}');
                                }
                              },
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            doc.lastUpdatedDate.toLocal().toString().split(' ')[0],
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            doc.status.toString().split('.').last,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentDetailsPage(documentKey: doc.key),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Future<Image?> _getCachedImage(String imageRef) async {
    if (_imageCache.containsKey(imageRef)) {
      return _imageCache[imageRef]!;
    }

    String? base64String = await getImage(imageRef);
    if (base64String != null) {
      final image = Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      _imageCache[imageRef] = image;
      return image;
    }

    return null;
  }

  Future<String> _getHolderName(TrackableDocument doc) async {
    HolderTracker? tracker = await getTrackerUsingKey(doc.currentHolderKey);
    return tracker?.fullName ?? 'Unknown';
  }

  Future<String> _getForwardedToName(TrackableDocument doc) async {
    String key = doc.records.last.receiverKey ?? '';
    if (key.isNotEmpty) {
      HolderTracker? tracker = await getTrackerUsingKey(key);
      return tracker?.fullName ?? 'Unknown';
    }
    return 'Unknown';
  }
}
