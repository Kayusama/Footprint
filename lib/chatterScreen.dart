import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footprint3/DocumentDetailsPage.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/ProfilePage.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/chat_class.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';
import 'package:intl/intl.dart';
import '../constants.dart';

late String messageText;

class ChatterScreen extends StatefulWidget {
  @override
  _ChatterScreenState createState() => _ChatterScreenState();
  Chat chat;
  ChatterScreen({required this.chat});
}

class _ChatterScreenState extends State<ChatterScreen> {
  final chatMsgTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  HolderTracker? recipientTracker;
  List<TrackableDocument> allDocs = [];
  List<String> allDocsTitles = [];
  List<String> filteredDocsTitles = [];

  @override
  void initState() {
    super.initState();
    getRecipient();
    fetchdocs();
  }

  Future<void> fetchdocs() async {
    allDocs = await getAllDocuments();
    allDocsTitles = allDocs.map((doc) => doc.key).toList();
  }

  void getRecipient() async {
    final recipientUid = widget.chat.holdersUid.firstWhere(
      (uid) => uid != curTracker.uid,
      orElse: () => '',
    );

    if (recipientUid.isEmpty) return;

    final tracker = await getTracker(recipientUid);
    if (tracker != null) {
      setState(() {
        recipientTracker = tracker;
      });
    }
  }

  void onTextChanged(String value) {
    setState(() {
      messageText = value;
      final lastWord = value.split(' ').last;
      if (lastWord.startsWith('@')) {
        filteredDocsTitles = allDocsTitles
            .where((title) =>
                title.toLowerCase().startsWith(lastWord.substring(1).toLowerCase()))
            .toList();
    print(filteredDocsTitles);

      } else {
        filteredDocsTitles = [];
      }
    });
  }

  void insertMention(String mention) {
    final words = messageText.split(' ');
    if (words.isNotEmpty) {
      words.removeLast(); // Remove the current @...
    }
    words.add('@$mention'); // Add selected mention
    final newText = words.join(' ');
    setState(() {
      messageText = newText;
      chatMsgTextController.text = newText;
      chatMsgTextController.selection = TextSelection.fromPosition(
        TextPosition(offset: chatMsgTextController.text.length),
      );
      filteredDocsTitles = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.deepPurple),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size(25, 10),
          child: Container(
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.blue[100],
            ),
            constraints: BoxConstraints.expand(height: 1),
          ),
        ),
        backgroundColor: Colors.white10,
        title: Row(
          children: <Widget>[
            GestureDetector(
              child: CircleAvatar(
                radius: 20,
                backgroundImage: (recipientTracker?.profilePicture?.isNotEmpty ?? false)
                    ? MemoryImage(base64Decode(recipientTracker?.profilePicture ?? ''))
                    : null,
                child: (recipientTracker?.profilePicture?.isEmpty ?? true)
                    ? Text(
                        recipientTracker?.fullName[0] ?? '',
                        style: TextStyle(
                          color: mainOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(user: recipientTracker ?? HolderTracker.empty())),
              ),
            ),
            SizedBox(width: 10),
            Text(
              recipientTracker?.fullName ?? '',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(child: Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChatStream(chatID: widget.chat.key, allDocs: allDocs,),

          // MENTION SUGGESTIONS DROPDOWN
          if (filteredDocsTitles.isNotEmpty)
            Container(
              height: 150,
              color: Colors.blueAccent,
              child: ListView.builder(
                itemCount: filteredDocsTitles.length,
                itemBuilder: (context, index) {
                  final mention = filteredDocsTitles[index];
                  return ListTile(
                    title: Text(mention),
                    onTap: () => insertMention(mention),
                  );
                },
              ),
            ),

          // INPUT BAR
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: kMessageContainerDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Material(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white,
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                      child: TextField(
                        controller: chatMsgTextController,
                        onChanged: onTextChanged,
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                  ),
                ),
                MaterialButton(
                  shape: CircleBorder(),
                  color: Colors.blue,
                  onPressed: () {
                    chatMsgTextController.clear();
                    sendMessage(
                      widget.chat.key,
                      Message(
                        text: messageText,
                        senderUid: curTracker.uid,
                        timestamp: DateTime.now(),
                        isDeleted: false,
                      ),
                    );
                    setState(() {
                      messageText = '';
                      filteredDocsTitles = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class ChatStream extends StatelessWidget {
  final String chatID;
  final List<TrackableDocument> allDocs;

  ChatStream({required this.chatID, required this.allDocs});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('Chats').doc(chatID).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(backgroundColor: Colors.deepPurple),
          );
        }

        var chatData = snapshot.data!.data() as Map<String, dynamic>?;

        if (chatData == null || !chatData.containsKey('messages')) {
          return Center(child: Text("No messages yet."));
        }


List<dynamic> messagesData = chatData['messages'];

List<Widget> messageWidgets = messagesData.reversed.map<Widget>((msg) {
  final message = Message.fromMap(msg);
  final words = message.text.split(' ');
  bool isMe() => message.senderUid == curTracker.uid;
  
  for (var word in words) {
    
    if (word.startsWith('@')) {
      final docTitle = word.substring(1);
      final doc = allDocs.firstWhere(
        (d) => d.key == docTitle,
        orElse: () => TrackableDocument.empty(),
      );

      if (doc.key.isNotEmpty) {
        return Align(
          alignment: isMe() ? Alignment.centerRight : Alignment.centerLeft, // or centerRight, based on your UI
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 200),
              child: documentCard(doc, context),
            ),
          ),
        );
      }
    }
  }

  return MessageBubble(message: message, chatID: chatID);
}).toList();




        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            children: messageWidgets,
          ),
        );
      },
    );
  }

