import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KitchenChatScreen extends StatefulWidget {
  @override
  _KitchenChatScreenState createState() => _KitchenChatScreenState();
}

class _KitchenChatScreenState extends State<KitchenChatScreen> {
  final String kitchenId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _controller = TextEditingController();
  String? selectedUserId;
  List<Map<String, dynamic>> cachedMessages = [];

  // Save messages to Shared Preferences
  Future<void> saveKitchenMessages(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'kitchen_${kitchenId}_user_${selectedUserId}_messages';
    String timeKey = 'kitchen_${kitchenId}_user_${selectedUserId}_time';

    await prefs.setString(key, jsonEncode(messages));
    await prefs.setString(timeKey, DateTime.now().toIso8601String());
  }

  // Load cached messages from Shared Preferences
  Future<void> loadKitchenMessages() async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'kitchen_${kitchenId}_user_${selectedUserId}_messages';
    String timeKey = 'kitchen_${kitchenId}_user_${selectedUserId}_time';

    String? cached = prefs.getString(key);
    String? cachedTime = prefs.getString(timeKey);

    if (cached != null && cachedTime != null) {
      DateTime cacheTime = DateTime.parse(cachedTime);
      if (DateTime.now().difference(cacheTime) < Duration(hours: 1)) {
        setState(() {
          cachedMessages = List<Map<String, dynamic>>.from(jsonDecode(cached));
        });
      } else {
        await prefs.remove(key);
        await prefs.remove(timeKey);
      }
    }
  }


  Future<List<String>> fetchUsers() async {
    print("Starting fetchUsers()...");

    // Look inside ALL user_inbox collections across Firestore
    QuerySnapshot userInboxes = await FirebaseFirestore.instance
        .collectionGroup("user_inbox")
        .get(const GetOptions(source: Source.server));

    print("Total user_inbox documents fetched: ${userInboxes.docs.length}");

    List<String> activeUserIds = [];

    for (var doc in userInboxes.docs) {
      // Example doc.path: kitchen_chats/{kitchenId}/messages/{userId}/user_inbox/{inboxDocId}
      final pathSegments = doc.reference.path.split('/');

      final userId = pathSegments[pathSegments.indexOf('messages') + 1];
      final docKitchenId = pathSegments[pathSegments.indexOf('kitchen_chats') + 1];

      print("Found doc for kitchenId: $docKitchenId, userId: $userId");

      if (docKitchenId == kitchenId) {
        if (!activeUserIds.contains(userId)) {
          print("✅ Adding user: $userId");
          activeUserIds.add(userId);
        }
      }
    }

    print("=====");
    print("Final list of active users who messaged: $activeUserIds");
    return activeUserIds;
  }

  void sendReply(String message) async {
    if (selectedUserId == null) return;

    // Add message to /message_list subcollection
    await FirebaseFirestore.instance
        .collection("kitchen_chats")
        .doc(kitchenId)
        .collection("messages")
        .doc(selectedUserId)
        .collection("kitchen_inbox")
        .add({
      "text": message,
      "senderId": kitchenId,
      "receiverId": selectedUserId,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  Future<void> deleteOldMessages() async {
    if (selectedUserId == null) return;

    final DateTime cutoffTime = DateTime.now().subtract(Duration(hours: 24));

    // Delete from user_inbox
    QuerySnapshot userOldMessages = await FirebaseFirestore.instance
        .collection("kitchen_chats")
        .doc(kitchenId)
        .collection("messages")
        .doc(selectedUserId)
        .collection("user_inbox")
        .where("timestamp", isLessThan: Timestamp.fromDate(cutoffTime))
        .get();

    for (var doc in userOldMessages.docs) {
      await doc.reference.delete();
    }

    // Delete from kitchen_inbox
    QuerySnapshot kitchenOldMessages = await FirebaseFirestore.instance
        .collection("kitchen_chats")
        .doc(kitchenId)
        .collection("messages")
        .doc(selectedUserId)
        .collection("kitchen_inbox")
        .where("timestamp", isLessThan: Timestamp.fromDate(cutoffTime))
        .get();

    for (var doc in kitchenOldMessages.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Customer Chats")),
      body: Column(
        children: [
          // Dropdown to select user
          FutureBuilder<List<String>>(
            future: fetchUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              }
              List<String> users = snapshot.data!;
              return Padding(
                padding: EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  hint: Text("Select a User"),
                  value: selectedUserId,
                  onChanged: (String? newValue) async {
                    setState(() {
                      selectedUserId = newValue;
                      cachedMessages = [];
                    });
                    await deleteOldMessages();
                    await loadKitchenMessages();
                  },
                  items: users.map<DropdownMenuItem<String>>((String user) {
                    return DropdownMenuItem<String>(
                      value: user,
                      child: Text("User: $user"),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // Messages section
          Expanded(
            child: selectedUserId == null
                ? Center(child: Text("Select a user to view messages."))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("kitchen_chats")
                  .doc(kitchenId)
                  .collection("messages")
                  .doc(selectedUserId)
                  .collection("user_inbox")
                  .where("timestamp", isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 24))))
                  .orderBy("timestamp", descending: false)
                  .snapshots(),
              builder: (context, userSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("kitchen_chats")
                      .doc(kitchenId)
                      .collection("messages")
                      .doc(selectedUserId)
                      .collection("kitchen_inbox")
                      .where("timestamp", isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 24))))
                      .orderBy("timestamp", descending: false)
                      .snapshots(),
                  builder: (context, kitchenSnapshot) {
                    if (!userSnapshot.hasData || !kitchenSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // Merge both inboxes
                    List<Map<String, dynamic>> allMessages = [
                      ...userSnapshot.data!.docs.map((doc) => {
                        "text": doc['text'],
                        "senderId": doc['senderId'],
                        "receiverId": doc['receiverId'],
                        "timestamp": doc['timestamp'],
                      }),
                      ...kitchenSnapshot.data!.docs.map((doc) => {
                        "text": doc['text'],
                        "senderId": doc['senderId'],
                        "receiverId": doc['receiverId'],
                        "timestamp": doc['timestamp'],
                      }),
                    ];

                    // Sort by timestamp
                    allMessages.sort((a, b) {
                      Timestamp t1 = a['timestamp'];
                      Timestamp t2 = b['timestamp'];
                      return t1.compareTo(t2);
                    });

                    // Save merged messages to cache
                    saveKitchenMessages(allMessages);

                    return ListView(
                      reverse: false,
                      children: allMessages.map((msg) {
                        bool isSentByKitchen = msg['senderId'] == kitchenId;
                        return Align(
                          alignment: isSentByKitchen
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSentByKitchen
                                  ? Colors.orange[200]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: isSentByKitchen
                                    ? Radius.circular(10)
                                    : Radius.circular(0),
                                bottomRight: isSentByKitchen
                                    ? Radius.circular(0)
                                    : Radius.circular(10),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['text'],
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  msg['timestamp'] != null
                                      ? (msg['timestamp'] as Timestamp)
                                      .toDate()
                                      .toString()
                                      .substring(11, 16)
                                      : "Sending...",
                                  style:
                                  TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),

          // Message input field
          if (selectedUserId != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.orange),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        sendReply(_controller.text);
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
