// ignore_for_file: use_super_parameters, library_private_types_in_public_api, prefer_const_constructors, use_build_context_synchronously, unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_crafter_app/models/task.dart';
import 'package:task_crafter_app/screens/task_detail.dart';

class Tasks extends StatefulWidget {
  final String? projectId;

  const Tasks({Key? key, this.projectId}) : super(key: key);

  @override
  _TasksState createState() => _TasksState();
}

class _TasksState extends State<Tasks> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    if (user == null) {
      return Center(child: Text('No user logged in'));
    }

    return FutureBuilder<List<Task>>(
      future: _fetchTasks(widget.projectId, user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No tasks found'));
        }

        List<Task> tasksList = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: tasksList.length,
          itemBuilder: (context, index) {
            final task = tasksList[index];
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              child: Dismissible(
                key: Key(
                    task.taskId!), // Use task's taskId as key for Dismissible
                background: Container(color: Colors.red),
                onDismissed: (direction) async {
                  try {
                    if (task.taskId != null) {
                      await _firestore
                          .collection('tasks')
                          .doc(task.taskId!)
                          .delete();
                      if (task.projectId != null &&
                          task.projectId!.isNotEmpty) {
                        await _firestore
                            .collection('projects')
                            .doc(task.projectId)
                            .collection('tasks')
                            .doc(task.taskId!)
                            .delete();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Task deleted successfully'),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Task ID is null or empty'),
                      ));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to delete task: $e'),
                    ));
                  }
                },
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(
                          task: task,
                        ),
                      ),
                    );
                    // After returning from TaskDetailPage, refresh the task list
                    setState(() {});
                  },
                  child: _buildTask(context, task),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Task>> _fetchTasks(String? projectId, String userId) async {
    List<Task> tasksList = [];

    if (projectId != null) {
      // Fetch the user's role from the project
      DocumentSnapshot projectDoc =
          await _firestore.collection('projects').doc(projectId).get();
      if (projectDoc.exists) {
        Map<String, dynamic> projectData =
            projectDoc.data() as Map<String, dynamic>;
        List<dynamic> members = projectData['members'];

        String? userRole;
        for (var member in members) {
          if (member['id'] == userId) {
            userRole = member['role'];
            break;
          }
        }

        if (userRole == 'Team Lead' || userRole == 'Project Manager') {
          // Fetch all tasks for Team Lead or Project Manager
          var tasksSnapshot = await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('tasks')
              .get();
          tasksList = tasksSnapshot.docs.map((doc) {
            return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        } else if (userRole == 'Member') {
          // Fetch only tasks that contain the user's ID for Member
          var tasksSnapshot = await _firestore
              .collection('projects')
              .doc(projectId)
              .collection('tasks')
              .where('userId', isEqualTo: userId)
              .get();
          tasksList = tasksSnapshot.docs.map((doc) {
            return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();
        }
      }
    }

    return tasksList;
  }

  Widget _buildTask(BuildContext context, Task task) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: task.bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title ?? '',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            task.desc ?? '',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: task.percent / 100,
          ),
        ],
      ),
    );
  }
}
