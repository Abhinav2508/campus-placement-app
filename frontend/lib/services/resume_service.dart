import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ResumeService {

  static Future<String> uploadResume() async {

    try {

      // PICK FILE
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null) {
        return "Cancelled";
      }

      final pickedFile = result.files.single;

      // TOKEN
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null) return "Login expired";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://127.0.0.1:8000/api/upload-resume/"),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        final bytes = pickedFile.bytes;
        if (bytes == null) {
          return "Could not read selected file";
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'resume',
            bytes,
            filename: pickedFile.name,
          ),
        );
      } else {
        final path = pickedFile.path;
        if (path == null) {
          return "Could not read selected file path";
        }

        request.files.add(
          await http.MultipartFile.fromPath('resume', path),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        return "Uploaded successfully";
      } else {
        return "Upload failed (${response.statusCode})";
      }

    } catch (e) {
      return "Error: $e";
    }
  }
}