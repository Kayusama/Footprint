import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:footprint3/DocumentRecord_class.dart';
import 'package:footprint3/Notifications_page.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/chat_class.dart';
import 'package:footprint3/utils.dart';
import 'HolderTracker_class.dart';
import 'package:footprint3/Feedback_class.dart' as FeedbackClass;



final FirebaseFirestore firestore = FirebaseFirestore.instance;
final CollectionReference documentsCollection = firestore.collection('Documents');
final CollectionReference trackersCollection = firestore.collection('Trackers');
final CollectionReference chatsCollection = FirebaseFirestore.instance.collection('Chats');
final CollectionReference notificationsCollection = FirebaseFirestore.instance.collection('Notifications');


Future<String?> addTracker(HolderTracker tracker) async {
  try {
    DocumentReference docRef = await trackersCollection.add(tracker.toJson());
    await docRef.update({'key': docRef.id}); // Store Firestore-generated ID
    print('Tracker added successfully with ID: ${docRef.id}');
    return docRef.id; // Return the generated ID
  } catch (error) {
    print('Failed to add Tracker: $error');
    return null; // Return null if there was an error
  }
}

Future<void> updateTracker(HolderTracker tracker) async {
  try {
    if (tracker.key.isEmpty) {
      print('Error: Tracker key is null');
      return;
    }
    await trackersCollection.doc(tracker.key).update(tracker.toJson());
    print('Tracker updated successfully');
  } catch (error) {
    print('Failed to update Tracker: $error');
  }
}

Future<List<HolderTracker>> getAllTrackers() async {
  try {
    QuerySnapshot querySnapshot = await trackersCollection.get();
    return querySnapshot.docs
        .map((doc) => HolderTracker.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'key': doc.id,
            }))
        .toList();
  } catch (error) {
    print('Failed to get trackers: $error');
    return [];
  }
}

Future<HolderTracker?> getTrackerUsingKey(String key) async {
  try {
    DocumentSnapshot docSnapshot = await trackersCollection.doc(key).get();

    if (docSnapshot.exists) {
      return HolderTracker.fromJson({
        ...docSnapshot.data() as Map<String, dynamic>,
        'key': docSnapshot.id,
      });
    } else {
      print('Tracker not found for the provided key: $key');
      return null;
    }
  } catch (error) {
    print('Failed to get tracker with key $key: $error');
    return null;
  }
}


Future<void> deleteTracker(String trackerID) async {
  try {
    await trackersCollection.doc(trackerID).delete();
    print('Tracker deleted successfully');
  } catch (error) {
    print('Failed to delete Tracker: $error');
  }
}

Future<HolderTracker?> getTracker(String uid) async {
  try {
    QuerySnapshot querySnapshot =
        await trackersCollection.where('uid', isEqualTo: uid).get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first;
      return HolderTracker.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'key': doc.id,
      });
    }
  } catch (error) {
    print('Failed to fetch tracker: $error');
  }
  return null;
}

Future<String?> addDocument(TrackableDocument document) async {
  try {
    // Add the document first
    DocumentReference docRef = await documentsCollection.add(document.toJson());
    await docRef.update({'key': docRef.id});
    print('Document added successfully with ID: ${docRef.id}');
    return docRef.id;
  } catch (error) {
    print('Failed to add Document: $error');
    return null;
  }
}


Future<void> updateDocument(TrackableDocument document) async {
  try {
    if (document.key.isEmpty) {
      print('Error: Document key is null');
      return;
    }
    await documentsCollection.doc(document.key).update(document.toJson());
    print('Document updated successfully');
  } catch (error) {
    print('Failed to update Document: $error');
  }
}

Future<List<TrackableDocument>> getAllDocuments() async {
  try {
    QuerySnapshot querySnapshot = await documentsCollection.get();
    return querySnapshot.docs
        .map((doc) => TrackableDocument.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'key': doc.id,
            }))
        .toList();
  } catch (error) {
    print('Failed to get documents: $error');
    return [];
  }
}

Stream<List<TrackableDocument>> getAllDocumentsStream() {
  return documentsCollection          
      .snapshots()                    
      .map((QuerySnapshot snap) =>   
          snap.docs
              .map((doc) => TrackableDocument.fromJson({
                    ...doc.data() as Map<String, dynamic>,
                    'key': doc.id,   
                  }))
              .toList())
      .handleError((error) {
        print('Failed to stream documents: $error');
      });
}

