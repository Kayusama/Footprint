import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  String key;
  List<String> holdersUid;
  String lastMessage;
  DateTime timestamp;
  List<Message> messages;
  bool hasRead;
  bool isDeleted;

  // Constructor
  Chat({
    required this.key,
    required this.holdersUid,
    required this.lastMessage,
    required this.timestamp,
    required this.messages,
    required this.hasRead,
    required this.isDeleted,
  });

  // Named empty constructor
  Chat.empty()
      : key = '',
        holdersUid = [],
        lastMessage = '',
        timestamp = DateTime.now(),
        messages = [],
        hasRead = false,
        isDeleted = false;

  // Factory method to create Chat from Firestore DocumentSnapshot
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Chat(
      key: doc.id,
      holdersUid: List<String>.from(data['holdersUid'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      messages: (data['messages'] as List<dynamic>?)
              ?.map((e) => Message.fromMap(e))
              .toList() ??
          [],
      hasRead: data['hasRead'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  // Factory method to create a Chat object from JSON
  factory Chat.fromJson(Map<String, dynamic> data) {
    return Chat(
      key: data['key'] ?? '',
      holdersUid:
          (data['holdersUid'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastMessage: data['lastMessage'] ?? '',
      timestamp: (data['timestamp'] != null)
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      messages:
          (data['messages'] as List<dynamic>?)?.map((e) => Message.fromMap(e)).toList() ?? [],
      hasRead: data['hasRead'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  // Convert a Chat object to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'holdersUid': holdersUid,
      'lastMessage': lastMessage,
      'timestamp': timestamp.toIso8601String(),
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'hasRead': hasRead,
      'isDeleted': isDeleted,
    };
  }
}

class Message {
  String text;
  String senderUid;
  DateTime timestamp;
  bool isDeleted; // <-- Added here

  Message({
    required this.text,
    required this.senderUid,
    required this.timestamp,
    required this.isDeleted,
  });

  // Convert a Message object to a Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderUid': senderUid,
      'timestamp': timestamp.toIso8601String(),
      'isDeleted': isDeleted, // <-- Added here
    };
  }

  // Create a Message object from a Map (e.g., from Firebase)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'] ?? '',
      senderUid: map['senderUid'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isDeleted: map['isDeleted'] ?? false, // <-- Added here
    );
  }
}
