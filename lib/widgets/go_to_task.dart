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
  final List<Color> colors = [
    Color(0xFFD49C9F), // Darker Light Pink
    Color(0xFF8AB0C4), // Darker Light Blue
    Color(0xFF9CC2B5), // Darker Light Green
    Color(0xFFF2B89A), // Darker Light Peach
    Color(0xFFB8A0D6), // Darker Light Purple
    Color(0xFFE7B3B4), // Darker Light Coral
    Color(0xFFF8E2A1), // Darker Light Yellow
  ];

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Color getColor(int index) {
    Color color = colors[index % colors.length];
    print('Assigning color $color to project at index $index'); // Debug print
    return color;
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
          return Center(
            child: Image.asset(
              'assets/images/notasksfound.jpg', // Corrected the image path
              fit: BoxFit.cover,
            ),
          );
        }

        List<DocumentSnapshot> userProjects =
            snapshot.data!.docs.where((projectDoc) {
          List<dynamic> members = projectDoc['members'];

          return members.any((member) {
            if (member is Map<String, dynamic>) {
              return member['id'] == widget.userId;
            }
            return false;
          });
        }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userProjects.isNotEmpty) {
            widget.setDefaultProjectId(userProjects.first.id);
          }
        });

        if (userProjects.isEmpty) {
          return Center(
            child: Image.asset(
              'assets/images/notasksfound.jpg', // Corrected the image path
              fit: BoxFit.cover,
            ),
          );
        }

        return SizedBox(
          height: 70,
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: userProjects.length,
            itemBuilder: (context, index) {
              DocumentSnapshot projectDoc = userProjects[index];
              String projectId = projectDoc.id;
              String projectTitle = projectDoc['title'];
              String projectDescription = projectDoc['desc'];
              dynamic projectDeadline = projectDoc['deadline'];
              List<dynamic> members = projectDoc['members'];

              String deadlineText = projectDeadline is int
                  ? 'Deadline: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(projectDeadline))}'
                  : projectDeadline ?? 'No deadline';

              return GestureDetector(
                onTap: () {
                  widget.onProjectSelected(projectId);
                },
                child: Container(
                  width: 270,
                  height: 100,
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: getColor(index),
                    borderRadius: BorderRadius.circular(40),
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
                          color: Colors.white,
                          fontSize: 16,
                        ),
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
