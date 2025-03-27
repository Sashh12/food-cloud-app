import 'package:flutter/cupertino.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool isListening = false;
  String recognizedText = "";

  Future<void> initSpeech() async {
    bool available = await _speech.initialize(
      onError: (error) {
        print("Speech recognition error: $error");
      },
      onStatus: (status) {
        print("Speech recognition status: $status");
      },
    );

    if (available) {
      print("✅ Speech recognition initialized successfully.");
    } else {
      print("❌ Speech recognition NOT available.");
    }
  }

  Future<void> startListening(
      Function(String) onResult,
      BuildContext context,
      Function(BuildContext) showListeningDialog) async {

    bool available = await _speech.initialize();
    if (!available) {
      print("❌ Speech recognition not available");
      return;
    }

    showListeningDialog(context); // ✅ Show listening dialog before starting

    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;

        if (recognizedText.isNotEmpty) {
          _speech.stop(); // ✅ Stop listening once text is captured
          onResult(recognizedText); // ✅ Pass recognized text for filtering
        }
      },
    );

    isListening = true;
  }



  void stopListening(BuildContext context, Function(BuildContext, bool) showListeningDialog) {
    _speech.stop();
    isListening = false;

    // Update dialog to show checkmark
    showListeningDialog(context, false);

    // Close the dialog after 1 second
    Future.delayed(Duration(seconds: 1), () {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  // Future<void> startListening(
  //     Function(String) onResult,
  //     BuildContext context,
  //     Function(BuildContext, bool) showListeningDialog) async {
  //   try {
  //     bool available = await _speech.initialize(
  //       onStatus: (status) {
  //         if (status == "done") {
  //           stopListening(context, showListeningDialog);
  //         }
  //       },
  //     );
  //
  //     if (!available) {
  //       print("❌ Speech recognition not available");
  //       return;
  //     }
  //
  //     showListeningDialog(context, true);
  //
  //     await _speech.listen(
  //       onResult: (result) {
  //         recognizedText = result.recognizedWords;
  //         onResult(recognizedText);
  //       },
  //     );
  //
  //     isListening = true;
  //   } catch (e) {
  //     print("🔥 Error in startListening: $e");
  //   }
  // }
  //
  //
  // void stopListening(BuildContext context, Function(bool) showListeningDialog) {
  //   _speech.stop();
  //   isListening = false;
  //
  //   // Update dialog to show checkmark
  //   showListeningDialog(false);
  //
  //   // Close the dialog after a delay
  //   Future.delayed(Duration(seconds: 1), () {
  //     Navigator.pop(context); // Close the dialog
  //   });
  // }
}

  class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> searchFoodItems(String query) async {
    if (query.isEmpty) return [];

    List<Map<String, dynamic>> results = [];

    QuerySnapshot kitchenSnapshot = await _firestore.collection('kitchens').get();

    if (kitchenSnapshot.docs.isEmpty) {
      print("No kitchens found.");
      return [];
    }

    for (var kitchenDoc in kitchenSnapshot.docs) {
      String kitchenName = kitchenDoc["kitchenname"];
      if (kitchenName != null && kitchenName.isNotEmpty) {
        QuerySnapshot categorySnapshot = await _firestore
            .collection('fooditem')
            .doc(kitchenName)
            .collection('categories')
            .get();

        for (var categoryDoc in categorySnapshot.docs) {
          String categoryName = categoryDoc.id;

          QuerySnapshot snapshot = await _firestore
              .collection('fooditem')
              .doc(kitchenName)
              .collection('categories')
              .doc(categoryName)
              .collection('Items')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: query + 'z')
              .get();

          for (var doc in snapshot.docs) {
            results.add(doc.data() as Map<String, dynamic>);
          }
        }
      }
    }

    return results;
  }

  // New method to filter products based on the search query
  static List<Map<String, dynamic>> filterProducts(List<Map<String, dynamic>> products, String query) {
    if (query.isEmpty) return products;

    return products.where((product) {
      String name = product['Name']?.toLowerCase() ?? '';
      return name.contains(query.toLowerCase());
    }).toList();
  }
}
