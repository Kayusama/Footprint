import 'package:flutter/material.dart';
import 'package:footprint3/DocumentDetailsPage.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Stream<List<NotificationItem>> notificationsStream;

  @override
  void initState() {
    super.initState();
    notificationsStream = getNotificationsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // Select all functionality
            },
            child: Text('Select all', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Filter functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationItem>>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${notifications.length} notifications',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            // Mark all as read functionality
                            setState(() {
                              notifications.forEach((item) => item.isRead = true);
                              // updateNotificationsBatch(notifications); // Make sure to update the DB if needed
                            });
                          },
                          child: Text('Mark as Read'),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            // Delete selected notifications
                            setState(() {
                              notifications.removeWhere((item) => item.isSelected);
                              // deleteSelectedNotifications(notifications); // Delete them from DB if needed
                            });
                          },
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
  child: Builder(
    builder: (context) {
      // Sort notifications by time descending
      final sortedNotifications = [...notifications]
        ..sort((a, b) => DateTime.parse(b.time).compareTo(DateTime.parse(a.time)));

      return ListView.builder(
        itemCount: sortedNotifications.length,
        itemBuilder: (context, index) {
          final notification = sortedNotifications[index];
          return ListTile(
            title: Text(notification.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.time), // Time
                if (notification.content?.isNotEmpty ?? false) ...[
                  SizedBox(height: 4),
                  Text(
                    notification.content ?? '',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
            leading: notification.isSelected
                ? Icon(Icons.check_circle, color: Colors.blue)
                : null,
            tileColor: notification.isRead ? null : Colors.blue[50],
            onTap: () async {
              notification.isRead = true;
              updateNotification(notification);
              TrackableDocument? document = await getDocument(notification.documentKey);
              print("Document: ${document?.title ?? "Document not found"}");

              if (document != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DocumentDetailsPage(documentKey: document.key,),
                  ),
                );
              }
            },
            onLongPress: () {
              setState(() {
                notification.isSelected = !notification.isSelected;
              });
            },
          );
        },
      );
    },
  ),
),
 
            ],
          );
        },
      ),
    );
  }
}


class NotificationItem {
  String key;
  String documentKey;
  String trackerKey;
  String title;
  String time;
  bool isRead;
  bool isSelected;
  String content; // New content field

  NotificationItem({
    required this.key,
    required this.documentKey,
    required this.trackerKey,
    required this.title,
    required this.time,
    this.isRead = false,
    this.isSelected = false,
    required this.content, // Accept content in the constructor
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      key: json['key'] as String,
      documentKey: json['documentKey'] as String,
      trackerKey: json['trackerKey'] as String,
      title: json['title'] as String,
      time: json['time'] as String,
      isRead: json['isRead'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? false,
      content: json['content'] as String, // Map the content from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'documentKey': documentKey,
      'trackerKey': trackerKey,
      'title': title,
      'time': time,
      'isRead': isRead,
      'isSelected': isSelected,
      'content': content, // Include content in the JSON map
    };
  }
}
