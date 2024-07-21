// ignore_for_file: camel_case_types, use_super_parameters, prefer_final_fields, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_crafter_app/constants/colors.dart';
import 'package:task_crafter_app/models/task.dart';
import 'create_project.dart'; // Import the new create_project page

class new_task extends StatefulWidget {
  const new_task({Key? key}) : super(key: key);

  @override
  State<new_task> createState() => _new_taskState();
}

class _new_taskState extends State<new_task> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _subTaskController = TextEditingController();
  List<SubTask> _subTasks = [];
  DateTime? _selectedDeadline; // Add this line
  String? _selectedProject; // Add this line to store selected project ID

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: he * 0.03,
              vertical: he * 0.01, // Adjusted top padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // No action needed as we are already on the Create Task page
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        backgroundColor: const Color.fromARGB(250, 244, 215, 215),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Create Task',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const CreateProjectPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.ease;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));

                              return SlideTransition(
                                position: animation.drive(tween),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        backgroundColor: const Color.fromARGB(255, 251, 235, 237),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Create Project',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: he * 0.03),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Create New Task',
                    style: TextStyle(
                      fontSize: 23,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.normal,
                      color: Colors.purple[300],
                    ),
                  ),
                ),
                SizedBox(height: he * 0.03),
                _buildNewTask(context),
                SizedBox(height: he * 0.03),
                _buildProjectSelector(context), // Add this line
                SizedBox(height: he * 0.03),
                _buildAddSubTasks(context),
                SizedBox(height: he * 0.03),
                _buildDeadlinePicker(context), // Add this line
                SizedBox(height: he * 0.05),
                _buildCreateTaskButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewTask(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Title',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Enter title',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Description',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(
              hintText: 'Enter description',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelector(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Project',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('projects').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No projects found for this user'));
              }

              List<DocumentSnapshot> userProjects =
                  snapshot.data!.docs.where((projectDoc) {
                List<dynamic> members = projectDoc['members'];

                // Debug print to check the structure of members
                print('Project members: $members');

                return members.any((member) {
                  // Ensure member is a map before accessing 'id'
                  if (member is Map<String, dynamic>) {
                    return member['id'] == _auth.currentUser!.uid;
                  }
                  return false;
                });
              }).toList();

              return DropdownButton<String>(
                isExpanded: true,
                value: _selectedProject,
                hint: const Text('Select a project'),
                items: userProjects.map((projectDoc) {
                  String projectId = projectDoc.id;
                  String projectTitle = projectDoc['title'];
                  return DropdownMenuItem(
                    value: projectId,
                    child: Text(projectTitle),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProject = value;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinePicker(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deadline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _selectedDeadline = picked;
                });
              }
            },
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 10),
                Text(
                  _selectedDeadline == null
                      ? 'Select Deadline'
                      : 'Deadline: ${_selectedDeadline!.toLocal()}'
                          .split(' ')[0],
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedDeadline != null)
            Text(
              'Selected Deadline: ${_selectedDeadline!.toLocal()}'
                  .split(' ')[0],
              style: const TextStyle(fontSize: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildAddSubTasks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subtasks',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subTasks.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_subTasks[index].title),
                trailing: Checkbox(
                  value: _subTasks[index].isCompleted,
                  onChanged: (bool? value) {
                    setState(() {
                      _subTasks[index].isCompleted = value ?? false;
                    });
                  },
                ),
              );
            },
          ),
          TextFormField(
            controller: _subTaskController,
            decoration: InputDecoration(
              hintText: 'Enter subtask',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    if (_subTaskController.text.isNotEmpty) {
                      _subTasks.add(SubTask(title: _subTaskController.text));
                      _subTaskController.clear();
                    }
                  });
                },
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTaskButton(BuildContext context) {
    return Center(
      child: Container(
        height: 40,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white, // Changed background color to white
          borderRadius: BorderRadius.circular(20),
        ),
        child: ElevatedButton(
          onPressed: _createTask,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black, // Changed text color to black
            backgroundColor: const Color.fromARGB(250, 244, 215, 215),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Create Task',
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createTask() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      // Handle user not signed in
      return;
    }

    if (_selectedProject == null) {
      // Handle no project selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }

    Task newTask = Task(
      title: _titleController.text,
      desc: _descController.text,
      bgColor: kBlue,
      textColor: Colors.black,
      subTasks: _subTasks,
      progress: 0, // Assuming progress starts at 0
      deadline: _selectedDeadline,
    );

    try {
      DocumentReference docRef = await _firestore
          .collection('projects')
          .doc(_selectedProject)
          .collection('tasks')
          .add({
        'userId': user.uid,
        'projectId': _selectedProject, // Store projectId
        'title': newTask.title,
        'desc': newTask.desc,
        'bgColor': newTask.bgColor.value,
        'textColor': newTask.textColor.value,
        'subTasks': newTask.subTasks
            .map((subTask) => {
                  'title': subTask.title,
                  'isCompleted': subTask.isCompleted,
                })
            .toList(),
        'progress': newTask.progress,
        'deadline': _selectedDeadline?.millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Assign taskId to the newly created task
      newTask.taskId = docRef.id;

      // Update the task with the assigned taskId in Firestore
      await docRef.update({'taskId': newTask.taskId});

      _titleController.clear();
      _descController.clear();
      _subTaskController.clear();
      _subTasks.clear();
      _selectedDeadline = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task created successfully')),
      );

      setState(() {});

      // Optionally navigate to a different screen or show a success message
    } catch (e) {
      print('Error creating task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to create task. Please try again later.')),
      );
      // Handle error
    }
  }
}
