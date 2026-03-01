import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  late TextEditingController nameController;
  late TextEditingController branchController;
  late TextEditingController cgpaController;
  late TextEditingController skillsController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.profile.name);
    branchController = TextEditingController(text: widget.profile.branch);
    cgpaController =
        TextEditingController(text: widget.profile.cgpa.toString());
    skillsController =
        TextEditingController(text: widget.profile.skills);
  }

  Future<void> updateProfile() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    var url = Uri.parse("http://127.0.0.1:8000/api/update-profile/");

    var response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "name": nameController.text,
        "branch": branchController.text,
        "cgpa": double.parse(cgpaController.text),
        "skills": skillsController.text,
      }),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 200) {
      Navigator.pop(context, true); // return success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: branchController,
              decoration: const InputDecoration(labelText: "Branch"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: cgpaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "CGPA"),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: skillsController,
              decoration: const InputDecoration(
                  labelText: "Skills (comma separated)"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isLoading ? null : updateProfile,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}