Future<List<TrackableDocument>> getToReceive() async {
  try {
    QuerySnapshot querySnapshot = await documentsCollection.get();

    List<TrackableDocument> allDocuments = querySnapshot.docs.map((doc) {
      return TrackableDocument.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'key': doc.id,
      });
    }).toList();

    List<TrackableDocument> filteredDocuments = allDocuments.where((document) {
      List<DocumentRecord> records = document.records;
      if (records.isEmpty) return false;
      var latestRecord = records.last;

      return latestRecord.status == DocumentStatus.forwarded &&
             latestRecord.receiverKey == curTracker.key;
    }).toList();

    print("found only ${filteredDocuments.length}");

    return filteredDocuments;
  } catch (error) {
    print('Failed to get documents: $error');
    return [];
  }
}


Future<List<TrackableDocument>> getHoldersDocuments() async {
  try {
    QuerySnapshot querySnapshot = await documentsCollection
        .where('currentHolderKey', isEqualTo: curTracker.key)
        .get();

    return querySnapshot.docs
        .map((doc) => TrackableDocument.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'key': doc.id,
            }))
        .toList();
  } catch (error) {
    print('Failed to get filtered documents: $error');
    return [];
  }
}


Stream<List<TrackableDocument>> getHoldersDocumentsStream() {
  return documentsCollection
      .where('currentHolderKey', isEqualTo: curTracker.key)
      .snapshots()
      .map((querySnapshot) => querySnapshot.docs.map((doc) {
            return TrackableDocument.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'key': doc.id,
            });
          }).toList());
}



Future<void> deleteDocument(String documentID) async {
  try {
    await documentsCollection.doc(documentID).delete();
    print('Document deleted successfully');
  } catch (error) {
    print('Failed to delete Document: $error');
  }
}

Future<TrackableDocument?> getDocument(String key) async {
  try {
    QuerySnapshot querySnapshot =
        await documentsCollection.where('key', isEqualTo: key).get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first;
      return TrackableDocument.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'key': doc.id,
      });
    }
  } catch (error) {
    print('Failed to fetch document: $error');
  }
  return null;
}
Future<TrackableDocument?> getDocumentbyCode(String code) async {
  try {
    QuerySnapshot querySnapshot =
        await documentsCollection.where('scancode', isEqualTo: code).get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first;
      return TrackableDocument.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'key': doc.id,
      });
    }
  } catch (error) {
    print('Failed to fetch document: $error');
  }
  return null;
}
Stream<TrackableDocument?> getDocumentStream(String key) {
  return documentsCollection
      .where('key', isEqualTo: key)
      .snapshots()
      .map((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          return TrackableDocument.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'key': doc.id,
          });
        } else {
          return null;
        }
      }).handleError((error) {
        print('Failed to fetch document: $error');
        return null;
      });
}

Future<String?> addChat(Chat chat) async {
  try {
    DocumentReference docRef = await chatsCollection.add(chat.toJson());
    await docRef.update({'key': docRef.id}); // Store Firestore-generated ID
    print('Chat added successfully with ID: ${docRef.id}');

    return docRef.id; // Return the generated ID
  } catch (error) {
    print('Failed to add Chat: $error');
    return null; // Return null if there was an error
  }
}

Future<void> updateChat(Chat chat) async {
  try {
    if (chat.key.isEmpty) {
      print('Error: Chat key is null');
      return;
    }
    await chatsCollection.doc(chat.key).update(chat.toJson());
    print('Chat updated successfully');
  } catch (error) {
    print('Failed to update Chat: $error');
  }
}

Stream<List<Chat>> getUserChatsStream(String userUid) {
  return chatsCollection
      .where('holdersUid', arrayContains: userUid)
      .snapshots()
      .map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return Chat.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'key': doc.id,
          });
        }).toList();
      });
}


Future<void> deleteChat(String chatID) async {
  try {
    await chatsCollection.doc(chatID).delete();
    print('Chat deleted successfully');
  } catch (error) {
    print('Failed to delete Chat: $error');
  }
}

Future<Chat?> getChat(String chatID) async {
  try {
    DocumentSnapshot doc = await chatsCollection.doc(chatID).get();
    if (doc.exists) {
      return Chat.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'key': doc.id,
      });
    }
  } catch (error) {
    print('Failed to fetch chat: $error');
  }
  return null;
}

Future<void> sendMessage(String chatID, Message message) async {
  try {
    DocumentReference chatRef = chatsCollection.doc(chatID);
    await chatRef.update({
      'messages': FieldValue.arrayUnion([message.toMap()]),
      'lastMessage': message.text,
      'timestamp': message.timestamp.toIso8601String(),
    });
    print('Message sent successfully');
  } catch (error) {
    print('Failed to send message: $error');
  }
}

