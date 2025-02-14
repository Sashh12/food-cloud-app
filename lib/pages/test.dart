import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirestoreFetch extends StatefulWidget {
  @override
  _TestFirestoreFetchState createState() => _TestFirestoreFetchState();
}

class _TestFirestoreFetchState extends State<TestFirestoreFetch> {
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    testFirestoreFetch();
  }

  void testFirestoreFetch() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('fooditem').get();
      print("Number of documents in fooditem: ${snapshot.docs.length}");
    } catch (e) {
      print("Error fetching from Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Firestore Fetch')),
      body: Center(
        child: Text('Check console for output'),
      ),
    );
  }
}
