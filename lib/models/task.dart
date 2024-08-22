import 'package:flutter/material.dart';

class Task {
  String? id; // Firebase document ID
  String? taskId; // Task ID
  String? title;
  String? desc;
  Color bgColor;
  Color textColor;
  num percent;
  double progress;
  bool isLast;
  DateTime? deadline;
  List<SubTask> subTasks;
  String? projectId; // Project ID

  Task({
    this.id,
    this.taskId, // Initialize taskId
    this.title,
    this.desc,
    this.bgColor = Colors.red,
    this.textColor = Colors.black,
    this.percent = 0,
    this.progress = 0.0,
    this.isLast = false,
    this.deadline,
    this.subTasks = const [],
    this.projectId,
  });

  void calculateProgress() {
    if (subTasks.isEmpty) {
      percent = 0;
    } else {
      int completed = subTasks.where((subTask) => subTask.isCompleted).length;
      percent = (completed / subTasks.length) * 100;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId, // Include taskId in map
      'title': title,
      'desc': desc,
      'bgColor': bgColor.value,
      'textColor': textColor.value,
      'percent': percent,
      'isLast': isLast,
      'deadline': deadline != null ? deadline!.millisecondsSinceEpoch : null,
      'subTasks': subTasks.map((subTask) => subTask.toMap()).toList(),
      'projectId': projectId,
    };
  }

  static Task fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      taskId: map['taskId'] as String?, // Initialize taskId from map
      title: map['title'] as String?,
      desc: map['desc'] as String?,
      bgColor: map['bgColor'] != null ? Color(map['bgColor']) : Colors.red,
      textColor:
          map['textColor'] != null ? Color(map['textColor']) : Colors.black,
      percent: map['percent'] ?? 0,
      isLast: map['isLast'] ?? false,
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
      subTasks: (map['subTasks'] as List<dynamic>?)
              ?.map(
                  (subTask) => SubTask.fromMap(subTask as Map<String, dynamic>))
              .toList() ??
          [],
      projectId: map['projectId'] as String?,
    );
  }
}

class SubTask {
  String title;
  bool isCompleted;

  SubTask({required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  static SubTask fromMap(Map<String, dynamic> map) {
    return SubTask(
      title: map['title'] as String,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
