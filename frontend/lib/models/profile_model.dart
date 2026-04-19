class ProfileModel {
  final String name;
  final String rollNo;
  final String branch;
  final double cgpa;
  final String skills;
  final String phone;
  final String linkedin;
  final String github;
  final String email;
  final String resumeUrl;

  ProfileModel({
    required this.name,
    required this.rollNo,
    required this.branch,
    required this.cgpa,
    required this.skills,
    required this.phone,
    required this.linkedin,
    required this.github,
    required this.email,
    required this.resumeUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'],
      rollNo: json['roll_no'],
      branch: json['branch'],
      cgpa: double.parse(json['cgpa'].toString()),
      skills: json['skills'],
      phone: json['phone'] ?? '',
      linkedin: json['linkedin'] ?? '',
      github: json['github'] ?? '',
      email: json['email'] ?? '',
      resumeUrl: json['resume_url'] ?? '',
    );
  }

  List<String> skillList() {
    return skills.split(',').map((e) => e.trim()).toList();
  }
}