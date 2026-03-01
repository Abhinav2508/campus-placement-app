class ProfileModel {
  final String name;
  final String rollNo;
  final String branch;
  final double cgpa;
  final String skills;

  ProfileModel({
    required this.name,
    required this.rollNo,
    required this.branch,
    required this.cgpa,
    required this.skills,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'],
      rollNo: json['roll_no'],
      branch: json['branch'],
      cgpa: double.parse(json['cgpa'].toString()),
      skills: json['skills'],
    );
  }

  List<String> skillList() {
    return skills.split(',').map((e) => e.trim()).toList();
  }
}