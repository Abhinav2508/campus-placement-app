import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAddStudentScreen extends StatefulWidget {
  const AdminAddStudentScreen({super.key});

  @override
  State<AdminAddStudentScreen> createState() => _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends State<AdminAddStudentScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final emailController = TextEditingController();
  final rollController = TextEditingController();
  final phoneController = TextEditingController();

  String branch = "Computer Science";
  final List<String> branches = ["Computer Science", "IT", "Electronics", "Mechanical", "Civil"];

  bool isSubmitting = false;

  Future<void> _submit() async {
    if (usernameController.text.isEmpty || passwordController.text.isEmpty || nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name, Username, and Password are required.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse("http://127.0.0.1:8000/api/add-student/");
    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: jsonEncode({
        "username": usernameController.text.trim(),
        "password": passwordController.text.trim(),
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "roll_no": rollController.text.trim(),
        "branch": branch,
        "phone": phoneController.text.trim(),
        "cgpa": 0.0,
      }),
    );

    setState(() => isSubmitting = false);

    if (res.statusCode == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student created successfully!")),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        final error = jsonDecode(res.body)["error"] ?? "Failed to create student";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller, {bool isPass = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPass,
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
      appBar: AppBar(title: const Text("Add New Student"), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Account Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildField("Full Name", nameController),
          _buildField("Email", emailController),
          _buildField("Phone", phoneController),

          const SizedBox(height: 20),
          const Text("Academic Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildField("Roll Number", rollController),
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
          const Text("Login Credentials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildField("Username", usernameController),
          _buildField("Password", passwordController, isPass: true),

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
              : const Text("Create Student Account", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
