import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/result_model.dart';

class PreviousWorkScreen extends StatefulWidget {
  const PreviousWorkScreen({super.key});

  @override
  State<PreviousWorkScreen> createState() => _PreviousWorkScreenState();
}

class _PreviousWorkScreenState extends State<PreviousWorkScreen> {
  List<ResultModel> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    try {
      final data = await ApiService.getPreviousResults();
      if (!mounted) return;
      setState(() {
        _results = data.map((e) => ResultModel.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load history. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        return ListTile(
          title: Text(_results[i].label),
        );
      },
    );
  }
}