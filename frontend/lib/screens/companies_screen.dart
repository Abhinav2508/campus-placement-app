import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'company_detail_screen.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {

  List allCompanies = [];
  List filteredCompanies = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Full-Time', 'Internship', 'Remote', 'On-Site'];

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/companies/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        allCompanies = jsonDecode(response.body);
        _applyFilters();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredCompanies = allCompanies.where((c) {
        // text match
        final query = searchController.text.toLowerCase();
        final name = (c["name"] ?? "").toString().toLowerCase();
        final role = (c["role"] ?? "").toString().toLowerCase();
        final matchesText = query.isEmpty || name.contains(query) || role.contains(query);

        // chip match
        bool matchesChip = true;
        if (selectedFilter != 'All') {
          final jobType = (c["job_type"] ?? "").toString();
          final workMode = (c["work_mode"] ?? "").toString();
          matchesChip = jobType == selectedFilter || workMode == selectedFilter;
        }

        return matchesText && matchesChip;
      }).toList();
    });
  }

  Widget jobPill(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6)
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
    );
  }

  Widget companyCard(company) {
    String logoUrl = company["logo_url"] ?? "";
    String jobType = company["job_type"] ?? "Full-Time";
    String workMode = company["work_mode"] ?? "On-Site";
    String experience = company["experience"] ?? "Fresher";
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyDetailScreen(companyId: company["id"]),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Company Logo / Initials
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: logoUrl.isNotEmpty 
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Center(child: Icon(Icons.business, color: Colors.grey)))) 
                    : Center(
                        child: Text(
                          company["name"][0],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ),
                ),

                const SizedBox(width: 14),

                /// Job Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company["role"],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text(company["name"],
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade800)),
                      const SizedBox(height: 4),
                      Text(company["location"], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // SALARY
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.currency_rupee, size: 14, color: Colors.black87),
                  const SizedBox(width: 4),
                  Text(company["package"], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
            ),

            // PILLS
            Row(
              children: [
                jobPill(jobType),
                jobPill(workMode),
                jobPill(experience),
              ],
            ),

            const SizedBox(height: 16),
            
            // FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text("Actively hiring", style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text("Deadline: ${company['deadline']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ]
            )

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(
        title: const Text("Companies", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: searchController,
              onChanged: (val) => _applyFilters(),
              decoration: InputDecoration(
                hintText: "Search companies or roles...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xfff4f6fa),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0)
              ),
            ),
          ),

          // CATEGORY CHIPS
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: Colors.indigo,
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) {
                          selectedFilter = filter;
                          _applyFilters();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // NOTIFICATIONS LAYERS
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchCompanies,
                    child: filteredCompanies.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Icon(Icons.search_off, size: 60, color: Colors.grey),
                              SizedBox(height: 16),
                              Center(child: Text("No companies match your search", style: TextStyle(color: Colors.grey, fontSize: 16))),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredCompanies.length,
                            itemBuilder: (context, index) {
                              return companyCard(filteredCompanies[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
