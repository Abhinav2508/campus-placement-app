import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = 'http://127.0.0.1:8000/api/admin';

  late final TabController _tabController;
  late Future<Map<String, List<dynamic>>> adminDataFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    adminDataFuture = fetchAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Login expired');
    }
    return token;
  }

  Future<List<dynamic>> _getList(String endpoint) async {
    final token = await _token();
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List<dynamic>) {
        return data;
      }
      return [];
    }

    if (response.statusCode == 403) {
      throw Exception('Only admin users can access this panel');
    }

    throw Exception('Failed to load $endpoint');
  }

  Future<Map<String, List<dynamic>>> fetchAdminData() async {
    final results = await Future.wait([
      _getList('users'),
      _getList('students'),
      _getList('companies'),
      _getList('applications'),
    ]);

    return {
      'users': results[0],
      'students': results[1],
      'companies': results[2],
      'applications': results[3],
    };
  }

  Future<void> _refresh() async {
    setState(() {
      adminDataFuture = fetchAdminData();
    });
    await adminDataFuture;
  }

  Future<void> _deleteEntity(String endpoint, int id) async {
    final token = await _token();
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Delete failed for $endpoint');
    }
  }

  Future<void> _patchEntity(String endpoint, int id, Map<String, dynamic> body) async {
    final token = await _token();
    final response = await http.patch(
      Uri.parse('$baseUrl/$endpoint/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Update failed for $endpoint');
    }
  }

  Future<void> _createCompanyDialog() async {
    final name = TextEditingController();
    final role = TextEditingController();
    final packageCtrl = TextEditingController();
    final location = TextEditingController();
    final branch = TextEditingController();
    final minCgpa = TextEditingController(text: '0');
    final skills = TextEditingController();
    final description = TextEditingController();
    final deadline = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    String type = 'service';

    final created = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Company'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: role, decoration: const InputDecoration(labelText: 'Role')),
                TextField(controller: packageCtrl, decoration: const InputDecoration(labelText: 'Package')),
                TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'service', child: Text('service')),
                    DropdownMenuItem(value: 'product', child: Text('product')),
                    DropdownMenuItem(value: 'startup', child: Text('startup')),
                  ],
                  onChanged: (v) => type = v ?? 'service',
                ),
                TextField(controller: branch, decoration: const InputDecoration(labelText: 'Eligible Branch')),
                TextField(controller: minCgpa, decoration: const InputDecoration(labelText: 'Min CGPA')),
                TextField(controller: skills, decoration: const InputDecoration(labelText: 'Required Skills')),
                TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: deadline, decoration: const InputDecoration(labelText: 'Deadline YYYY-MM-DD')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
          ],
        );
      },
    );

    if (created != true) {
      return;
    }

    final token = await _token();
    final response = await http.post(
      Uri.parse('$baseUrl/companies/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name.text.trim(),
        'role': role.text.trim(),
        'package': packageCtrl.text.trim(),
        'location': location.text.trim(),
        'type': type,
        'eligible_branch': branch.text.trim(),
        'min_cgpa': double.tryParse(minCgpa.text.trim()) ?? 0,
        'required_skills': skills.text.trim(),
        'description': description.text.trim(),
        'deadline': deadline.text.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create company');
    }
    await _refresh();
  }

  Future<void> _showError(Object error) async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
  }

  Future<void> _createUserDialog() async {
    final username = TextEditingController();
    final email = TextEditingController();
    final firstName = TextEditingController();
    final lastName = TextEditingController();
    final password = TextEditingController();
    bool isStaff = false;
    bool isSuperuser = false;
    bool isActive = true;

    final create = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First Name')),
                  TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last Name')),
                  TextField(controller: password, decoration: const InputDecoration(labelText: 'Password')),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Staff'),
                    value: isStaff,
                    onChanged: (v) => setDialogState(() => isStaff = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Superuser'),
                    value: isSuperuser,
                    onChanged: (v) => setDialogState(() => isSuperuser = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
            ],
          );
        },
      ),
    );

    if (create != true) return;

    final token = await _token();
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username.text.trim(),
        'email': email.text.trim(),
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
        'password': password.text.trim(),
        'is_staff': isStaff,
        'is_superuser': isSuperuser,
        'is_active': isActive,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create user');
    }
    await _refresh();
  }

  Future<void> _editUserDialog(Map<String, dynamic> user) async {
    final id = user['id'] as int;
    final email = TextEditingController(text: (user['email'] ?? '').toString());
    final firstName = TextEditingController(text: (user['first_name'] ?? '').toString());
    final lastName = TextEditingController(text: (user['last_name'] ?? '').toString());
    final password = TextEditingController();
    bool isStaff = user['is_staff'] == true;
    bool isSuperuser = user['is_superuser'] == true;
    bool isActive = user['is_active'] == true;

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit ${user['username']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First Name')),
                  TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last Name')),
                  TextField(controller: password, decoration: const InputDecoration(labelText: 'New Password (optional)')),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Staff'),
                    value: isStaff,
                    onChanged: (v) => setDialogState(() => isStaff = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Superuser'),
                    value: isSuperuser,
                    onChanged: (v) => setDialogState(() => isSuperuser = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    if (save != true) return;

    final payload = {
      'email': email.text.trim(),
      'first_name': firstName.text.trim(),
      'last_name': lastName.text.trim(),
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'is_active': isActive,
    };
    if (password.text.trim().isNotEmpty) {
      payload['password'] = password.text.trim();
    }
    await _patchEntity('users', id, payload);
    await _refresh();
  }

  Future<void> _createStudentDialog(List<dynamic> users) async {
    final availableUsers = users.cast<Map<String, dynamic>>();
    if (availableUsers.isEmpty) {
      throw Exception('Create a user first');
    }

    int selectedUserId = availableUsers.first['id'] as int;
    final name = TextEditingController();
    final rollNo = TextEditingController();
    final branch = TextEditingController();
    final cgpa = TextEditingController(text: '0');
    final skills = TextEditingController();

    final create = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Student'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedUserId,
                    decoration: const InputDecoration(labelText: 'User'),
                    items: availableUsers
                        .map((u) => DropdownMenuItem<int>(
                              value: u['id'] as int,
                              child: Text((u['username'] ?? '').toString()),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedUserId = v ?? selectedUserId),
                  ),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: rollNo, decoration: const InputDecoration(labelText: 'Roll No')),
                  TextField(controller: branch, decoration: const InputDecoration(labelText: 'Branch')),
                  TextField(controller: cgpa, decoration: const InputDecoration(labelText: 'CGPA')),
                  TextField(controller: skills, decoration: const InputDecoration(labelText: 'Skills (comma separated)')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
            ],
          );
        },
      ),
    );

    if (create != true) return;

    final token = await _token();
    final response = await http.post(
      Uri.parse('$baseUrl/students/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user': selectedUserId,
        'name': name.text.trim(),
        'roll_no': rollNo.text.trim(),
        'branch': branch.text.trim(),
        'cgpa': double.tryParse(cgpa.text.trim()) ?? 0,
        'skills': skills.text.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create student');
    }
    await _refresh();
  }

  Future<void> _editStudentDialog(Map<String, dynamic> student, List<dynamic> users) async {
    int selectedUserId = (student['user'] as int?) ?? 0;
    final name = TextEditingController(text: (student['name'] ?? '').toString());
    final rollNo = TextEditingController(text: (student['roll_no'] ?? '').toString());
    final branch = TextEditingController(text: (student['branch'] ?? '').toString());
    final cgpa = TextEditingController(text: (student['cgpa'] ?? '').toString());
    final skills = TextEditingController(text: (student['skills'] ?? '').toString());

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Student'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedUserId == 0 ? null : selectedUserId,
                    decoration: const InputDecoration(labelText: 'User'),
                    items: users
                        .cast<Map<String, dynamic>>()
                        .map((u) => DropdownMenuItem<int>(
                              value: u['id'] as int,
                              child: Text((u['username'] ?? '').toString()),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedUserId = v ?? selectedUserId),
                  ),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: rollNo, decoration: const InputDecoration(labelText: 'Roll No')),
                  TextField(controller: branch, decoration: const InputDecoration(labelText: 'Branch')),
                  TextField(controller: cgpa, decoration: const InputDecoration(labelText: 'CGPA')),
                  TextField(controller: skills, decoration: const InputDecoration(labelText: 'Skills')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    if (save != true) return;

    await _patchEntity('students', student['id'] as int, {
      'user': selectedUserId,
      'name': name.text.trim(),
      'roll_no': rollNo.text.trim(),
      'branch': branch.text.trim(),
      'cgpa': double.tryParse(cgpa.text.trim()) ?? 0,
      'skills': skills.text.trim(),
    });
    await _refresh();
  }

  Future<void> _editCompanyDialog(Map<String, dynamic> company) async {
    final name = TextEditingController(text: (company['name'] ?? '').toString());
    final role = TextEditingController(text: (company['role'] ?? '').toString());
    final packageCtrl = TextEditingController(text: (company['package'] ?? '').toString());
    final location = TextEditingController(text: (company['location'] ?? '').toString());
    final branch = TextEditingController(text: (company['eligible_branch'] ?? '').toString());
    final minCgpa = TextEditingController(text: (company['min_cgpa'] ?? '').toString());
    final skills = TextEditingController(text: (company['required_skills'] ?? '').toString());
    final description = TextEditingController(text: (company['description'] ?? '').toString());
    final deadline = TextEditingController(text: (company['deadline'] ?? '').toString());
    String type = (company['type'] ?? 'service').toString();

    final save = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Company'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: role, decoration: const InputDecoration(labelText: 'Role')),
                  TextField(controller: packageCtrl, decoration: const InputDecoration(labelText: 'Package')),
                  TextField(controller: location, decoration: const InputDecoration(labelText: 'Location')),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'service', child: Text('service')),
                      DropdownMenuItem(value: 'product', child: Text('product')),
                      DropdownMenuItem(value: 'startup', child: Text('startup')),
                    ],
                    onChanged: (v) => setDialogState(() => type = v ?? type),
                  ),
                  TextField(controller: branch, decoration: const InputDecoration(labelText: 'Eligible Branch')),
                  TextField(controller: minCgpa, decoration: const InputDecoration(labelText: 'Min CGPA')),
                  TextField(controller: skills, decoration: const InputDecoration(labelText: 'Required Skills')),
                  TextField(controller: description, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(controller: deadline, decoration: const InputDecoration(labelText: 'Deadline YYYY-MM-DD')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    if (save != true) return;

    await _patchEntity('companies', company['id'] as int, {
      'name': name.text.trim(),
      'role': role.text.trim(),
      'package': packageCtrl.text.trim(),
      'location': location.text.trim(),
      'type': type,
      'eligible_branch': branch.text.trim(),
      'min_cgpa': double.tryParse(minCgpa.text.trim()) ?? 0,
      'required_skills': skills.text.trim(),
      'description': description.text.trim(),
      'deadline': deadline.text.trim(),
    });
    await _refresh();
  }

  Future<void> _createApplicationDialog(List<dynamic> users, List<dynamic> companies) async {
    final userItems = users.cast<Map<String, dynamic>>();
    final companyItems = companies.cast<Map<String, dynamic>>();
    if (userItems.isEmpty || companyItems.isEmpty) {
      throw Exception('Users and companies are required');
    }

    int selectedUser = userItems.first['id'] as int;
    int selectedCompany = companyItems.first['id'] as int;
    String status = 'applied';

    final create = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create Application'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedUser,
                    decoration: const InputDecoration(labelText: 'Student User'),
                    items: userItems
                        .map((u) => DropdownMenuItem<int>(
                              value: u['id'] as int,
                              child: Text((u['username'] ?? '').toString()),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedUser = v ?? selectedUser),
                  ),
                  DropdownButtonFormField<int>(
                    value: selectedCompany,
                    decoration: const InputDecoration(labelText: 'Company'),
                    items: companyItems
                        .map((c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text((c['name'] ?? '').toString()),
                            ))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedCompany = v ?? selectedCompany),
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'applied', child: Text('applied')),
                      DropdownMenuItem(value: 'shortlisted', child: Text('shortlisted')),
                      DropdownMenuItem(value: 'interview', child: Text('interview')),
                      DropdownMenuItem(value: 'selected', child: Text('selected')),
                      DropdownMenuItem(value: 'rejected', child: Text('rejected')),
                    ],
                    onChanged: (v) => setDialogState(() => status = v ?? status),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
            ],
          );
        },
      ),
    );

    if (create != true) return;

    final token = await _token();
    final response = await http.post(
      Uri.parse('$baseUrl/applications/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'student': selectedUser,
        'company': selectedCompany,
        'status': status,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create application');
    }
    await _refresh();
  }

  Widget _buildUsersTab(List<dynamic> users) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _createUserDialog();
                } catch (e) {
                  await _showError(e);
                }
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add User'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index] as Map<String, dynamic>;
              final id = user['id'] as int;
              final username = (user['username'] ?? '').toString();
              final isStaff = user['is_staff'] == true;
              final isActive = user['is_active'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(username),
                  subtitle: Text('Email: ${user['email'] ?? ''} | Staff: $isStaff | Active: $isActive'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        if (value == 'toggle_staff') {
                          await _patchEntity('users', id, {'is_staff': !isStaff});
                          await _refresh();
                        } else if (value == 'toggle_active') {
                          await _patchEntity('users', id, {'is_active': !isActive});
                          await _refresh();
                        } else if (value == 'edit') {
                          await _editUserDialog(user);
                        } else if (value == 'delete') {
                          await _deleteEntity('users', id);
                          await _refresh();
                        }
                      } catch (e) {
                        await _showError(e);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'toggle_staff', child: Text(isStaff ? 'Remove staff' : 'Make staff')),
                      PopupMenuItem(value: 'toggle_active', child: Text(isActive ? 'Deactivate' : 'Activate')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab(List<dynamic> students, List<dynamic> users) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _createStudentDialog(users);
                } catch (e) {
                  await _showError(e);
                }
              },
              icon: const Icon(Icons.school),
              label: const Text('Add Student'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index] as Map<String, dynamic>;
              final id = student['id'] as int;
              final name = (student['name'] ?? '').toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(name.isEmpty ? 'Unnamed Student' : name),
                  subtitle: Text('User: ${student['user_username'] ?? ''} | Branch: ${student['branch'] ?? ''} | CGPA: ${student['cgpa'] ?? ''}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        if (value == 'edit') {
                          await _editStudentDialog(student, users);
                        } else if (value == 'delete') {
                          await _deleteEntity('students', id);
                          await _refresh();
                        }
                      } catch (e) {
                        await _showError(e);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompaniesTab(List<dynamic> companies) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _createCompanyDialog();
                } catch (e) {
                  await _showError(e);
                }
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Add Company'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index] as Map<String, dynamic>;
              final id = company['id'] as int;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text((company['name'] ?? '').toString()),
                  subtitle: Text('Role: ${company['role'] ?? ''} | Min CGPA: ${company['min_cgpa'] ?? ''}'),
                  onTap: () async {
                    try {
                      await _editCompanyDialog(company);
                    } catch (e) {
                      await _showError(e);
                    }
                  },
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        if (value == 'edit') {
                          await _editCompanyDialog(company);
                        } else if (value == 'delete') {
                          await _deleteEntity('companies', id);
                          await _refresh();
                        }
                      } catch (e) {
                        await _showError(e);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsTab(
    List<dynamic> applications,
    List<dynamic> users,
    List<dynamic> companies,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await _createApplicationDialog(users, companies);
                } catch (e) {
                  await _showError(e);
                }
              },
              icon: const Icon(Icons.add_task),
              label: const Text('Add Application'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index] as Map<String, dynamic>;
              final id = app['id'] as int;
              final status = (app['status'] ?? 'applied').toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('${app['student_username'] ?? ''} -> ${app['company_name'] ?? ''}'),
                  subtitle: Text('Status: $status'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        if (value == 'delete') {
                          await _deleteEntity('applications', id);
                        } else {
                          await _patchEntity('applications', id, {'status': value});
                        }
                        await _refresh();
                      } catch (e) {
                        await _showError(e);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'applied', child: Text('Set applied')),
                      PopupMenuItem(value: 'shortlisted', child: Text('Set shortlisted')),
                      PopupMenuItem(value: 'interview', child: Text('Set interview')),
                      PopupMenuItem(value: 'selected', child: Text('Set selected')),
                      PopupMenuItem(value: 'rejected', child: Text('Set rejected')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Students'),
            Tab(text: 'Companies'),
            Tab(text: 'Applications'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, List<dynamic>>>(
        future: adminDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(snapshot.error.toString()),
              ),
            );
          }

          final data = snapshot.data ?? <String, List<dynamic>>{};
          return RefreshIndicator(
            onRefresh: _refresh,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(data['users'] ?? []),
                _buildStudentsTab(data['students'] ?? [], data['users'] ?? []),
                _buildCompaniesTab(data['companies'] ?? []),
                _buildApplicationsTab(
                  data['applications'] ?? [],
                  data['users'] ?? [],
                  data['companies'] ?? [],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
