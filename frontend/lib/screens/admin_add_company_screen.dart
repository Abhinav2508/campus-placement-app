import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class AdminAddCompanyScreen extends StatefulWidget {
  const AdminAddCompanyScreen({super.key});

  @override
  State<AdminAddCompanyScreen> createState() => _AdminAddCompanyScreenState();
}

class _AdminAddCompanyScreenState extends State<AdminAddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String name = "";
  String role = "";
  String package = "";
  String location = "";
  String type = "product";
  String eligibleBranch = "";
  double minCgpa = 0.0;
  String requiredSkills = "";
  String description = "";
  String deadline = "";
  String logoUrl = "";
  String jobType = "Full-Time";
  String workMode = "On-Site";
  String experience = "Fresher";
  String aboutCompany = "";

  bool isSaving = false;

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isSaving = true);

    try {
      final success = await AdminService.addCompany({
        "name": name,
        "role": role,
        "package": package,
        "location": location,
        "type": type,
        "eligible_branch": eligibleBranch,
        "min_cgpa": minCgpa,
        "required_skills": requiredSkills,
        "description": description,
        "deadline": deadline,
        "logo_url": logoUrl,
        "job_type": jobType,
        "work_mode": workMode,
        "experience": experience,
        "about_company": aboutCompany,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Company added successfully!")));
        Navigator.pop(context, true); // return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add company. Check deadline format YYYY-MM-DD")));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Company")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Company Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
                onSaved: (val) => name = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Role"),
                validator: (val) => val!.isEmpty ? "Required" : null,
                onSaved: (val) => role = val!,
              ),
              Row(
                children: [
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: "Package (LPA)"),
                    onSaved: (val) => package = val ?? "",
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: "Location"),
                    onSaved: (val) => location = val ?? "",
                  )),
                ],
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Type"),
                value: type,
                items: const [
                  DropdownMenuItem(value: "product", child: Text("Product")),
                  DropdownMenuItem(value: "service", child: Text("Service")),
                  DropdownMenuItem(value: "startup", child: Text("Startup")),
                ],
                onChanged: (val) => setState(() => type = val!),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Job Type"),
                      value: jobType,
                      items: const [
                        DropdownMenuItem(value: "Full-Time", child: Text("Full-Time")),
                        DropdownMenuItem(value: "Internship", child: Text("Internship")),
                        DropdownMenuItem(value: "Contract", child: Text("Contract")),
                      ],
                      onChanged: (val) => setState(() => jobType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Work Mode"),
                      value: workMode,
                      items: const [
                        DropdownMenuItem(value: "On-Site", child: Text("On-Site")),
                        DropdownMenuItem(value: "Hybrid", child: Text("Hybrid")),
                        DropdownMenuItem(value: "Remote", child: Text("Remote")),
                      ],
                      onChanged: (val) => setState(() => workMode = val!),
                    ),
                  )
                ],
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Experience (e.g. Fresher, 1-3 years)"),
                onSaved: (val) => experience = val ?? "Fresher",
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Logo Image URL (Optional)"),
                onSaved: (val) => logoUrl = val ?? "",
              ),
              Row(
                children: [
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: "Eligible Branch"),
                    onSaved: (val) => eligibleBranch = val ?? "",
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: "Min CGPA"),
                    keyboardType: TextInputType.number,
                    validator: (val) => double.tryParse(val!) == null ? "Must be number" : null,
                    onSaved: (val) => minCgpa = double.tryParse(val!) ?? 0.0,
                  )),
                ],
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Required Skills (comma separated)"),
                onSaved: (val) => requiredSkills = val ?? "",
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Job Description"),
                maxLines: 3,
                onSaved: (val) => description = val ?? "",
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "About Company"),
                maxLines: 3,
                onSaved: (val) => aboutCompany = val ?? "",
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Deadline (YYYY-MM-DD)", hintText: "e.g. 2026-12-31"),
                validator: (val) => val!.isEmpty ? "Required" : null,
                onSaved: (val) => deadline = val!,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isSaving ? null : _saveCompany,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
                child: isSaving ? const CircularProgressIndicator() : const Text("Save Company"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

