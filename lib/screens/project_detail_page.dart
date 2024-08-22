// ignore_for_file: use_super_parameters, prefer_const_constructors, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:task_crafter_app/screens/task_detail.dart';
import 'package:task_crafter_app/screens/comments.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Add this import for the CommentsPage
import 'package:task_crafter_app/models/task.dart';
import 'package:task_crafter_app/screens/edit_members.dart';

class ProjectDetailsPage extends StatelessWidget {
  final String projectId;
  final String projectTitle;
  final String projectDescription;
  final List<dynamic> members;

  const ProjectDetailsPage({
    Key? key,
    required this.projectId,
    required this.projectTitle,
    required this.projectDescription,
    required this.members,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F4F8),
      appBar: AppBar(
        title: Text('Project Details'),
        backgroundColor: Color(0xFFF1F4F8),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.black),
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                projectTitle,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                projectDescription,
                style: TextStyle(
                  fontSize: 18,
                  color: const Color.fromARGB(255, 96, 95, 95),
                ),
              ),
              SizedBox(height: 10),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('projects')
                    .doc(projectId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    dynamic projectDeadline = snapshot.data!['deadline'];
                    String deadlineText = projectDeadline is int
                        ? 'Deadline: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(projectDeadline))}'
                        : projectDeadline ?? 'No deadline';

                    return Text(
                      deadlineText,
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color.fromARGB(255, 76, 75, 75),
                      ),
                    );
                  }

                  return SizedBox.shrink();
                },
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFB8A0D6), // Darker Light Blue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Members:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            bool isTeamLead = await _isUserTeamLead(projectId);
                            if (isTeamLead) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditMembersPage(
                                    projectId: projectId,
                                    members: members,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Only accessible to team leads.',
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 255, 255, 255)),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Edit Members',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    FutureBuilder<List<Map<String, String>>>(
                      future: _fetchMemberDetails(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        List<Map<String, String>>? memberDetails =
                            snapshot.data;

                        return ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: memberDetails?.length ?? 0,
                          itemBuilder: (context, index) {
                            String memberName = memberDetails![index]['name']!;
                            String memberEmail = memberDetails[index]['email']!;
                            String memberRole = memberDetails[index]['role']!;
                            String memberInitial = memberName.isNotEmpty
                                ? memberName[0].toUpperCase()
                                : '';

                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(0, 64, 195, 255)
                                    .withOpacity(0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor:
                                        Color.fromARGB(255, 167, 76, 237),
                                    child: Text(
                                      memberInitial,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memberName,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        memberEmail,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color.fromARGB(
                                              255, 255, 254, 254),
                                        ),
                                      ),
                                      Text(
                                        memberRole,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFB8A0D6), // Darker Light Green

                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color.fromARGB(255, 16, 16, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('projects')
                          .doc(projectId)
                          .collection('tasks')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text('No tasks found for this project'));
                        }

                        return ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot taskDoc =
                                snapshot.data!.docs[index];
                            Task task = Task.fromMap(
                              taskDoc.data() as Map<String, dynamic>,
                              taskDoc.id,
                            );

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TaskDetailPage(task: task),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 5),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(0, 178, 255, 89)
                                      .withOpacity(0),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      task.desc ?? '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                      ),
                                    ),
                                    Text(
                                      'Deadline: ${task.deadline?.toLocal().toString().split(' ')[0] ?? 'No deadline'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFB8A0D6),
                  // Darker Light Purple // Darker Light Pink

                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Comments:',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 18, 18, 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CommentsPage(projectId: projectId),
                              ),
                            );
                          },
                          child: Text(
                            '+ comment',
                            style: TextStyle(fontSize: 16),
                            // Darker Light Purple
                          ),
                        ),
                      ],
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('projects')
                          .doc(projectId)
                          .collection('comments')
                          .orderBy('timestamp', descending: true)
                          .limit(2)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child:
                                  Text('No comments found for this project'));
                        }

                        List<DocumentSnapshot> commentDocs =
                            snapshot.data!.docs;

                        return Column(
                          children: [
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: commentDocs.length,
                              itemBuilder: (context, index) {
                                DocumentSnapshot commentDoc =
                                    commentDocs[index];
                                String commentText = commentDoc['comment'];
                                String commentAuthor = commentDoc['author'];
                                String commentAuthorFirstName = commentAuthor
                                    .split(' ')[0]; // Get the first name

                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(0, 255, 64, 128)
                                        .withOpacity(0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        commentAuthorFirstName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        commentText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color.fromARGB(
                                              255, 255, 255, 255),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (snapshot.data!.docs.length >= 2)
                              Align(
                                alignment:
                                    Alignment.centerRight, // Align to right
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CommentsPage(projectId: projectId),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    '... more',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color.fromARGB(255, 35, 30,
                                          39), // Change text color to black
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Project'),
          content: Text('Are you sure you want to delete this project?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteProject();
                Navigator.of(context).pop(); // Close the project details page
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProject() async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .delete();
    } catch (e) {
      print('Error deleting project: $e');
    }
  }

  Future<List<Map<String, String>>> _fetchMemberDetails() async {
    List<Map<String, String>> memberDetails = [];

    try {
      for (var member in members) {
        String memberId = member['id'];
        String role = member['role'];

        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(memberId)
            .get();

        String firstName = doc['firstName'];
        String lastName = doc['lastName'];
        String email = doc['email'];

        memberDetails.add({
          'name': '$firstName $lastName',
          'email': email,
          'role': role,
        });
      }

      return memberDetails;
    } catch (e) {
      print('Error fetching member details: $e');
      return [];
    }
  }
}

Future<bool> _isUserTeamLead(String projectId) async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();

      if (projectDoc.exists) {
        List<dynamic> members = projectDoc['members'];

        for (var member in members) {
          if (member['id'] == currentUser.uid &&
              member['role'] == 'Team Lead') {
            print('User is a Team Lead');
            return true;
          }
        }

        print('User is not a Team Lead');
      } else {
        print('Project document does not exist');
      }
    } else {
      print('No user is currently signed in');
    }
  } catch (e) {
    print('Error checking team lead status: $e');
  }
  return false;
}
