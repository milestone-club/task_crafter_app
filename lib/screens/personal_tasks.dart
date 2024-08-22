import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_personal_task_page.dart';
import 'package:intl/intl.dart';

class PersonalTasks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(''),
        ),
        body: Center(
          child: Text('No user logged in.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF1F4F8),
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Color(0xFFF1F4F8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Tasks',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('createdBy', isEqualTo: currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final data = task.data() as Map<String, dynamic>;
                      final title = data['title'];
                      final isCompleted = data.containsKey('isCompleted')
                          ? data['isCompleted']
                          : false;
                      final deadline = data['deadline'] != null
                          ? (data['deadline']).toDate()
                          : null;

                      return TaskItem(
                        title: title,
                        deadline: deadline,
                        isCompleted: isCompleted,
                        onChanged: (value) {
                          task.reference.update({'isCompleted': value});
                        },
                        onDelete: () {
                          task.reference.delete();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 50,
        height: 50,
        margin:
            EdgeInsets.only(bottom: 16), // Increase bottom margin for spacing
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey
                  .withOpacity(0.8), // increased opacity for more visibility
              spreadRadius: 2, // spread radius
              blurRadius: 5, // blur radius
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
          gradient: LinearGradient(
            colors: [Colors.blue[100]!, Colors.blue[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to the new task creation page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreatePersonalTaskPage(),
              ),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final String title;
  final DateTime? deadline;
  final bool isCompleted;
  final Function(bool?)? onChanged;
  final Function()? onDelete;

  const TaskItem({
    required this.title,
    this.deadline,
    required this.isCompleted,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isCompleted,
                onChanged: onChanged,
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.grey),
                onPressed: onDelete,
              ),
            ],
          ),
          if (deadline != null)
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Text(
                'Deadline: ${DateFormat.yMMMMd().format(deadline!)}',
                style: TextStyle(
                  color: Colors.grey,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
