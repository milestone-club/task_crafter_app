// ignore_for_file: use_super_parameters, no_leading_underscores_for_local_identifiers

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_crafter_app/widgets/go_to_task.dart';
import 'package:task_crafter_app/widgets/tasks.dart';
import 'personal_tasks.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OpenPage extends StatefulWidget {
  const OpenPage({Key? key}) : super(key: key);

  @override
  State<OpenPage> createState() => _OpenPageState();
}

class _OpenPageState extends State<OpenPage> {
  late String userId = '';
  String? selectedProjectId; // Track the selected project ID
  String? selectedProjectName; // Track the selected project name

  @override
  void initState() {
    super.initState();
    fetchUserId();
  }

  Future<void> fetchUserId() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final User? user = _auth.currentUser;
    if (user != null && mounted) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  void onProjectSelected(String projectId) async {
    setState(() {
      selectedProjectId = projectId;
    });
    await fetchProjectName(projectId);
  }

  void setDefaultProjectId(String projectId) {
    if (selectedProjectId == null) {
      setState(() {
        selectedProjectId = projectId;
      });
      fetchProjectName(projectId);
    }
  }

  Future<void> fetchProjectName(String projectId) async {
    DocumentSnapshot projectDoc = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .get();
    if (mounted) {
      setState(() {
        selectedProjectName = projectDoc['title'];
      });
    }
  }

  void navigateToPersonalTasksPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonalTasks()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor:
            Color.fromARGB(255, 255, 255, 255), // Set background color to white
        elevation: 0,
        // No shadow
        title: const Text(
          'My Projects',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Text color
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => navigateToPersonalTasksPage(context),
            child: const Text(
              'Personal Tasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(221, 28, 27, 27), // Text color
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GoToTask(
              userId: userId,
              onProjectSelected: onProjectSelected,
              setDefaultProjectId: setDefaultProjectId,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            child: Text(
              selectedProjectName ?? 'Select a project',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Tasks(projectId: selectedProjectId),
          ),
        ],
      ),
    );
  }
}
