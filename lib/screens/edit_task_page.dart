import 'package:flutter/material.dart';
import 'package:task_crafter_app/models/task.dart';

class EditTaskPage extends StatefulWidget {
  final Task task;

  EditTaskPage({required this.task});

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.desc);
    _selectedDeadline = widget.task.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // Save the edited task details
              widget.task.title = _titleController.text;
              widget.task.desc = _descController.text;
              widget.task.deadline = _selectedDeadline;

              // Return the updated task to the previous page
              Navigator.pop(context, widget.task);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16),
            Text(
              'Deadline: ${_selectedDeadline != null ? _selectedDeadline!.toLocal().toString().split(' ')[0] : 'No deadline'}',
            ),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('Select Deadline'),
            ),
          ],
        ),
      ),
    );
  }
}
