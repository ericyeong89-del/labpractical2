import 'package:flutter/material.dart';
import '../services/checkin_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await CheckInService.getHistory();
    setState(() => history = data.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participation History'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: history.isEmpty 
        ? const Center(child: Text('No participation records found.'))
        : ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.event_available, color: Colors.indigo),
                  title: Text(item['fairName']),
                  subtitle: Text("${item['time']}\n${item['address']}"),
                  trailing: Text("+${item['points']} pts", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  isThreeLine: true,
                ),
              );
            },
          ),
    );
  }
}