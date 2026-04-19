import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminEditStudentScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const AdminEditStudentScreen({super.key, required this.studentData});

  @override
  State<AdminEditStudentScreen> createState() => _AdminEditStudentScreenState();
}

class _AdminEditStudentScreenState extends State<AdminEditStudentScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController rollController;
  late TextEditingController phoneController;
  late TextEditingController cgpaController;
  late TextEditingController skillsController;
  late TextEditingController linkedinController;
  late TextEditingController githubController;

  late String branch;
  final List<String> branches = ["Computer Science", "IT", "Electronics", "Mechanical", "Civil"];

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.studentData["name"] ?? "");
    emailController = TextEditingController(text: widget.studentData["email"] ?? "");
    rollController = TextEditingController(text: widget.studentData["roll_no"] ?? "");
    phoneController = TextEditingController(text: widget.studentData["phone"] ?? "");
    cgpaController = TextEditingController(text: widget.studentData["cgpa"]?.toString() ?? "0.0");
    skillsController = TextEditingController(text: widget.studentData["skills"] ?? "");
    linkedinController = TextEditingController(text: widget.studentData["linkedin"] ?? "");
    githubController = TextEditingController(text: widget.studentData["github"] ?? "");
    
    branch = widget.studentData["branch"] ?? "Computer Science";
    if (!branches.contains(branch)) {
      branch = "Computer Science";
    }
  }

  Future<void> _submit() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name is required.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    int studentId = widget.studentData["id"];

    final url = Uri.parse("${AppConfig.baseUrl}/api/admin/student/$studentId/edit/");
    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "roll_no": rollController.text.trim(),
        "branch": branch,
        "phone": phoneController.text.trim(),
        "cgpa": double.tryParse(cgpaController.text.trim()) ?? 0.0,
        "skills": skillsController.text.trim(),
        "linkedin": linkedinController.text.trim(),
        "github": githubController.text.trim(),
      }),
    );

    setState(() => isSubmitting = false);

    if (res.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student profile updated successfully!")),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        final error = jsonDecode(res.body)["error"] ?? "Failed to update profile";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Edit Student"), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Account Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildField("Full Name", nameController),
          _buildField("Email", emailController, keyboardType: TextInputType.emailAddress),
          _buildField("Phone", phoneController, keyboardType: TextInputType.phone),

          const SizedBox(height: 20),
          const Text("Academic Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildField("Roll Number", rollController),
          _buildField("CGPA", cgpaController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          DropdownButtonFormField<String>(
            value: branch,
            decoration: InputDecoration(
              labelText: "Branch",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (val) => setState(() => branch = val!),
          ),

          const SizedBox(height: 20),
          const Text("Professional Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildField("Skills (comma separated)", skillsController, maxLines: 2),
          _buildField("LinkedIn URL", linkedinController, keyboardType: TextInputType.url),
          _buildField("GitHub URL", githubController, keyboardType: TextInputType.url),

          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text("Save Changes", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}


