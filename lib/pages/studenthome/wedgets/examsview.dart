import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_444/pages/studenthome/wedgets/StudentExamWidget.dart';
import 'package:project_444/pages/studenthome/wedgets/studentexamsession.dart';

class StudentExam extends StatefulWidget {
  const StudentExam({Key? key}) : super(key: key);

  @override
  _StudentExamState createState() => _StudentExamState();
}

class _StudentExamState extends State<StudentExam> {
  late List<Timer> _timers;

  @override
  void initState() {
    super.initState();
    _timers = []; // Initialize the list of timers
  }

  @override
  void dispose() {
    // Cancel all timers when the widget is disposed
    for (var timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exams')
          .where('endDate', isGreaterThan: DateTime.now().toIso8601String())
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No uncompleted exams found.',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        final now = DateTime.now();
        final exams = snapshot.data!.docs.where((doc) {
          final examData = doc.data() as Map<String, dynamic>;
          final startDate = DateTime.parse(examData['startDate']);
          // Only show exams that have not started yet or are starting now
          return now.subtract(Duration(days: 1)).isBefore(startDate);
        }).toList();

        if (exams.isEmpty) {
          return const Center(
            child: Text(
              'There are no upcoming exams.',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        // Set timers dynamically based on each exam's start time
        _setTimers(exams, now);

        return ListView.builder(
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final examData = exams[index].data() as Map<String, dynamic>;
            final examId = exams[index].id; // Firestore document ID
            final startDate = DateTime.parse(examData['startDate']);
            final endDate = DateTime.parse(examData['endDate']);
            final examName = examData['examName'] ?? 'Unnamed Exam';
            final attempts = examData['attempts'] ?? 0;
            final duration = examData['duration'] ?? 0;

            return StudentExamWidget(
              examId: examId,
              examName: examName,
              startDate: startDate,
              endDate: endDate,
              attempts: attempts,
              duration: duration,
              onTap: () {
                _handleExamTap(
                  examId,
                  context,
                  examName,
                  startDate,
                  endDate,
                  duration,
                );
              },
            );
          },
        );
      },
    );
  }

  void _setTimers(List<QueryDocumentSnapshot> exams, DateTime now) {
    for (var timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    for (var exam in exams) {
      final examData = exam.data() as Map<String, dynamic>;
      final startDate = DateTime.parse(examData['startDate']);
      final difference = startDate.difference(now).inSeconds;

      if (difference > 0) {
        final timer = Timer(Duration(seconds: difference), () {
          if (mounted) {
            setState(() {
              // Update the state if required.
            });
          }
        });
        _timers.add(timer);
      }
    }
  }

  void _handleExamTap(String examId, BuildContext context, String examName,
      DateTime startDate, DateTime endDate, int duration) {
    final now = DateTime.now();

    if (now.isAfter(startDate) && now.isBefore(endDate)) {
      _showBottomSheet(context, examName, duration, examId);
    } else {
      _showDialog(context, 'Exam Unavailable',
          'The exam is not available for interaction yet or has expired.');
    }
  }

  void _showBottomSheet(
      BuildContext context, String title, int duration, String examId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'You will have $duration minutes to solve the exam. Make sure you are ready before starting.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showConfirmationDialog(context, examId);
                },
                child: const Text('Start Exam'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, String examId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you want to start the exam now?'),
          actions: <Widget>[
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StudentExamSession(examId: examId),
                      ),
                    );
                  },
                  child: const Text('Start Exam'),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
