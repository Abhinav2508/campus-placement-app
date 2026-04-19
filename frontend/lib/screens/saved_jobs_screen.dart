import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'company_detail_screen.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  List savedJobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSavedJobs();
  }

  Future<void> fetchSavedJobs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final res = await http.get(
      Uri.parse("http://127.0.0.1:8000/api/saved/"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      setState(() {
        savedJobs = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(
        title: const Text("Saved Jobs", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchSavedJobs,
              child: savedJobs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Center(
                          child: Text("No saved jobs yet",
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ),
                        Center(
                          child: Text("Bookmark jobs from the Companies tab",
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: savedJobs.length,
                      itemBuilder: (context, index) {
                        final job = savedJobs[index];
                        final logoUrl = job["logo_url"] ?? "";
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    CompanyDetailScreen(companyId: job["id"])),
                          ).then((_) => fetchSavedJobs()),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: logoUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(logoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => const Icon(
                                                  Icons.business,
                                                  color: Colors.grey)))
                                      : Center(
                                          child: Text(job["name"][0],
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.indigo))),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(job["role"],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(job["name"],
                                          style: TextStyle(
                                              color: Colors.grey.shade700, fontSize: 14)),
                                      Text(
                                          "${job["location"]} • ${job["package"]}",
                                          style: TextStyle(
                                              color: Colors.grey.shade500, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.bookmark, color: Colors.indigo.shade400),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
