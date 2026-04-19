import 'package:flutter/material.dart';
import '../models/application_model.dart';

class ApplicationTimelineCard extends StatelessWidget {
  final ApplicationModel app;

  const ApplicationTimelineCard({super.key, required this.app});

  int getStageIndex() {
    switch (app.status.toLowerCase()) {
      case "applied":
        return 1;
      case "shortlisted":
        return 2;
      case "interview":
        return 3;
      case "selected":
      case "rejected":
        return 4;
      default:
        return 1;
    }
  }

  Widget buildStep(int step, String title, String? dateStr) {
    bool completed = getStageIndex() >= step;
    bool isRejected = app.status.toLowerCase() == "rejected" && step == 4;

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: completed ? (isRejected ? Colors.red : Colors.green) : Colors.grey[300],
            child: completed ? Icon(isRejected ? Icons.close : Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(height: 8),
          Text(title, 
            style: TextStyle(fontSize: 11, fontWeight: completed ? FontWeight.bold : FontWeight.normal),
            textAlign: TextAlign.center,
          ),
          if (dateStr != null && dateStr.isNotEmpty)
            Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Text(app.companyName[0]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.companyName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(app.role, style: const TextStyle(color: Colors.grey))
                  ],
                ),
              ),
              Chip(
                label: Text(app.status.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                backgroundColor: app.status.toLowerCase() == 'rejected' ? Colors.red[100] : (app.status.toLowerCase() == 'selected' ? Colors.green[100] : Colors.blue[50]),
              )
            ],
          ),

          const SizedBox(height: 18),

          /// TIMELINE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildStep(1, "Applied", app.appliedAt),
              buildStep(2, "Shortlisted", app.shortlistedAt),
              buildStep(3, "Interview", app.interviewAt),
              buildStep(4, "Result", app.resultAt),
            ],
          ),
        ],
      ),
    );
  }
}