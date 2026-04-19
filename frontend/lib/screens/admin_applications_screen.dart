import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_service.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  List<dynamic> applications = [];
  bool isLoading = true;

  final List<String> statuses = ['applied', 'shortlisted', 'interview', 'selected', 'rejected'];

  @override
  void initState() {
    super.initState();
    _fetchApplications();
  }

  Future<void> _fetchApplications() async {
    try {
      final res = await AdminService.getApplications();
      setState(() {
        applications = res;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error fetching applications")));
      }
    }
  }

  void _updateStatus(int appId, String currentStatus) {
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Status"),
          content: DropdownButtonFormField<String>(
            value: selectedStatus,
            items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
            onChanged: (val) {
              selectedStatus = val!;
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await AdminService.updateApplicationStatus(appId, selectedStatus);
                if (success) {
                  _fetchApplications();
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update status")));
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No resume uploaded")));
      return;
    }
    String fullUrl = url.startsWith('http') ? url : "http://127.0.0.1:8000$url";
    final uri = Uri.parse(fullUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Could not open link")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (applications.isEmpty) return const Center(child: Text("No applications found"));

    return RefreshIndicator(
      onRefresh: _fetchApplications,
      child: ListView.builder(
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final app = applications[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${app['student_name']} (${app['student_roll']})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    tooltip: "View Resume",
                    onPressed: () => _launchURL(app['resume_url']),
                  ),
                ]
              ),
              subtitle: Text("Applied to: ${app['company_name']}\nDate: ${app['applied_at']}\nPhone: ${app['student_phone'] ?? 'N/A'}"),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(app['status'].toString().toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _updateStatus(app['id'], app['status']),
                    child: const Icon(Icons.edit, color: Colors.grey, size: 20),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
