import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/service/SharedPreferenceService.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';


class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  bool isChatWithKitchen = false;
  String? kitchenname;
  bool isAIChat = false;
  List<Map<String, dynamic>> kitchens = [];
  String? selectedKitchenId;
  StreamSubscription? _kitchenInboxListener;
  DateTime? lastFetchedKitchenMessageTime;
  ChatMode? _chatMode;
  final apiKey="AIzaSyCbn_31wQuomnBVQTVN9-HCZxX0cJxVObk";

  @override
  void initState() {
    super.initState();
    _loadChatMode(); // Load chat mode
    SharedPreferenceService.loadMessagesForUser (userId).then((cachedMsgs) {
      setState(() {
        if (cachedMsgs.isNotEmpty) {
          messages = cachedMsgs;
        } else {
          showChatOptions();
        }
      });
    });
  }

  @override
  void dispose() {
    _kitchenInboxListener?.cancel();
    super.dispose();
  }

  void _loadChatMode() async {
    ChatMode? mode = await SharedPreferenceService.loadChatMode();
    setState(() {
      _chatMode = mode;
    });
  }

  void showChatOptions() {
    setState(() {
      messages.add({"text": "Choose an option:", "isUser": false, "isOption": true});
    });
  }

  void handleOptionSelect(String option) async {
    print("🔹 Option selected: $option");

    setState(() {
      messages.add({"text": option, "isUser": true});
    });

    if (option == "Order Status") {
      print("🔹 Switching to Order Status mode...");
      if (_chatMode == ChatMode.orderstatus) {
        print("✅ Already in Order Status mode. No change.");
        return;
      }
      await SharedPreferenceService.saveChatMode(ChatMode.orderstatus);
      setState(() {
        _chatMode = ChatMode.orderstatus;
      });
      resetChatModes();
      print("✅ Fetching order status...");
      fetchOrderDetails();
    } else if (option == "Chat with Kitchen") {
      print("🔹 Switching to Kitchen Chat mode...");
      if (isChatWithKitchen && selectedKitchenId != null) {
        print("✅ Already in kitchen chat. No change.");
        return;
      }

      resetChatModes();
      await SharedPreferenceService.saveChatMode(ChatMode.kitchen);
      setState(() {
        _chatMode = ChatMode.kitchen;
        isChatWithKitchen = true;
      });

      if (selectedKitchenId != null) {
        print("✅ Kitchen selected. Listening to messages...");
        listenToKitchenMessages();
      } else {
        print("🔹 Fetching available kitchens...");
        fetchKitchens().then((_) {
          if (kitchens.isNotEmpty) {
            print("✅ Kitchens available. Showing selection dialog.");
            showKitchenSelectionDialog(context);
          } else {
            print("⚠️ No kitchens available.");
            setState(() {
              messages.add({"text": "No kitchens available.", "isUser": false});
            });
          }
        });
      }
    } else if (option == "AI Chatbot") {
      print("🔹 Switching to AI Chatbot mode...");

      if (_chatMode == ChatMode.bot) {
        print("✅ Already in AI Chatbot mode. No change.");
        return;
      }

      resetChatModes();
      await SharedPreferenceService.saveChatMode(ChatMode.bot);

      setState(() {
        _chatMode = ChatMode.bot;
        isAIChat = true;
      });

      print("✅ AI Chat mode activated.");
      messages.add({"text": "Ask me anything!", "isUser": false});
    }
  }

  Future<void> sendMessage(String message) async {
    DateTime now = DateTime.now();
    print("🔹 Sending message: $message");

    // Add the user's message to the chat
    setState(() {
      messages.add({
        "text": message,
        "isUser ": true,
        "timestamp": now, // Store the timestamp
      });
    });

    // Check if the chat is with the kitchen
    if (isChatWithKitchen) {
      print("🔹 Checking kitchen chat setup...");
      if (selectedKitchenId == null) {
        print("⚠️ No kitchen selected. Fetching kitchens...");
        await fetchKitchens();
        showKitchenSelectionDialog(context);
      } else {
        print("✅ Saving message to kitchen chat...");
        await SharedPreferenceService.saveMessagesForUser (
          selectedKitchenId!,
          userId,
          messages,
          lastFetchedKitchenMessageTime,
        );
        await sendKitchenMessage(message); // Ensure this is awaited
      }
    }
    // Handle AI chat mode
    else if (_chatMode == ChatMode.bot) {
      print("🔹 AI chat mode detected. Fetching AI response...");

      try {
        String response = await getAIResponse(message);
        print("✅ AI response received: $response");

        // Add the AI's response to the chat
        setState(() {
          messages.add({
            "text": response,
            "isUser ": false,
            "timestamp": DateTime.now(), // Add timestamp for AI response
          });
        });

        print("✅ Saving AI chat...");
        await SharedPreferenceService.saveMessagesForUser (
          "bot",
          userId,
          messages,
          DateTime.now(),
        );
      } catch (e) {
        print("❌ Error fetching AI response: $e");
        // Optionally, you can add a message to the chat indicating an error
        setState(() {
          messages.add({
            "text": "Error fetching AI response.",
            "isUser ": false,
            "timestamp": DateTime.now(),
          });
        });
      }
    } else {
      print("🔹 Saving message for Order Status chat...");
      await SharedPreferenceService.saveMessagesForUser (
        "orderstatus",
        userId,
        messages,
        DateTime.now(),
      );
    }
  }

  Future<String> getAIResponse(String message) async {
    print("🔹 Sending request to Gemini AI: $message");

    const String apiKey = "AIzaSyCbn_31wQuomnBVQTVN9-HCZxX0cJxVObk"; // Secure this key
    final model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: apiKey);

    final content = Content.text(message);

    try {
      final response = await model.generateContent([content]);
      print("✅ Response from Gemini AI: ${response.text}");
      return response.text ?? "No response";
    } catch (e) {
      print("❌ Error fetching AI response: $e");
      return "Error in AI response";
    }
  }

  void resetChatModes() {
    isChatWithKitchen = false;
    isAIChat = false;
    selectedKitchenId = null;
    _kitchenInboxListener?.cancel();
    lastFetchedKitchenMessageTime = null;
  }

  // Future<void> fetchOrderStatus() async {
  //
  //   var orders = await FirebaseFirestore.instance
  //       .collection("Orders")
  //       .where("userId", isEqualTo: userId)
  //       .orderBy("orderDate", descending: true)
  //       .limit(1)
  //       .get();
  //
  //   if (orders.docs.isNotEmpty) {
  //     String status = orders.docs.first.get("KitchenorderStatus");
  //     setState(() {
  //       messages.add({"text": "Your latest order status: $status", "isUser": false});
  //     });
  //   } else {
  //     setState(() {
  //       messages.add({"text": "No recent orders found.", "isUser": false});
  //     });
  //   }
  // }
  Future<void> fetchOrderDetails() async {
    var orders = await FirebaseFirestore.instance
        .collection("Orders")
        .where("userId", isEqualTo: userId)
        .orderBy("orderDate", descending: true)
        .limit(1)
        .get();

    if (orders.docs.isNotEmpty) {
      var order = orders.docs.first;
      String status = order.get("KitchenorderStatus");
      String foodName = order.get("items")[0]["Name"];
      String foodCategory = order.get("items")[0]["FoodCategory"];
      String imageUrl = order.get("items")[0]["Image"];
      int totalAmount = order.get("totalAmount");
      Timestamp orderTimestamp = order.get("orderDate");
      DateTime orderDate = orderTimestamp.toDate();

      setState(() {
        messages.add({
          "text": "Your latest order details:\n\n"
              "📝 Status: $status\n"
              "🍽️ Food: $foodName\n"
              "📂 Category: $foodCategory\n"
              "💰 Total: ₹$totalAmount\n"
              "📅 Date: ${orderDate.toLocal()}",
          "image": imageUrl,
          "status": status, // Added these keys to match UI
          "foodName": foodName,
          "foodCategory": foodCategory,
          "totalAmount": totalAmount,
          "orderDate": orderDate,
          "isUser": false,
        });
      });
    } else {
      setState(() {
        messages.add({"text": "No recent orders found.", "isUser": false});
      });
    }
  }



  Future<void> fetchKitchens() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance.collection("kitchens").get();
      setState(() {
        kitchens = querySnapshot.docs
            .map((doc) => {"id": doc.id, "name": doc.get("kitchenname")})
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching kitchens: $e");
    }
  }

  void showKitchenSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Kitchen"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: kitchens.map((kitchen) {
              return ListTile(
                title: Text(kitchen["name"]),
                onTap: () {
                  setState(() {
                    selectedKitchenId = kitchen["id"];
                    messages.add({"text": "You are now chatting with ${kitchen["name"]}.", "isUser": false});
                  });
                  Navigator.pop(context);
                  listenToKitchenMessages(); // Listen for kitchen replies
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> sendKitchenMessage(String message) async {
    if (selectedKitchenId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("kitchen_chats")
          .doc(selectedKitchenId)
          .collection("messages")
          .doc(userId)
          .collection("user_inbox")
          .add({
        "text": message,
        "senderId": userId,
        "receiverId": selectedKitchenId,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> deleteOldKitchenInboxMessages() async {
    if (selectedKitchenId == null) return;

    try {
      final oldMessages = await FirebaseFirestore.instance
          .collection("kitchen_chats")
          .doc(selectedKitchenId)
          .collection("messages")
          .doc(userId)
          .collection("kitchen_inbox")
          .where(
        "timestamp",
        isLessThan: Timestamp.fromDate(
          DateTime.now().subtract(Duration(minutes: 2)),
        ),
      )
          .get();

      for (var doc in oldMessages.docs) {
        await doc.reference.delete();
      }

      debugPrint("Old kitchen_inbox messages deleted for user $userId ✅");
    } catch (e) {
      debugPrint("Error deleting old kitchen inbox messages: $e");
    }
  }

  void listenToKitchenMessages() async {
    if (selectedKitchenId != null) {
      await deleteOldKitchenInboxMessages(); // keep this

      Query query = FirebaseFirestore.instance
          .collection("kitchen_chats")
          .doc(selectedKitchenId)
          .collection("messages")
          .doc(userId)
          .collection("kitchen_inbox")
          .orderBy("timestamp", descending: false);

      // Now this will correctly filter out old messages:
      if (lastFetchedKitchenMessageTime != null) {
        query = query.where("timestamp", isGreaterThan: lastFetchedKitchenMessageTime);
      }

      _kitchenInboxListener?.cancel();
      _kitchenInboxListener = query.snapshots().listen((messageSnapshot) {
        for (var msgDoc in messageSnapshot.docChanges) {
          if (msgDoc.type == DocumentChangeType.added) {
            Map<String, dynamic> newMessage = {
              "text": msgDoc.doc.get("text"),
              "isUser ": false,
            };
            Timestamp msgTimestamp = msgDoc.doc.get("timestamp");

            if (lastFetchedKitchenMessageTime == null ||
                msgTimestamp.toDate().isAfter(lastFetchedKitchenMessageTime!)) {
              lastFetchedKitchenMessageTime = msgTimestamp.toDate();
            }

            setState(() {
              messages.add(newMessage);
            });

            // Save updated messages + latest time!
            SharedPreferenceService.saveMessagesForUser (
                selectedKitchenId!, userId, messages, lastFetchedKitchenMessageTime);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with Kitchen")),
      body: Column(
        children: [
          // Display current chat mode
          if (_chatMode != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Current Mode: ${_chatMode!.name}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];

                if (msg == null || msg["text"] == null) {
                  debugPrint("⚠️ Warning: Null or invalid message at index $index: $msg");
                  return SizedBox.shrink();
                }

                if (msg["isLoading"] == true) {
                  return Center(child: CircularProgressIndicator());
                }

                if (msg["isOption"] == true) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        msg["text"] ?? "Choose an option:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(onPressed: () => handleOptionSelect("Order Status"),child: Text("Order Status"),),
                      ElevatedButton(onPressed: () => handleOptionSelect("Chat with Kitchen"),child: Text("Chat with Kitchen"),),
                      ElevatedButton(onPressed: () => handleOptionSelect("AI Chatbot"),child: Text("AI Chatbot"),),
                    ],
                  );
                }

                // Special UI for Order Status
                if (_chatMode == ChatMode.orderstatus && msg.containsKey("image")) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📦 Order Details",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            msg["image"],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text("📝 Status: ${msg["status"]}", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("🍽️ Food: ${msg["foodName"]}"),
                        Text("📂 Category: ${msg["foodCategory"]}"),
                        Text("💰 Total: ₹${msg["totalAmount"]}"),
                        Text("📅 Date: ${msg["orderDate"] != null ? DateFormat('dd MMM yyyy, hh:mm a').format(msg["orderDate"]) : "Date not available"}",
                          style: TextStyle(fontWeight: FontWeight.bold),),
                      ],
                    ),
                  );
                }

                return Align(
                  alignment: msg["isUser"] == true ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: msg["isUser"] == true ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: msg["isUser  "] == true ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(msg["text"] ?? "No message found"),
                        SizedBox(height: 5), // Add some space between message and timestamp
                        if (msg["timestamp"] != null) // Check if timestamp is not null
                          Text(
                            DateFormat('hh:mm a').format(msg["timestamp"]), // Format the timestamp
                            style: TextStyle(fontSize: 10, color: Colors.black54), // Style the timestamp
                          )
                        else
                          SizedBox.shrink(), // Or handle the null case as needed
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      sendMessage(_controller.text);
                      _controller.clear();
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

