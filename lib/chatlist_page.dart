import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:footprint3/HolderTracker_class.dart';
import 'package:footprint3/chat_class.dart';
import 'package:footprint3/chatterScreen.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';

class ChatList extends StatefulWidget {
  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  List<HolderTracker> suggestedUsers = [];
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  List<HolderTracker> allUsers = [];
  List<Chat> chats = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_filterChats);
    _fetchAllUsers();
  }

  Stream<List<Chat>> get userChatsStream => getUserChatsStream(curTracker.uid);


  // Future<void> _fetchAllchats() async {
  //   chats = await getUserChats(curTracker.uid);
  //   print("Fetched ${chats.length} chats for user ${curTracker.uid}");
  //   setState(() {});
  // }


  /// Fetches all users from the database
  Future<void> _fetchAllUsers() async {
  allUsers = await getAllTrackers();
  if (mounted) {
    setState(() {});
  }
}

  /// Filters the list based on the search input
  void _filterChats() {
    String query = searchController.text.toLowerCase().trim();
    setState(() {
      isSearching = query.isNotEmpty;
      suggestedUsers = allUsers
      .where((user) => 
          user.fullName.toLowerCase().contains(query) && 
          user.uid != curTracker.uid)
      .toList();

    });
  }

  /// Selects a suggested user and clears search
  Future<void> _selectSuggestion(HolderTracker user) async {
    searchController.text = user.fullName;
    for (Chat chat in chats) {
      for(var uid in chat.holdersUid){
        if (uid == user.uid) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatterScreen(chat: chat),
            ),
          );
          return;
        }
      }
    }
    // If no chat found, you can handle it here (e.g., show a message)
    Chat newChat = Chat(
      key: '', 
      holdersUid: [curTracker.uid, user.uid], 
      lastMessage: '', 
      timestamp: DateTime.now(), 
      messages: [], 
      hasRead: false, 
      isDeleted: false
    );

    String? chatID = await addChat(newChat);
    if (chatID != null) {
      newChat.key = chatID; // Update the chat object with the new ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatterScreen(chat: newChat),
        ),
      );
    }
    
    setState(() {
      isSearching = false;
      suggestedUsers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainOrange,
        title: const Text("Chats",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isSearching ? _buildSuggestedUsersList() : _buildChatList(),
          ),
        ],
      ),
    );
  }

  /// Builds the search bar UI
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Start a conversation",
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Builds the list of suggested users
  Widget _buildSuggestedUsersList() {
    return ListView.builder(
      itemCount: suggestedUsers.length,
      itemBuilder: (context, index) {
        final name = suggestedUsers[index].fullName;
        return ListTile(
          title: Text(name, style: const TextStyle(color: Colors.white)),
          onTap: () => _selectSuggestion(suggestedUsers[index]),
        );
      },
    );
  }

  Future<HolderTracker?> _getOtherUserTracker(Chat chat) async {
    String uid = chat.holdersUid[0] == curTracker.uid ? chat.holdersUid[1] : chat.holdersUid[0];
    return await getTracker(uid);
  }


  /// Builds the main chat list
  Widget _buildChatList() {
  return StreamBuilder<List<Chat>>(
    stream: userChatsStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(
          child: Text("Error loading chats", style: TextStyle(color: Colors.white)),
        );
      }

      final chats = snapshot.data ?? [];
      if (chats.isEmpty) {
        return Center(
          child: Text("No chats yet", style: TextStyle(color: mainOrange)),
        );
      }

      return ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return FutureBuilder<HolderTracker?>(
            future: _getOtherUserTracker(chat),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                  title: Text("Loading...", style: TextStyle(color: Colors.white)),
                );
              }

              if (!userSnapshot.hasData) {
                return SizedBox();
              }

              final tracker = userSnapshot.data!;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
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
                  title: Text(tracker.fullName, style: TextStyle(color: mainOrange)),
                  subtitle: Text(chat.lastMessage, style: TextStyle(color: Colors.grey)),
                  trailing: Text(formatTimeDifference(chat.timestamp), style: TextStyle(color: Colors.grey)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatterScreen(chat: chat),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    },
  );
}
}