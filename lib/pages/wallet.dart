import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:foodapp/service/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodapp/widget/app_constant.dart';
import 'package:foodapp/widget/widget_support.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? wallet, userId;
  TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserWalletData();
  }

  Future<void> getUserWalletData() async {
    User? user = FirebaseAuth.instance.currentUser; // Get current user
    if (user != null) {
      userId = user.uid; // Set user ID dynamically
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      setState(() {
        wallet = userDoc['Wallet'];
      });
    }
  }

  Map<String, dynamic>? paymentIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: wallet == null? Center(child: CircularProgressIndicator()): Container(
        margin: EdgeInsets.only(top: 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
                elevation: 5.0,
                child: Container(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Center(
                        child: Text("Wallet", style: AppWidget.HeaderLineTextFieldStyle())))),
            SizedBox(height: 30.0),
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(color: Color(0xFFF2f2f2)),
              child: Row(children: [
                Image.asset("images/wallet.png", height: 60, width: 60, fit: BoxFit.cover),
                SizedBox(width: 40.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your Wallet", style: AppWidget.LightTextFieldStyle()),
                    SizedBox(height: 5.0),
                    Text("\₹" + " " + wallet!, style: AppWidget.BoldTextFieldStyle()),
                  ],
                )
              ]),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text("Add Money", style: AppWidget.SemiBoldFieldStyle()),
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var amount in ['100', '500', '1000', '2000'])
                  GestureDetector(
                    onTap: () {
                      makePayment(amount);
                    },
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(border: Border.all(color: Color(0xFFd9d9d9)), borderRadius: BorderRadius.circular(10)),
                      child: Text("\₹" + " " + amount, style: AppWidget.SemiBoldFieldStyle()),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 50.0),
            GestureDetector(
              onTap: () {
                openEdit();
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 40.0),
                padding: EdgeInsets.symmetric(vertical: 12.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Color(0xFF008080), borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text("Add Money", style: TextStyle(color: Colors.white, fontSize: 16.0, fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  bool isAmountValid(String amount) {
    double conversionRate = 83.0; // Example conversion rate (1 USD = 83 INR). Update this dynamically if necessary.
    double enteredAmountInUSD = int.parse(amount) / conversionRate;
    return enteredAmountInUSD >= 0.50; // Ensure it's at least $0.50
  }

  Future<void> makePayment(String amount) async {
    if (!isAmountValid(amount)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Text("Amount must be ₹42 or more."),
        ),
      );
      return;
    }

    try {
      paymentIntent = await createPaymentIntent(amount, 'INR');
      await Stripe.instance.initPaymentSheet(paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'],
          style: ThemeMode.dark,
          merchantDisplayName: 'CloudEatz')).then((value) {});

      displayPaymentSheet(amount);
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  displayPaymentSheet(String amount) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) async {
        int newBalance = int.parse(wallet!) + int.parse(amount);
        await DatabaseMethods().UpdateUserwallet(userId!, newBalance.toString());

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [Icon(Icons.check_circle, color: Colors.green), Text("Payment Successful")]),
              ],
            ),
          ),
        );

        await getUserWalletData(); // Refresh wallet data
        paymentIntent = null;
      }).onError((error, stackTrace) {
        print('Error is: ---> $error $stackTrace');
      });
    } on StripeException catch (e) {
      print('Error is:---> $e ');
      showDialog(context: context, builder: (_) => const AlertDialog(content: Text("Cancelled")));
    } catch (e) {
      print('$e');
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card',
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretkey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      print('Payment Intent Body->>> ${response.body.toString()}');
      return jsonDecode(response.body);
    } catch (err) {
      print('err charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final calculatedAmount = (int.parse(amount)) * 100;
    return calculatedAmount.toString();
  }

  // Future<void> openEdit() => showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       content: SingleChildScrollView(
  //         child: Container(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(children: [
  //                 GestureDetector(
  //                     onTap: () {
  //                       Navigator.pop(context);
  //                     },
  //                     child: Icon(Icons.cancel)),
  //                 SizedBox(width: 60.0),
  //                 Center(
  //                   child: Text(
  //                     "Add Money",
  //                     style: TextStyle(color: Color(0xFF008080), fontWeight: FontWeight.bold),
  //                   ),
  //                 )
  //               ]),
  //               SizedBox(height: 20.0),
  //               Text("Amount"),
  //               SizedBox(height: 10.0),
  //               Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 10.0),
  //                 decoration: BoxDecoration(
  //                     border: Border.all(color: Colors.black38, width: 2.0),
  //                     borderRadius: BorderRadius.circular(10)),
  //                 child: TextField(
  //                   controller: amountController,
  //                   decoration: InputDecoration(border: InputBorder.none, hintText: 'Enter Amount'),
  //                 ),
  //               ),
  //               SizedBox(height: 20.0),
  //               Center(
  //                 child: GestureDetector(
  //                   onTap: () {
  //                     Navigator.pop(context);
  //                     makePayment(amountController.text);
  //                   },
  //                   child: Container(
  //                     width: 100,
  //                     padding: EdgeInsets.all(5),
  //                     decoration: BoxDecoration(color: Color(0xFF008080), borderRadius: BorderRadius.circular(10)),
  //                     child: Center(child: Text("Pay", style: TextStyle(color: Colors.white))),
  //                   ),
  //                 ),
  //               )
  //             ],
  //           ),
  //         ),
  //       ),
  //     ));
  Future<void> openEdit() {
    String? errorMessage;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.cancel)),
                    SizedBox(width: 60.0),
                    Center(
                      child: Text(
                        "Add Money",
                        style: TextStyle(color: Color(0xFF008080), fontWeight: FontWeight.bold),
                      ),
                    )
                  ]),
                  SizedBox(height: 20.0),
                  Text("Amount"),
                  SizedBox(height: 10.0),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black38, width: 2.0),
                        borderRadius: BorderRadius.circular(10)),
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter Amount',
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    SizedBox(height: 10),
                    Text(errorMessage!, style: TextStyle(color: Colors.red)),
                  ],
                  SizedBox(height: 20.0),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        final enteredAmount = int.tryParse(amountController.text);
                        if (enteredAmount == null || enteredAmount < 40) {
                          setState(() {
                            errorMessage = "Amount must be ₹40 or more.";
                          });
                          return;
                        }

                        Navigator.pop(context);
                        makePayment(amountController.text);
                      },
                      child: Container(
                        width: 100,
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Color(0xFF008080),
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                            child: Text("Pay",
                                style: TextStyle(color: Colors.white))),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
