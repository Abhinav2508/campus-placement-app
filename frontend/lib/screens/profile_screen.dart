import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_model.dart';
import '../services/profile_service.dart';
import '../services/resume_service.dart';
import '../main.dart';
import 'edit_profile_screen.dart';
import 'resume_builder_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
const ProfileScreen({super.key});

@override
State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
late Future<ProfileModel> profileFuture;

@override
void initState() {
super.initState();
profileFuture = ProfileService.getProfile();
}

// ================= LOGOUT =================
Future<void> logout(BuildContext context) async {
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.remove("token");


Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const LoginScreen()),
  (route) => false,
);


}

// ================= INFO TILE =================
Widget infoTile(IconData icon, String title, String value) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 10),
child: Row(
children: [
Icon(icon, color: Colors.grey.shade600),
const SizedBox(width: 14),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title,
style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
const SizedBox(height: 2),
Text(value,
style: const TextStyle(
fontSize: 15, fontWeight: FontWeight.w500)),
],
)
],
),
);
}

// ================= SECTION CARD =================
Widget sectionCard({required Widget child}) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(22),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(.05),
blurRadius: 12,
offset: const Offset(0, 6),
)
],
),
child: child,
);
}

// ================= UPLOAD RESUME =================
Future<void> uploadResume() async {
String result = await ResumeService.uploadResume();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(result)),
);

// refresh profile
setState(() {
  profileFuture = ProfileService.getProfile();
});

}

Future<void> _launchURL(String url) async {
  if (url.isEmpty) return;
  String fullUrl = url.startsWith('http') ? url : "http://127.0.0.1:8000$url";
  final uri = Uri.parse(fullUrl);
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Could not open link.")));
  }
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xfff4f6fa),
appBar: AppBar(
  title: const Text("Profile"),
  actions: [
    ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return IconButton(
          icon: Icon(mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
          tooltip: "Toggle Dark Mode",
          onPressed: () {
            themeNotifier.value =
                mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          },
        );
      },
    ),
  ],
),


  body: FutureBuilder<ProfileModel>(
    future: profileFuture,
    builder: (context, snapshot) {

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError || snapshot.data == null) {
        return const Center(child: Text("Failed to load profile"));
      }

      final profile = snapshot.data!;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ================= HERO CARD =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xffe8f0ff),
                    child: Text(
                      profile.name[0],
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(profile.branch,
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xffeef4ff),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text("CGPA: ${profile.cgpa}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= DETAILS =================
            sectionCard(
              child: Column(
                children: [
                  infoTile(Icons.badge_outlined, "ROLL NO", profile.rollNo),
                  infoTile(Icons.school_outlined, "BRANCH", profile.branch),
                  infoTile(Icons.star_outline, "CGPA", profile.cgpa.toString()),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= CONTACT INFO =================
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Contact Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  infoTile(Icons.email_outlined, "EMAIL", profile.email.isNotEmpty ? profile.email : "Not provided"),
                  infoTile(Icons.phone_outlined, "PHONE", profile.phone.isNotEmpty ? profile.phone : "Not provided"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= SOCIAL LINKS =================
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Social Links", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchURL(profile.linkedin),
                    child: infoTile(Icons.work_outline, "LINKEDIN", profile.linkedin.isNotEmpty ? profile.linkedin : "Not provided"),
                  ),
                  InkWell(
                    onTap: () => _launchURL(profile.github),
                    child: infoTile(Icons.code, "GITHUB", profile.github.isNotEmpty ? profile.github : "Not provided"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= SKILLS =================
            sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Skills",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: profile.skillList().map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xffeef1f6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(skill),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= RESUME =================
            sectionCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xffe8f7ef),
                    child: Icon(Icons.description, color: Colors.green),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Resume", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Upload your latest resume", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (profile.resumeUrl.isNotEmpty) 
                    OutlinedButton(
                      onPressed: () => _launchURL(profile.resumeUrl),
                      child: const Text("View"),
                    ),
                  if (profile.resumeUrl.isNotEmpty) const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: uploadResume,
                    child: const Text("Upload"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= EDIT PROFILE =================
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: profile),
                  ),
                );

                if (result == true) {
                  setState(() {
                    profileFuture = ProfileService.getProfile();
                  });
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text("Edit Profile"),
            ),

            const SizedBox(height: 12),

            // ================= RESUME BUILDER =================
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResumeBuilderScreen()),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Generate Resume"),
            ),

            const SizedBox(height: 12),

            // ================= LOGOUT =================
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),

            const SizedBox(height: 40),
          ],
        ),
      );
    },
  ),
);

}
}
