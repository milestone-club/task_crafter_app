// ignore_for_file: use_super_parameters, library_private_types_in_public_api, prefer_const_constructors, avoid_print, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import DateFormat
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_crafter_app/screens/project_detail_page.dart';

class GoToTask extends StatefulWidget {
  final String userId;
  final Function(String) onProjectSelected;
  final Function(String) setDefaultProjectId;

  const GoToTask({
    Key? key,
    required this.userId,
    required this.onProjectSelected,
    required this.setDefaultProjectId,
  }) : super(key: key);

  @override
  _GoToTaskState createState() => _GoToTaskState();
}

class _GoToTaskState extends State<GoToTask> {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No projects found for this user'));
        }

        List<DocumentSnapshot> userProjects =
            snapshot.data!.docs.where((projectDoc) {
          List<dynamic> members = projectDoc['members'];

          // Debug print to check the structure of members
          print('Project members: $members');

          return members.any((member) {
            // Ensure member is a map before accessing 'id'
            if (member is Map<String, dynamic>) {
              return member['id'] == widget.userId;
            }
            return false;
          });
        }).toList();

        // Set the default project ID to the first project if it's not already set
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userProjects.isNotEmpty) {
            widget.setDefaultProjectId(userProjects.first.id);
          }
        });

        return SizedBox(
          height: 50,
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: userProjects.length,
            itemBuilder: (context, index) {
              DocumentSnapshot projectDoc = userProjects[index];
              String projectId = projectDoc.id;
              String projectTitle = projectDoc['title'];
              String projectDescription = projectDoc['desc'];
              dynamic projectDeadline = projectDoc[
                  'deadline']; // Assume deadline can be int or String
              List<dynamic> members = projectDoc['members'];

              String deadlineText = projectDeadline is int
                  ? 'Deadline: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(projectDeadline))}'
                  : projectDeadline ?? 'No deadline';

              return GestureDetector(
                onTap: () {
                  widget.onProjectSelected(projectId);
                },
                child: Container(
                  width: 300,
                  height: 50,
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 102, 179, 215),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '$projectDescription\n$deadlineText',
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailsPage(
                                projectId: projectId,
                                projectTitle: projectTitle,
                                projectDescription: projectDescription,
                                members: members,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'Go to tasks',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
