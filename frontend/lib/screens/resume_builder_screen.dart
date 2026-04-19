import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResumeBuilderScreen extends StatefulWidget {
  const ResumeBuilderScreen({super.key});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  Map profile = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final res = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/profile/"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode == 200) {
      setState(() {
        profile = jsonDecode(res.body);
        isLoading = false;
      });
    }
  }

  Future<void> generatePdf() async {
    final doc = pw.Document();
    final skills = (profile["skills"] as String? ?? "").split(",");

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // HEADER
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#1a237e'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    profile["name"] ?? "",
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    profile["branch"] ?? "",
                    style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey300),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // CONTACT ROW
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if ((profile["email"] ?? "").isNotEmpty)
                  pw.Text("📧 ${profile["email"]}", style: const pw.TextStyle(fontSize: 11)),
                if ((profile["phone"] ?? "").isNotEmpty)
                  pw.Text("📱 ${profile["phone"]}", style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            if ((profile["linkedin"] ?? "").isNotEmpty)
              pw.Text("LinkedIn: ${profile["linkedin"]}",
                  style: const pw.TextStyle(fontSize: 11)),
            if ((profile["github"] ?? "").isNotEmpty)
              pw.Text("GitHub: ${profile["github"]}",
                  style: const pw.TextStyle(fontSize: 11)),

            pw.SizedBox(height: 20),
            pw.Divider(),

            // EDUCATION
            pw.SizedBox(height: 12),
            _pdfSection("EDUCATION"),
            _pdfRow("Branch", profile["branch"] ?? ""),
            _pdfRow("Roll No", profile["roll_no"] ?? ""),
            _pdfRow("CGPA", profile["cgpa"]?.toString() ?? ""),

            pw.SizedBox(height: 16),
            _pdfSection("SKILLS"),
            pw.Wrap(
              spacing: 8,
              runSpacing: 4,
              children: skills.map((s) => pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#e8eaf6'),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(s.trim(),
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  )).toList(),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _pdfSection(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1a237e'))),
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
              width: 80,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(
        title: const Text("Resume Builder", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PREVIEW CARD
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff1a237e), Color(0xff4e4376)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white30,
                          child: Text(
                            (profile["name"] ?? "?")[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(profile["name"] ?? "",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text(profile["branch"] ?? "",
                            style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // INFO CARDS
                  _infoCard(Icons.school, "Education",
                      "${profile["branch"]} • CGPA: ${profile["cgpa"]}"),
                  _infoCard(Icons.badge, "Roll No", profile["roll_no"] ?? "-"),
                  _infoCard(Icons.email, "Email", profile["email"] ?? "-"),
                  if ((profile["phone"] ?? "").isNotEmpty)
                    _infoCard(Icons.phone, "Phone", profile["phone"]),
                  if ((profile["linkedin"] ?? "").isNotEmpty)
                    _infoCard(Icons.link, "LinkedIn", profile["linkedin"]),
                  if ((profile["github"] ?? "").isNotEmpty)
                    _infoCard(Icons.code, "GitHub", profile["github"]),

                  const SizedBox(height: 16),
                  const Text("Skills",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (profile["skills"] as String? ?? "")
                        .split(",")
                        .map((s) => Chip(
                              label: Text(s.trim(),
                                  style: TextStyle(
                                      color: Colors.indigo.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              backgroundColor: Colors.indigo.shade50,
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 40),

                  // PDF BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: generatePdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Download / Print PDF",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}