Future<List<Message>> getMessages(String chatID) async {
  try {
    DocumentSnapshot doc = await chatsCollection.doc(chatID).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return (data['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromMap(e))
              .toList() ??
          [];
    }
  } catch (error) {
    print('Failed to fetch messages: $error');
  }
  return [];
}


Future<String?> addNotification(NotificationItem notification) async {
  try {
    // Add the notification first
    DocumentReference docRef = await notificationsCollection.add(notification.toJson());
    await docRef.update({'key': docRef.id});
    print('Notification added successfully with ID: ${docRef.id}');
    return docRef.id;
  } catch (error) {
    print('Failed to add Notification: $error');
    return null;
  }
}


Future<void> updateNotification(NotificationItem notification) async {
  try {
    if (notification.key.isEmpty) {
      print('Error: Notification key is null');
      return;
    }
    await notificationsCollection.doc(notification.key).update(notification.toJson());
    print('Notification updated successfully');
  } catch (error) {
    print('Failed to update Notification: $error');
  }
}

Future<List<NotificationItem>> getAllNotifications() async {
  try {
    QuerySnapshot querySnapshot = await notificationsCollection.get();
    return querySnapshot.docs
        .map((doc) => NotificationItem.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'key': doc.id,
            }))
        .toList();
  } catch (error) {
    print('Failed to get notifications: $error');
    return [];
  }
}


Future<List<NotificationItem>> getHoldersNotifications() async {
  try {
    QuerySnapshot querySnapshot = await notificationsCollection
        .where('trackerKey', isEqualTo: curTracker.key)
        .get();

    return querySnapshot.docs
        .map((doc) => NotificationItem.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'key': doc.id,
            }))
        .toList();
  } catch (error) {
    print('Failed to get filtered notifications: $error');
    return [];
  }
}

Stream<List<NotificationItem>> getNotificationsStream() {
  return FirebaseFirestore.instance
      .collection('Notifications')
      .where('trackerKey', isEqualTo: curTracker.key)  // Filter added here
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => NotificationItem.fromJson(doc.data() as Map<String, dynamic>))
          .toList());
}




Future<void> deleteNotification(String notificationID) async {
  try {
    await notificationsCollection.doc(notificationID).delete();
    print('Notification deleted successfully');
  } catch (error) {
    print('Failed to delete Notification: $error');
  }
}

Future<NotificationItem?> getNotification(String key) async {
  try {
    QuerySnapshot querySnapshot =
        await notificationsCollection.where('key', isEqualTo: key).get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first;
      return NotificationItem.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'key': doc.id,
      });
    }
  } catch (error) {
    print('Failed to fetch notification: $error');
  }
  return null;
}

Future<void> addFeedItem(FeedbackClass.Feedback feedItem) async {
  try {
    await firestore.collection('FeedItem').add(feedItem.toJson());
    print('FeedItem added successfully');
  } catch (error) {
    print('Failed to add feedItem: $error');
  }
}

Future<void> updateFeedItem(FeedbackClass.Feedback feedItem) async {
  try {
    await firestore.collection('FeedItem').doc(feedItem.key).update(feedItem.toJson());
    print('FeedItem updated successfully');
  } catch (error) {
    print('Failed to update feedItem: $error');
  }
}

Future<void> deleteFeedItem(String feedItemId) async {
  try {
    await firestore.collection('FeedItem').doc(feedItemId).delete();
    print('FeedItem deleted successfully');
  } catch (error) {
    print('Failed to delete feedItem: $error');
  }
}

Future<List<FeedbackClass.Feedback>> getAllFeedItems() async {
  try {
    QuerySnapshot snapshot = await firestore.collection('FeedItem').get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['key'] = doc.id;
      return FeedbackClass.Feedback.fromJson(data);
    }).toList();
  } catch (error) {
    print('Failed to fetch feedItems: $error');
    return [];
  }
}

Stream<List<FeedbackClass.Feedback>> streamAllFeedItems() {
  try {
    return firestore.collection('FeedItem').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['key'] = doc.id;
        return FeedbackClass.Feedback.fromJson(data);
      }).toList();
    });
  } catch (error) {
    print('Failed to stream feedItems: $error');
    return Stream.value([]);
  }
}

Future<String?> uploadImage(String base64) async {
  try {
    // Store the base64 image directly under the Images collection
    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('Images')
        .add({'base64': base64});

    print('Image uploaded successfully with ID: ${docRef.id}');
    return docRef.id;
  } catch (error) {
    print('Failed to upload image: $error');
    return null;
  }
}

Future<String?> getImage(String key) async {
  try {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('Images')
        .doc(key)
        .get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      return data['base64'] as String?;
    } else {
      print('Image not found for the provided key: $key');
      return null;
    }
  } catch (error) {
    print('Failed to get image with key $key: $error');
    return null;
  }
}

