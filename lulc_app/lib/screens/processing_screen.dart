import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/result_model.dart';

class ProcessingScreen extends StatefulWidget {
  final File imageFile;

  const ProcessingScreen({super.key, required this.imageFile});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {

  @override
  void initState() {
    super.initState();
    process();
  }

  void process() async {
    try {
      final apiResult = await ApiService.classifyImage(widget.imageFile.path);
      if (!mounted) return;

      if (apiResult['success'] == true) {
        final result = ResultModel.fromJson(apiResult);
        Navigator.pop(context, result);
      } else {
        _showError(apiResult['message'] ?? 'Classification failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    Navigator.pop(context, null);
    // Error will surface in UploadScreen since result will be null
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}