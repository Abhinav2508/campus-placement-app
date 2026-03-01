class DashboardModel {
  final String name;
  final double cgpa;
  final int eligibleCompanies;
  final int applied;
  final int upcoming;
  final List<Activity> recentActivity;

  DashboardModel({
    required this.name,
    required this.cgpa,
    required this.eligibleCompanies,
    required this.applied,
    required this.upcoming,
    required this.recentActivity,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      name: json['name'],
      cgpa: (json['cgpa'] as num).toDouble(),
      eligibleCompanies: json['eligible_companies'],
      applied: json['applied'],
      upcoming: json['upcoming'],
      recentActivity: (json['recent_activity'] as List)
          .map((e) => Activity.fromJson(e))
          .toList(),
    );
  }
}

class Activity {
  final String company;
  final String role;
  final String status;

  Activity({required this.company, required this.role, required this.status});

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      company: json['company'],
      role: json['role'],
      status: json['status'],
    );
  }
}