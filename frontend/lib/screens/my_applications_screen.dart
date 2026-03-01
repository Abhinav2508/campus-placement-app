import 'package:flutter/material.dart';
import '../models/application_model.dart';
import '../services/application_service.dart';
import '../widgets/application_timeline_card.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {

  late Future<List<ApplicationModel>> applicationsFuture;

  @override
  void initState() {
    super.initState();
    applicationsFuture = ApplicationService.getMyApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Applications"),
        centerTitle: true,
      ),

      body: FutureBuilder<List<ApplicationModel>>(
        future: applicationsFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load applications"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No applications yet"));
          }

          final applications = snapshot.data!;

          return ListView.builder(
            itemCount: applications.length,
            itemBuilder: (context, index) {
              return ApplicationTimelineCard(app: applications[index]);
            },
          );
        },
      ),
    );
  }
}