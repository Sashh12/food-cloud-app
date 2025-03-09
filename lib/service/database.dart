import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:rxdart/rxdart.dart';

class DatabaseMethods{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future addUserDetail(String id, Map<String, dynamic>  userInfoMap)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).set(userInfoMap);
  }
  
  UpdateUserwallet(String id, String amount)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).update({"Wallet": amount});
  }

  Future addFoodItem(String name, Map<String, dynamic>  userInfoMap)async{
    return await FirebaseFirestore.instance.collection(name).add(userInfoMap);
  }

  Future placeOrder(String userId, int totalAmount, List<Map<String, dynamic>> items) async {
    String orderId = FirebaseFirestore.instance.collection("orders").doc().id;
    await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
      "userId": userId,
      "totalAmount": totalAmount,
      "orderDate": Timestamp.now(),
      "items": items,
    });
  }

  Future<Stream<QuerySnapshot>> getFoodItem(String name)async{
    return await FirebaseFirestore.instance.collection(name).snapshots();
  }

  Future addFoodtoCart(String id, Map<String, dynamic> userInfoMap) async {
    var cartRef = FirebaseFirestore.instance.collection("users").doc(id).collection("Cart");

    // Check if the item already exists in the cart
    var querySnapshot = await cartRef.where('Name', isEqualTo: userInfoMap['Name']).get();

    if (querySnapshot.docs.isNotEmpty) {
      var doc = querySnapshot.docs.first;
      int existingQuantity = int.parse(doc['Quantity']);
      int newQuantity = existingQuantity + int.parse(userInfoMap['Quantity']);

      // Calculate the new total price (price per item * new quantity)
      int pricePerItem = int.parse(doc['Total']) ~/ existingQuantity; // Get per-item price
      int newTotalPrice = pricePerItem * newQuantity;

      // Update the existing item with the new quantity and total price
      await doc.reference.update({
        'Quantity': newQuantity.toString(),
        'Total': newTotalPrice.toString(), // Update total price
      });
    } else {
      // Item does not exist, add it as a new item
      await cartRef.add(userInfoMap);
    }
  }

  Future<Stream<QuerySnapshot>> getFoodCart(String id)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).collection("Cart").snapshots();
  }

  Future addCloudKitchenDetail(String id, Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance.collection("kitchens").doc(id).set(userInfoMap);
  }




} //class ending




