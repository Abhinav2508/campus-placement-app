import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CompanyDetailScreen extends StatefulWidget {
  final int companyId;

  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {

  Map company = {};
  bool isLoading = true;
  bool isApplying = false;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    fetchCompany();
    _checkSaved();
  }

  Future<void> fetchCompany() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    var url = Uri.parse("${AppConfig.baseUrl}/api/company/${widget.companyId}/");

    var response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    });

    if (response.statusCode == 200) {
      setState(() {
        company = jsonDecode(response.body);
        isLoading = false;
      });
    }
  }

  Future<void> _checkSaved() async {
    // we detect saved status via the saved API list
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final res = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/saved/"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      setState(() {
        isSaved = list.any((c) => c["id"] == widget.companyId);
      });
    }
  }

  Future<void> _toggleSave() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/save/${widget.companyId}/"),
      headers: {"Authorization": "Bearer $token"},
    );
    setState(() => isSaved = !isSaved);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSaved ? "Job saved!" : "Job unsaved")),
      );
    }
  }

  Future<void> applyCompany() async {
    setState(() => isApplying = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    var url = Uri.parse("${AppConfig.baseUrl}/api/apply/${widget.companyId}/");

    var response = await http.post(url, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    });

    var msg = jsonDecode(response.body)["message"];

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    await fetchCompany();
    setState(() => isApplying = false);
  }

  Widget infoCard({required IconData icon, required String title, required String value}) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildSkillChips(String skills) {
    List list = skills.split(",");

    return Wrap(
      spacing: 8,
      children: list.map((skill) {
        return Chip(
          label: Text(skill.trim()),
          backgroundColor: Colors.blue.shade50,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool eligible = company["is_eligible"];
    bool applied = company["is_applied"];

    String logoUrl = company["logo_url"] ?? "";
    String jobType = company["job_type"] ?? "Full-Time";
    String workMode = company["work_mode"] ?? "On-Site";
    String experience = company["experience"] ?? "Fresher";
    String aboutCompany = company["about_company"] ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // PREMIUM HERO HEADER
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: _toggleSave,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff2b5876), Color(0xff4e4376)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 76, height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: logoUrl.isNotEmpty 
                          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.business, color: Colors.indigo, size: 36)))) 
                          : Center(
                              child: Text(
                                company["name"][0],
                                style: const TextStyle(fontSize: 32, color: Color(0xff2b5876), fontWeight: FontWeight.bold),
                              ),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        company["name"],
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // PAGE CONTENTS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // ROLE
                  Text(company["role"], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(jobType, style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(workMode, style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(experience, style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // CARDS
                  Row(
                    children: [
                      Expanded(child: infoCard(icon: Icons.currency_rupee, title: "Package", value: company["package"])),
                      const SizedBox(width: 10),
                      Expanded(child: infoCard(icon: Icons.location_on, title: "Location", value: company["location"])),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ELIGIBILITY BADGE
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: eligible ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(eligible ? Icons.check_circle : Icons.cancel, color: eligible ? Colors.green : Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            eligible ? "You are eligible to apply!" : company["eligibility_reason"],
                            style: TextStyle(color: eligible ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SKILLS
                  const Text("Required Skills", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  buildSkillChips(company["required_skills"]),
                  
                  const SizedBox(height: 24),

                  // DESCRIPTION
                  const Text("Job Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(company["description"], style: const TextStyle(height: 1.5, fontSize: 15, color: Colors.black87)),

                  if (aboutCompany.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text("About the Company", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(aboutCompany, style: const TextStyle(height: 1.5, fontSize: 15, color: Colors.black87)),
                  ],

                  const SizedBox(height: 40),

                  // APPLY BUTTON
                  if (applied)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade200)
                      ),
                      child: const Center(
                        child: Text("✓ Already Applied", style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: eligible && !isApplying ? applyCompany : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300
                        ),
                        child: isApplying 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(eligible ? "Apply Now" : "Not Eligible", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

