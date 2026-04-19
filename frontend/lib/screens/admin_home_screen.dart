import 'package:flutter/material.dart';
import '../config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/admin_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool isLoading = true;
  Map<String, dynamic> data = {};
  Map<String, dynamic> analytics = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await AdminService.getDashboard();
      setState(() {
        data = res;
        isLoading = false;
      });
      _loadAnalytics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Error fetching admin stats")));
      }
    }
  }

  Future<void> _loadAnalytics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final res = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/admin/analytics/"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      setState(() => analytics = jsonDecode(res.body));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final int placed = analytics["placed"] ?? 0;
    final int notPlaced = analytics["not_placed"] ?? 0;
    final List companyApps = analytics["company_applications"] ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // STAT CARDS
          Row(
            children: [
              _buildStatCard("Students", data["total_students"].toString(),
                  Icons.people_outline, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard("Companies", data["total_companies"].toString(),
                  Icons.business_center, Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard("Applications", data["total_applications"].toString(),
                  Icons.assignment, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard("Placed", placed.toString(), Icons.verified, Colors.teal),
            ],
          ),

          const SizedBox(height: 24),

          // PIE CHART
          if (placed + notPlaced > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Placement Overview",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: placed.toDouble(),
                            title: "Placed\n$placed",
                            color: Colors.green,
                            radius: 70,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          PieChartSectionData(
                            value: notPlaced.toDouble(),
                            title: "Unplaced\n$notPlaced",
                            color: Colors.redAccent,
                            radius: 70,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // BAR CHART
          if (companyApps.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Applications per Company",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        barGroups: companyApps.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: (entry.value["count"] as int).toDouble(),
                                color: Colors.indigo,
                                width: 20,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < companyApps.length) {
                                  final name = companyApps[idx]["company"].toString();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                        name.length > 6
                                            ? "${name.substring(0, 5)}…"
                                            : name,
                                        style: const TextStyle(fontSize: 10)),
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) => Text(
                                  val.toInt().toString(),
                                  style: const TextStyle(fontSize: 10)),
                              reservedSize: 28,
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // RECENT ACTIVITY
          const Text("Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...(data["recent_activity"] as List).map((act) => Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text("${act['student']} → ${act['company']}"),
                  trailing: Chip(label: Text(act['status'])),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(count,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}


