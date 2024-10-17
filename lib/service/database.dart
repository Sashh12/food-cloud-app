import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseMethods{
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

  // Future<Stream<List<QuerySnapshot>>> getFoodItems(List<String> names) async {
  //   List<Stream<QuerySnapshot>> streams = names.map((name) {
  //     return FirebaseFirestore.instance.collection(name).snapshots();
  //   }).toList();

    // Use Rx.combineLatest with the correct generic types
  //   return Rx.combineLatest(streams, (List<QuerySnapshot> snapshots) {
  //     return snapshots;
  //   });
  // }

  Future addFoodtoCart(String id, Map<String, dynamic>  userInfoMap)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).collection("Cart").add(userInfoMap);
  }

  Future<Stream<QuerySnapshot>> getFoodCart(String id)async{
    return await FirebaseFirestore.instance.collection("users").doc(id).collection("Cart").snapshots();
  }

  Future addCloudKitchenDetail(String id, Map<String, dynamic> userInfoMap) async {
    return await FirebaseFirestore.instance.collection("kitchens").doc(id).set(userInfoMap);
  }

  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    List<Map<String, dynamic>> allProducts = [];

    try {
      // Fetch all categories
      var categorySnapshot = await FirebaseFirestore.instance.collection('categories').get();

      for (var categoryDoc in categorySnapshot.docs) {
        String categoryName = categoryDoc['name'];

        // Fetch products from the corresponding category collection
        var productSnapshot = await FirebaseFirestore.instance.collection(categoryName).get();

        for (var productDoc in productSnapshot.docs) {
          // Add each product to the list
          allProducts.add({
            'Category': categoryName,
            'Product': productDoc.data(),
          });
        }
      }
    } catch (e) {
      print("Error while fetching products: $e");
    }

    return allProducts;
  }


}

