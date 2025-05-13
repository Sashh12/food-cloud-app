import 'dart:io';

import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class KitchenStreamPage extends StatefulWidget {
  final String orderId; // Pass orderId from the previous screen
  KitchenStreamPage({required this.orderId});

  @override
  _KitchenStreamPageState createState() => _KitchenStreamPageState();
}

class _KitchenStreamPageState extends State<KitchenStreamPage> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isRecording = false;
  String? _videoUrl;
  late String orderId;

  @override
  void initState() {
    super.initState();
    orderId = widget.orderId; // Get the orderId passed to this page
    print("DEBUG: Order ID passed to KitchenStreamPage: $orderId");
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      print("DEBUG: Initializing cameras...");
      _cameras = await availableCameras();
      print("DEBUG: Available cameras: $_cameras");

      _cameraController = CameraController(
        _cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back),
        ResolutionPreset.medium,
      );
      await _cameraController?.initialize();
      print("DEBUG: Camera initialized successfully.");
      setState(() {});
    } catch (e) {
      print("ERROR: Failed to initialize camera: $e");
    }
  }

  Future<void> startRecording() async {
    if (_cameraController != null && !_isRecording) {
      try {
        print("DEBUG: Starting video recording...");
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecording = true;
        });
        print("DEBUG: Video recording started.");
      } catch (e) {
        print("ERROR: Failed to start video recording: $e");
      }
    }
  }

  Future<void> stopRecording() async {
    if (_cameraController != null && _isRecording) {
      try {
        print("DEBUG: Stopping video recording...");
        XFile videoFile = await _cameraController!.stopVideoRecording();
        setState(() {
          _isRecording = false;
        });
        print("DEBUG: Video recording stopped.");
        uploadVideo(videoFile);
      } catch (e) {
        print("ERROR: Failed to stop video recording: $e");
      }
    }
  }

  Future<void> uploadVideo(XFile videoFile) async {
    // Get the food name from the 'Orders' collection using the orderId
    try {
      print("DEBUG: Fetching order details for orderId: $orderId");
      final orderSnapshot = await FirebaseFirestore.instance.collection('Orders').doc(orderId).get();

      if (orderSnapshot.exists) {
        final foodName = orderSnapshot.data()?['foodName'] ?? 'Unknown Food';
        print("DEBUG: Found food name: $foodName");

        // Upload the video to Firebase Storage with the orderId and foodName as part of the path
        final storageRef = FirebaseStorage.instance.ref('kitchen_videos/$orderId/${foodName}_${DateTime.now().millisecondsSinceEpoch}.mp4');
        print("DEBUG: Uploading video to Firebase Storage: ${storageRef.fullPath}");

        await storageRef.putFile(File(videoFile.path));
        final downloadUrl = await storageRef.getDownloadURL();
        print("DEBUG: Video uploaded, download URL: $downloadUrl");

        // Update the video URL in the specific order document
        await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({
          'videoUrl': downloadUrl,
          'videoUploadedAt': FieldValue.serverTimestamp(),
        });
        print("DEBUG: Order $orderId updated with video URL.");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video uploaded to order: $foodName')),
        );
      } else {
        print("ERROR: Order not found for orderId: $orderId");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order not found')),
        );
      }
    } catch (e) {
      print("ERROR: Failed to upload video: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record Video for Order')),
      body: _cameraController != null && _cameraController!.value.isInitialized
          ? Column(
        children: [
          AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
          ElevatedButton(
            onPressed: _isRecording ? stopRecording : startRecording,
            child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}