import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreatePersonalTaskPage extends StatefulWidget {
  @override
  _CreatePersonalTaskPageState createState() => _CreatePersonalTaskPageState();
}

class _CreatePersonalTaskPageState extends State<CreatePersonalTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _pickDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDeadline) {
      setState(() {
        _selectedDeadline = pickedDate;
      });
    }
  }

  void _createTask() async {
    String uid = _auth.currentUser?.uid ?? '';

    if (_titleController.text.isEmpty || _selectedDeadline == null) {
      // Show an error message if title or deadline is not set
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title and select a deadline.')),
      );
      return;
    }

    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');

    await tasks.add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'deadline': _selectedDeadline,
      'createdBy': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isCompleted': false, // Ensure this line is included
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF1F4F8),
        elevation: 0,
        title: Text(
          'Create Personal Task',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Deadline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _selectedDeadline == null
                    ? 'No date chosen!'
                    : DateFormat.yMMMMd().format(_selectedDeadline!),
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () => _pickDeadline(context),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _createTask,
                child: Text(
                  'Create task',
                  style: TextStyle(
                      color: const Color.fromARGB(255, 255, 255, 255)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 162, 146, 236),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
