class ApplicationModel {
  final int id;
  final String companyName;
  final String role;
  final String package;
  final String location;
  final String status;
  final String? appliedAt;
  final String? shortlistedAt;
  final String? interviewAt;
  final String? resultAt;

  ApplicationModel({
    required this.id,
    required this.companyName,
    required this.role,
    required this.package,
    required this.location,
    required this.status,
    this.appliedAt,
    this.shortlistedAt,
    this.interviewAt,
    this.resultAt,
  });

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: json['id'],
      companyName: json['company_name'],
      role: json['role'],
      package: json['package'],
      location: json['location'],
      status: json['status'],
      appliedAt: json['applied_at'],
      shortlistedAt: json['shortlisted_at'],
      interviewAt: json['interview_at'],
      resultAt: json['result_at'],
    );
  }
}