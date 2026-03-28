import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// ================= HOME SCREEN =================

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box taskBox;

  String searchQuery = "";
  String filterStatus = "All";

  @override
  void initState() {
    super.initState();
    taskBox = Hive.box('tasksBox');
  }

  List getFilteredTasks(Box box) {
    List tasks = box.values.toList();

    if (searchQuery.isNotEmpty) {
      tasks = tasks.where((task) {
        return task['title']
            .toLowerCase()
            .contains(searchQuery.toLowerCase());
      }).toList();
    }

    if (filterStatus != "All") {
      tasks = tasks.where((task) {
        return task['status'] == filterStatus;
      }).toList();
    }

    return tasks;
  }

  void toggleTaskStatus(int index, Map task) {
    String newStatus = task['status'] == "Done" ? "To-Do" : "Done";

    taskBox.putAt(index, {
      ...task,
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Task Manager")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Hello Naveen 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            SizedBox(height: 10),

            DropdownButton<String>(
              value: filterStatus,
              isExpanded: true,
              items: ["All", "To-Do", "In Progress", "Done"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text("Filter: $e"),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  filterStatus = value!;
                });
              },
            ),

            SizedBox(height: 10),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: taskBox.listenable(),
                builder: (context, Box box, _) {
                  var tasks = getFilteredTasks(box);

                  if (tasks.isEmpty) {
                    return Center(child: Text("No matching tasks"));
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      var task = tasks[index];

                      bool isDone = task['status'] == "Done";

                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Checkbox(
                            value: isDone,
                            onChanged: (value) {
                              toggleTaskStatus(index, task);
                            },
                          ),
                          title: Text(
                            task['title'],
                            style: TextStyle(
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text(
                            "${task['status']} • ${task['dueDate']}",
                          ),

                          // 👉 TAP TO EDIT
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditTaskScreen(
                                  task: task,
                                  index: index,
                                ),
                              ),
                            );
                          },

                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              box.deleteAt(index);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTaskScreen()),
          );
        },
      ),
    );
  }
}

// ================= ADD TASK =================

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  String status = "To-Do";
  DateTime selectedDate = DateTime.now();

  final box = Hive.box('tasksBox');

  void saveTask() {
    box.add({
      'title': titleController.text,
      'description': descController.text,
      'dueDate': selectedDate.toString(),
      'status': status,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Task")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: "Title")),
            TextField(controller: descController, decoration: InputDecoration(labelText: "Description")),

            DropdownButton<String>(
              value: status,
              isExpanded: true,
              items: ["To-Do", "In Progress", "Done"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => status = value!),
            ),

            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Text("Pick Date"),
            ),

            ElevatedButton(onPressed: saveTask, child: Text("Save Task")),
          ],
        ),
      ),
    );
  }
}

// ================= EDIT TASK =================

class EditTaskScreen extends StatefulWidget {
  final Map task;
  final int index;

  EditTaskScreen({required this.task, required this.index});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController descController;

  late String status;
  late DateTime selectedDate;

  final box = Hive.box('tasksBox');

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.task['title']);
    descController = TextEditingController(text: widget.task['description']);

    status = widget.task['status'];
    selectedDate = DateTime.parse(widget.task['dueDate']);
  }

  void updateTask() {
    box.putAt(widget.index, {
      'title': titleController.text,
      'description': descController.text,
      'dueDate': selectedDate.toString(),
      'status': status,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Task")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController),
            TextField(controller: descController),

            DropdownButton<String>(
              value: status,
              isExpanded: true,
              items: ["To-Do", "In Progress", "Done"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => status = value!),
            ),

            ElevatedButton(
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              child: Text("Update Date"),
            ),

            ElevatedButton(
              onPressed: updateTask,
              child: Text("Update Task"),
            ),
          ],
        ),
      ),
    );
  }
}