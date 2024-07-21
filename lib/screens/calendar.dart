// ignore_for_file: depend_on_referenced_packages, unused_field, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:task_crafter_app/models/task.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final user = FirebaseAuth.instance.currentUser;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _tasks = [];
  final List<Map<String, dynamic>> _deadlines = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    if (user == null) return;

    List<Task> allTasks = [];

    // Fetch tasks from the main 'tasks' collection
    final QuerySnapshot mainTasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: user!.uid)
        .get();

    allTasks.addAll(mainTasksSnapshot.docs.map((doc) {
      return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList());

    // Fetch all projects
    final QuerySnapshot projectsSnapshot =
        await FirebaseFirestore.instance.collection('projects').get();

    // Fetch tasks from the 'tasks' sub-collections within each project where 'userId' matches the current user's ID
    for (var projectDoc in projectsSnapshot.docs) {
      final QuerySnapshot projectTasksSnapshot = await FirebaseFirestore
          .instance
          .collection('projects')
          .doc(projectDoc.id)
          .collection('tasks')
          .where('userId', isEqualTo: user!.uid)
          .get();

      allTasks.addAll(projectTasksSnapshot.docs.map((doc) {
        return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList());
    }

    if (mounted) {
      setState(() {
        _tasks = allTasks;
      });
    }
  }

  List<Task> _getTasksForSelectedDay() {
    return _tasks.where((task) {
      return task.deadline != null && isSameDay(task.deadline, _selectedDay);
    }).toList();
  }

  List<Task> _getNearestUpcomingDeadlines() {
    final now = DateTime.now();
    List<Task> upcomingTasks = _tasks.where((task) {
      return task.deadline != null && task.deadline!.isAfter(now);
    }).toList();

    // Sort tasks by deadline date
    upcomingTasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));

    // Return the two nearest deadlines
    return upcomingTasks.take(2).toList();
  }

  Widget _buildTask(BuildContext context, Task task) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: task.bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            task.desc ?? '',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 10),
          Text(
            'Deadline: ${task.deadline != null ? DateFormat.yMMMd().format(task.deadline!) : 'No deadline'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: task.percent / 100,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var he = MediaQuery.of(context).size.height;
    var tasksForSelectedDay = _getTasksForSelectedDay();
    var nearestUpcomingDeadlines = _getNearestUpcomingDeadlines();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Calendar',
          style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.purple[300],
              fontSize: 23),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: he * 0.03,
              right: he * 0.03,
              bottom: he * 0.05,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: he * 0.00),
                Text(
                  'Selected Day = ${_selectedDay?.toString().split(' ')[0] ?? ''}',
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.purple[300],
                  ),
                ),
                SizedBox(height: he * 0.00),
                Container(
                  padding: const EdgeInsets.all(15.0),
                  child: TableCalendar(
                    locale: 'en_US',
                    rowHeight: 35,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    availableGestures: AvailableGestures.all,
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    focusedDay: _focusedDay,
                    firstDay: DateTime.utc(2010, 10, 16),
                    lastDay: DateTime.utc(2040, 3, 14),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                ),
                SizedBox(height: he * 0.02),
                if (tasksForSelectedDay.isNotEmpty) ...[
                  Text(
                    'Tasks for Selected Day',
                    style: TextStyle(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: Colors.purple[300],
                    ),
                  ),
                  SizedBox(height: he * 0.01),
                  ...tasksForSelectedDay.map((task) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: _buildTask(
                            context, task), // Use the local _buildTask method
                      )),
                ],
                SizedBox(height: he * 0.02),
                if (nearestUpcomingDeadlines.isNotEmpty) ...[
                  Text(
                    'Upcoming Deadlines',
                    style: TextStyle(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: Colors.purple[300],
                    ),
                  ),
                  SizedBox(height: he * 0.01),
                  ...nearestUpcomingDeadlines.map((task) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: _buildTask(
                            context, task), // Use the local _buildTask method
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Any necessary cleanup code can be added here.
    super.dispose();
  }
}