  Widget documentCard(TrackableDocument doc, BuildContext context) {
    return GestureDetector(
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        child: ListTile(
          leading: Icon(Icons.document_scanner, color: Colors.orange),
          title: Text(doc.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: 70,
                child: FutureBuilder<String?>(
                      future: getImage(doc.imageRefs[0]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(base64Decode(snapshot.data!), fit: BoxFit.cover);
                        } else {
                          return Center(child: Text('Image not available'));
                        }
                      },
                    )
              ),
              Text("Status: ${doc.status.label}"),
              Text("Current Holder: ${doc.currentHolderKey}"),
              Text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(doc.lastUpdatedDate)}"),
            ],
          ),
        ),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentDetailsPage(documentKey: '${doc.key}',
          ),
        ),
      ),
    );
  }
}


class MessageBubble extends StatelessWidget {
  final Message message;
  final String chatID; // Added chatID so we know where to delete

  MessageBubble({required this.message, required this.chatID});

  bool get isMe => message.senderUid == curTracker.uid;

  Future<HolderTracker> getTrackerFuture() async {
    return await getTracker(message.senderUid) ?? HolderTracker.empty();
  }

  void _confirmDelete(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // DELETE the message from Firestore
      await _deleteMessageFromFirestore();
    }
  }

  Future<void> _deleteMessageFromFirestore() async {
    try {
      final chatDoc = FirebaseFirestore.instance.collection('Chats').doc(chatID);
      final chatSnapshot = await chatDoc.get();

      if (chatSnapshot.exists) {
        List<dynamic> messages = chatSnapshot['messages'];

        // Find and remove the specific message (by timestamp and senderUid)
        messages.removeWhere((m) =>
            m['timestamp'] == message.timestamp && m['senderUid'] == message.senderUid);

        await chatDoc.update({'messages': messages});
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HolderTracker>(
      future: getTrackerFuture(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text("Loading...", style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
          );
        }

        HolderTracker tracker = snapshot.data!;

        return GestureDetector(
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return SafeArea(
                  child: Wrap(
                    children: <Widget>[
                      ListTile(
                        leading: Icon(Icons.arrow_back, color: Colors.black),
                        title: Text('Reply'),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDelete(context);
                        },
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        leading: Icon(Icons.edit, color: Colors.black),
                        title: Text('Edit'),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDelete(context);
                        },
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete'),
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDelete(context);
                        },
                      ),
                      SizedBox(height: 10),

                    ],
                  ),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    tracker.fullName,
                    style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.black87),
                  ),
                ),
                Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    isMe
                        ? Material(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.blue,
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(),
                    GestureDetector(
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: (tracker.profilePicture.isNotEmpty)
                            ? MemoryImage(base64Decode(tracker.profilePicture))
                            : null,
                        child: (tracker.profilePicture.isEmpty)
                            ? Text(
                                tracker.fullName[0],
                                style: TextStyle(
                                  color: mainOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage(user: tracker)),
                      ),
                    ),
                    isMe
                        ? SizedBox()
                        : Material(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.white,
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget documentCard(TrackableDocument doc, BuildContext context) {
    return GestureDetector(
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        child: ListTile(
          leading: Icon(Icons.document_scanner, color: Colors.orange),
          title: Text(doc.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 100,
                width: 70,
                child: FutureBuilder<String?>(
                      future: getImage(doc.imageRefs[0]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(base64Decode(snapshot.data!), fit: BoxFit.cover);
                        } else {
                          return Center(child: Text('Image not available'));
                        }
                      },
                    )
              ),
              Text("Status: ${doc.status.label}"),
              Text("Current Holder: ${doc.currentHolderKey}"),
              Text("Date: ${DateFormat('yyyy-MM-dd HH:mm').format(doc.lastUpdatedDate)}"),
            ],
          ),
        ),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentDetailsPage(documentKey: '${doc.key}',
            
          ),
        ),
      ),
    );
  }
}
