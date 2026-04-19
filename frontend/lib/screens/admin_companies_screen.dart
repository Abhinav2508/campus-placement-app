import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_add_company_screen.dart';

class AdminCompaniesScreen extends StatefulWidget {
  const AdminCompaniesScreen({super.key});

  @override
  State<AdminCompaniesScreen> createState() => _AdminCompaniesScreenState();
}

class _AdminCompaniesScreenState extends State<AdminCompaniesScreen> {
  List<dynamic> companies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final res = await AdminService.getCompanies();
      setState(() {
        companies = res;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error fetching companies")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAddCompanyScreen()),
          );
          if (result == true) {
            _fetchCompanies(); // refresh list
          }
        },
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (companies.isEmpty 
            ? const Center(child: Text("No companies found"))
            : RefreshIndicator(
                onRefresh: _fetchCompanies,
                child: ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final c = companies[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.business_center, color: Colors.blue),
                        ),
                        title: Text(c["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${c["role"]} • Package: ${c["package"]}\nDeadline: ${c["deadline"]}"),
                        isThreeLine: true,
                        trailing: Chip(
                          label: Text("Min CGPA: ${c["min_cgpa"]}"),
                        ),
                      ),
                    );
                  },
                ),
              )
          ),
    );
  }
}

