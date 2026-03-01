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

  Widget buildStep(int step, String title) {
    bool completed = getStageIndex() >= step;

    return Column(
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: completed ? Colors.blue : Colors.grey[300],
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 11))
      ],
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
                label: Text(app.status),
                backgroundColor: Colors.blue[50],
              )
            ],
          ),

          const SizedBox(height: 18),

          /// TIMELINE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildStep(1, "Applied"),
              buildStep(2, "Shortlisted"),
              buildStep(3, "Interview"),
              buildStep(4, "Result"),
            ],
          ),
        ],
      ),
    );
  }
}