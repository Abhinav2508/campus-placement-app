import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    fetchCompany();
  }

  Future<void> fetchCompany() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    var url = Uri.parse("http://127.0.0.1:8000/api/company/${widget.companyId}/");

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

  Future<void> applyCompany() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    var url = Uri.parse("http://127.0.0.1:8000/api/apply/${widget.companyId}/");

    var response = await http.post(url, headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    });

    var msg = jsonDecode(response.body)["message"];

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    fetchCompany();
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

    return Scaffold(
      appBar: AppBar(title: Text(company["name"])),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ROLE
          Text(company["role"],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          // PACKAGE + LOCATION
          Row(
            children: [
              const Icon(Icons.currency_rupee),
              Text(company["package"]),
              const SizedBox(width: 20),
              const Icon(Icons.location_on_outlined),
              Text(company["location"]),
            ],
          ),

          const SizedBox(height: 20),

          // ELIGIBILITY BADGE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: eligible ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  eligible ? Icons.check_circle : Icons.cancel,
                  color: eligible ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    eligible
                        ? "You are eligible"
                        : company["eligibility_reason"],
                    style: TextStyle(
                        color: eligible ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SKILLS
          const Text("Required Skills",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          buildSkillChips(company["required_skills"]),

          const SizedBox(height: 20),

          // DESCRIPTION
          const Text("Job Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(company["description"]),

          const SizedBox(height: 30),

          // APPLY BUTTON
          if (applied)
            const Center(
              child: Text("Already Applied ✓",
                  style: TextStyle(fontSize: 18, color: Colors.green)),
            )
          else
            ElevatedButton(
              onPressed: eligible ? applyCompany : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(eligible ? "Apply Now" : "Not Eligible"),
            ),
        ],
      ),
    );
  }
}