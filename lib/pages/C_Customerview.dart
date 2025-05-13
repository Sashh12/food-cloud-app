import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomerViewPage extends StatefulWidget {
  final String orderId; // Pass the orderId from the previous screen

  CustomerViewPage({required this.orderId});

  @override
  _CustomerViewPageState createState() => _CustomerViewPageState();
}

class _CustomerViewPageState extends State<CustomerViewPage> {
  VideoPlayerController? _videoController;
  String? _videoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print("DEBUG: initState called. Fetching video...");
    fetchVideo(); // Fetch the video when the page is initialized
  }

  // Function to fetch video URL for the specific order
  Future<void> fetchVideo() async {
    try {
      print("DEBUG: Fetching video for orderId: ${widget.orderId}");
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(widget.orderId) // Fetch using orderId
          .get();

      if (orderSnapshot.exists) {
        print("DEBUG: Order found, checking videoUrl...");
        setState(() {
          _videoUrl = orderSnapshot.data()?['videoUrl']; // Get the video URL
          _isLoading = false; // Stop the loading indicator
        });

        if (_videoUrl != null) {
          print("DEBUG: Video URL found: $_videoUrl");
          _videoController = VideoPlayerController.network(_videoUrl!)
            ..initialize().then((_) {
              setState(() {});
              _videoController!.play(); // Play video when it's initialized
              print("DEBUG: Video started playing.");
            }).catchError((error) {
              print("ERROR: Video initialization failed - $error");
            });
        } else {
          print("DEBUG: No video URL found in the order.");
        }
      } else {
        print("DEBUG: No order found for orderId: ${widget.orderId}");
        setState(() {
          _isLoading = false; // Stop loading if no video found
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No video found for this order')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Stop loading in case of an error
      });
      print("ERROR: Failed to load video: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load video: $e')));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    print("DEBUG: VideoController disposed.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('View Order Video')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : _videoUrl != null
          ? Column(
        children: [
          // Display video player once video is loaded
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                    print("DEBUG: Video paused.");
                  } else {
                    _videoController!.play();
                    print("DEBUG: Video playing.");
                  }
                });
              },
              child: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 50,
              ),
            ),
          ),
        ],
      )
          : Center(child: Text('No video available for this order')),
    );
  }
}
