class ProfileModel {
  final String name;
  final String rollNo;
  final String branch;
  final double cgpa;
  final String skills;
  final String? resumeUrl;
  final bool isAdmin;

  ProfileModel({
    required this.name,
    required this.rollNo,
    required this.branch,
    required this.cgpa,
    required this.skills,
    this.resumeUrl,
    required this.isAdmin,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'],
      rollNo: json['roll_no'],
      branch: json['branch'],
      cgpa: double.parse(json['cgpa'].toString()),
      skills: json['skills'],
      resumeUrl: json['resume_url'],
      isAdmin: json['is_admin'] ?? false,
    );
  }

  List<String> skillList() {
    return skills.split(',').map((e) => e.trim()).toList();
  }
}