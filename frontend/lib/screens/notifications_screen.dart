import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final res = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/notifications/"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        notifications = data["notifications"];
        isLoading = false;
      });
      // mark all as read
      await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/notifications/read/"),
        headers: {"Authorization": "Bearer $token"},
      );
    } else {
      setState(() => isLoading = false);
    }
  }

  IconData _iconForMessage(String msg) {
    if (msg.toLowerCase().contains("selected")) return Icons.celebration;
    if (msg.toLowerCase().contains("rejected")) return Icons.cancel_outlined;
    if (msg.toLowerCase().contains("shortlisted")) return Icons.stars;
    if (msg.toLowerCase().contains("interview")) return Icons.work;
    return Icons.notifications;
  }

  Color _colorForMessage(String msg) {
    if (msg.toLowerCase().contains("selected")) return Colors.green;
    if (msg.toLowerCase().contains("rejected")) return Colors.red;
    if (msg.toLowerCase().contains("shortlisted")) return Colors.orange;
    if (msg.toLowerCase().contains("interview")) return Colors.blue;
    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchNotifications,
              child: notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Center(
                          child: Text("No notifications yet",
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        final isUnread = !(n["is_read"] as bool);
                        final color = _colorForMessage(n["message"]);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUnread ? color.withOpacity(.06) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUnread ? color.withOpacity(.3) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconForMessage(n["message"]),
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n["message"],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isUnread
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        )),
                                    const SizedBox(height: 4),
                                    Text(
                                        n["created_at"].toString().substring(0, 10),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}


