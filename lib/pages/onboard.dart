import 'package:flutter/material.dart';
import 'package:foodapp/pages/signup.dart';
import 'package:foodapp/widget/content_model.dart';
import 'package:foodapp/widget/widget_support.dart';

class Onboard extends StatefulWidget {
  const Onboard({super.key});

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  int currentIndex = 0;
  late PageController _controller;

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen height and width
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: contents.length,
              onPageChanged: (int index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (_, i) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.1,  // 10% of screen height for top padding
                    left: screenWidth * 0.05, // 5% of screen width for left padding
                    right: screenWidth * 0.05, // 5% of screen width for right padding
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        contents[i].image,
                        height: screenHeight * 0.45, // 45% of screen height for image
                        width: screenWidth,
                        fit: BoxFit.fill,
                      ),
                      SizedBox(height: screenHeight * 0.05), // 5% of screen height for spacing
                      Text(
                        contents[i].title,
                        style: AppWidget.HeaderLineTextFieldStyle(),
                      ),
                      SizedBox(height: screenHeight * 0.02), // 2% of screen height for spacing
                      Text(
                        contents[i].description,
                        style: AppWidget.LightTextFieldStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Dot Indicators
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                contents.length,
                    (index) => buildDot(index, context),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (currentIndex == contents.length - 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignUp()),
                );
              } else {
                _controller.nextPage(
                  duration: Duration(milliseconds: 100),
                  curve: Curves.bounceIn,
                );
              }
            },
            child: Container(
              height: screenHeight * 0.08, // 8% of screen height for button height
              margin: EdgeInsets.all(screenWidth * 0.1), // 10% of screen width for margin
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  currentIndex == contents.length - 1 ? "Start" : "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 10.0,
      width: currentIndex == index ? 18 : 7,
      margin: EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.black38,
      ),
    );
  }
}
