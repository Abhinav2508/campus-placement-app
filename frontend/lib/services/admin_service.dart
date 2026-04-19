import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AdminService {
  static final String baseUrl = "${AppConfig.baseUrl}/api/admin";

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    };
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(Uri.parse("$baseUrl/dashboard/"), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to load admin dashboard");
  }

  static Future<List<dynamic>> getStudents() async {
    final response = await http.get(Uri.parse("$baseUrl/students/"), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to load students");
  }

  static Future<List<dynamic>> getCompanies() async {
    final response = await http.get(Uri.parse("$baseUrl/companies/"), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to load companies");
  }

  static Future<List<dynamic>> getApplications() async {
    final response = await http.get(Uri.parse("$baseUrl/applications/"), headers: await _getHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to load applications");
  }

  static Future<bool> updateApplicationStatus(int appId, String status) async {
    final response = await http.put(
      Uri.parse("$baseUrl/application/$appId/status/"),
      headers: await _getHeaders(),
      body: jsonEncode({"status": status}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> addCompany(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/company/add/"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }
}
