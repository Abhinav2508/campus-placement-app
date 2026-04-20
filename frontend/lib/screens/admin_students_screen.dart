import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_add_student_screen.dart';
import 'admin_edit_student_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  List<dynamic> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final res = await AdminService.getStudents();
      setState(() {
        students = res;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error loading students")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAddStudentScreen()),
          );
          if (result == true) {
            setState(() => isLoading = true);
            _fetchStudents();
          }
        },
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (students.isEmpty 
            ? const Center(child: Text("No students found"))
            : RefreshIndicator(
                onRefresh: _fetchStudents,
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final s = students[index];
                    final name = s["name"] != null && s["name"].toString().trim().isNotEmpty
                        ? s["name"].toString()
                        : "Unnamed Student";

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.shade100,
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text("${s["roll_no"] ?? 'No Roll'} · ${s["branch"] ?? 'No Branch'}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("${s["cgpa"] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.indigo),
                              tooltip: "Edit Student",
                              onPressed: () async {
                                // Build a sanitized student map for the edit screen
                                final studentMap = Map<String, dynamic>.from(s);
                                studentMap["name"] = name == "Unnamed Student" ? "" : name;

                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminEditStudentScreen(studentData: studentMap),
                                  ),
                                );
                                if (result == true) {
                                  setState(() => isLoading = true);
                                  _fetchStudents();
                                }
                              },
                            ),
                          ],
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

