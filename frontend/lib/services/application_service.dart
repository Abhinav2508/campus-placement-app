import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/application_model.dart';
import '../config.dart';

class ApplicationService {

  static final String baseUrl = "${AppConfig.baseUrl}/api";

  static Future<List<ApplicationModel>> getMyApplications() async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    // 🔴 DEBUG PRINT (important)
    print("TOKEN = $token");

    final response = await http.get(
      Uri.parse("$baseUrl/my-applications/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("STATUS CODE = ${response.statusCode}");
    print("BODY = ${response.body}");

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => ApplicationModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load applications");
    }
  }
}