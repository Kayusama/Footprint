import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:footprint3/DocumentRecord_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/imageGallery.dart';
import 'package:footprint3/utils.dart';
import 'package:timelines/timelines.dart';
import 'TrackableDocument_class.dart';

// TrackDocumentPage displays the tracking information of a document.
class TrackDocumentPage extends StatelessWidget {
  final TrackableDocument trackableDocument;

  const TrackDocumentPage({Key? key, required this.trackableDocument}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Track Document",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _DocumentTitle(trackableDocument: trackableDocument),
            ),
            Divider(height: 1.0),
            _DeliveryProcesses(records: trackableDocument.records),
            Divider(height: 1.0),
          ],
        ),
      ),
    );
  }
}

// _DocumentTitle displays the document's tracking number and creation date.
class _DocumentTitle extends StatelessWidget {
  final TrackableDocument trackableDocument;

  const _DocumentTitle({Key? key, required this.trackableDocument}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Tracking #${trackableDocument.key}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15.0,
          ),
        ),
        Spacer(),
        Text(
          '${trackableDocument.createdDate.day}/${trackableDocument.createdDate.month}/${trackableDocument.createdDate.year}',
          style: TextStyle(
            color: Color(0xffb6b2b2),
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }
}

class _DeliveryProcesses extends StatelessWidget {
  final List<DocumentRecord> records;

  const _DeliveryProcesses({Key? key, required this.records}) : super(key: key);

  Future<String> getUsernameFromKey(String key) async {
    var tracker = await getTrackerUsingKey(key);
    return tracker?.fullName ?? "Unknown Holder";
  }

  Future<String> getReceiverFromKey(String key) async {
    var receiver = await getTrackerUsingKey(key);
    return receiver?.fullName ?? "Unknown Receiver";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: FixedTimeline.tileBuilder(
        theme: TimelineThemeData(
          nodePosition: 0,
          color: Color(0xff989898),
          indicatorTheme: IndicatorThemeData(
            position: 0,
            size: 20.0,
          ),
          connectorTheme: ConnectorThemeData(
            thickness: 2.5,
          ),
        ),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          itemCount: records.length,
          contentsBuilder: (_, index) {
            return FutureBuilder<String>(
              future: getUsernameFromKey(records[index].holder),
              builder: (context, holderSnapshot) {
                return FutureBuilder<String>(
                  future: getReceiverFromKey(records[index].receiverKey ?? ""),
                  builder: (context, receiverSnapshot) {
                    if (holderSnapshot.connectionState == ConnectionState.waiting || receiverSnapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: CircularProgressIndicator(),
                      );
                    } else if (holderSnapshot.hasError || receiverSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text("Error: ${holderSnapshot.error ?? receiverSnapshot.error}"),
                      );
                    } else if (holderSnapshot.hasData && receiverSnapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimelineText("Holder: ${holderSnapshot.data}", fontSize: 18.0),
                                _buildTimelineText("Status: ${records[index].status.label}", fontSize: 16.0),
                                _buildTimelineText("Remarks: ${records[index].remarks}", fontSize: 14.0),
                                if (records[index].receiverKey != null)
                                  _buildTimelineText("Receiver: ${receiverSnapshot.data}", fontSize: 14.0),
                                SizedBox(height: 20),
                              ],
                            ),
                            Spacer(),
                            Column(
                              children: [
                                if(records[index].imageRefs.isNotEmpty)
                                  Container(
                                    width: 70,
                                    height: 100,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ImageGalleryPage(record: records[index]),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        child: FutureBuilder<String?>(
                                          future: getImage(records[index].imageRefs[0]),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator());
                                            } else if (snapshot.hasData && snapshot.data != null) {
                                              return ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.memory(
                                                  base64Decode(snapshot.data!),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                ),
                                              );
                                            } else {
                                              return const Center(child: Text('Image not available'));
                                            }
                                          },
                                        ),
                                      ),
                                    )
                                  ),
                              ],

                            )
                          ],
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text("Holder: Unknown"),
                      );
                    }
                  },
                );
              },
            );
          },
          indicatorBuilder: (_, index) {
            final status = records[index].status;
            return DotIndicator(
              color: getStatusColor(status),
              child: Icon(
                getStatusIcon(status),
                color: Colors.white,
                size: 12.0,
              ),
            );
          },
          connectorBuilder: (_, index, ___) => SolidLineConnector(
            color: getStatusColor(records[index].status),
          ),
        ),
      ),
    );
  }

  // Helper method to build timeline text with custom style
  Widget _buildTimelineText(String text, {required double fontSize}) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize),
    );
  }
}

// === Helper Functions === //

Color getStatusColor(DocumentStatus status) {
  switch (status) {
    case DocumentStatus.registered:
      return Colors.blue;
    case DocumentStatus.onHold:
      return Colors.orange;
    case DocumentStatus.forwarded:
      return Colors.purple;
    case DocumentStatus.received:
      return Colors.green;
    case DocumentStatus.archived:
      return Colors.grey;
    case DocumentStatus.cancelled:
      return Colors.red;
  }
}

IconData getStatusIcon(DocumentStatus status) {
  switch (status) {
    case DocumentStatus.registered:
      return Icons.edit_document; // optional: Icons.article
    case DocumentStatus.onHold:
      return Icons.pause_circle_filled;
    case DocumentStatus.forwarded:
      return Icons.send;
    case DocumentStatus.received:
      return Icons.check_circle;
    case DocumentStatus.archived:
      return Icons.archive;
    case DocumentStatus.cancelled:
      return Icons.cancel;
  }
}
