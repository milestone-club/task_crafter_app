// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api, avoid_print, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_crafter_app/models/task.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;

  TaskDetailPage({required this.task});

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _toggleSubTaskCompletion(int index) {
    setState(() {
      // Toggle the completion status of the sub-task
      widget.task.subTasks[index].isCompleted =
          !widget.task.subTasks[index].isCompleted;

      // Recalculate the overall progress of the task
      widget.task.calculateProgress();

      // Update the task in the projects sub-collection
      _updateProjectTask(widget.task);
    });
  }

  Future<void> _updateProjectTask(Task task) async {
    try {
      // Update the task in the projects sub-collection
      await _firestore
          .collection('projects')
          .doc(task.projectId)
          .collection('tasks')
          .doc(task.taskId)
          .update(task.toMap());
      print('Task updated in project tasks sub-collection');
    } catch (e) {
      print('Error updating task in project tasks sub-collection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title ?? 'Task Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title ?? '',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.task.desc ?? '',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Deadline: ${widget.task.deadline != null ? widget.task.deadline!.toLocal().toString().split(' ')[0] : 'No deadline'}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: widget.task.percent / 100,
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.task.subTasks.length,
                itemBuilder: (context, index) {
                  final subTask = widget.task.subTasks[index];
                  return CheckboxListTile(
                    title: Text(subTask.title),
                    value: subTask.isCompleted,
                    onChanged: (bool? value) {
                      _toggleSubTaskCompletion(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
