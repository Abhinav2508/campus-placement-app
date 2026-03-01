import 'package:flutter/material.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import 'companies_screen.dart';
import 'my_applications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late Future<DashboardModel> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = DashboardService.getDashboard();
  }

  // ================= STATUS COLOR =================
  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "shortlisted":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),

      body: FutureBuilder<DashboardModel>(
        future: dashboardFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Failed to load dashboard"));
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                dashboardFuture = DashboardService.getDashboard();
              });
            },

            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ================= GREETING =================
                Text("Good morning,",
                    style: TextStyle(color: Colors.grey.shade600)),
                Text(data.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),

                // ================= STATS CARDS =================
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.4,
                  children: [

                    statCard(Icons.apartment, data.eligibleCompanies.toString(), "Eligible Companies"),
                    statCard(Icons.description, data.applied.toString(), "Applied"),
                    statCard(Icons.event, data.upcoming.toString(), "Upcoming Drives"),
                    statCard(Icons.school, data.cgpa.toString(), "CGPA"),

                  ],
                ),

                const SizedBox(height: 24),

                // ================= QUICK ACTIONS =================
                const Text("QUICK ACTIONS",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),

                actionTile(
                  "View Companies",
                  "Browse & apply to open positions",
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CompaniesScreen())),
                ),

                actionTile(
                  "My Applications",
                  "Track your application status",
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MyApplicationsScreen())),
                ),

                const SizedBox(height: 24),

                // ================= RECENT ACTIVITY =================
                const Text("RECENT ACTIVITY",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),

                ...data.recentActivity.map((activity) => activityCard(activity)),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= STAT CARD =================
  Widget statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ================= ACTION TILE =================
  Widget actionTile(String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8)],
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // ================= ACTIVITY CARD =================
  Widget activityCard(Activity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(activity.company[0])),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.company,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(activity.role, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor(activity.status).withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              activity.status,
              style: TextStyle(color: statusColor(activity.status)),
            ),
          )
        ],
      ),
    );
  }
}