import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _selectedDate;
  String _status = "To-Do";

  bool isLoading = false;

  Future<void> saveTask() async {
    if (_titleController.text.isEmpty || _selectedDate == null) return;

    setState(() {
      isLoading = true;
    });

    await Future.delayed(Duration(seconds: 2)); // REQUIRED

    final box = Hive.box('tasksBox');

    box.add({
      "title": _titleController.text,
      "description": _descController.text,
      "dueDate": _selectedDate.toString(),
      "status": _status,
      "blockedBy": null,
    });

    setState(() {
      isLoading = false;
    });

    Navigator.pop(context);
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Task")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickDate,
              child: Text(_selectedDate == null
                  ? "Select Due Date"
                  : _selectedDate.toString()),
            ),

            DropdownButton<String>(
              value: _status,
              items: ["To-Do", "In Progress", "Done"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _status = val!;
                });
              },
            ),

            SizedBox(height: 20),

            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveTask,
                    child: Text("Save Task"),
                  ),
          ],
        ),
      ),
    );
  }
}