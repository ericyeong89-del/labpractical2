import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CheckInService {
  static const String historyKey = "checkin_history";
  static const String pointsKey = "total_points";

  static Future<void> addCheckIn(String fairName, int points, String address) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(historyKey) ?? [];
    String formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final newEntry = jsonEncode({
      "fairName": fairName,
      "points": points,
      "address": address,
      "time": formattedTime,
    });
    history.add(newEntry);
    await prefs.setStringList(historyKey, history);

    int currentTotal = prefs.getInt(pointsKey) ?? 0;
    await prefs.setInt(pointsKey, currentTotal + points);
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(historyKey) ?? [];
    return history.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  static Future<int> getTotalPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(pointsKey) ?? 0;
  }
}