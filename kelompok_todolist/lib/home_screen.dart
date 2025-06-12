import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kelompok_todolist/auth_service.dart';
import 'package:kelompok_todolist/signin_screen.dart';

class TodoItem {
  String title;
  bool isCompleted;
  String id;

  TodoItem({required this.title, this.isCompleted = false, this.id = ''});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TodoItem> todoList = [];
  final TextEditingController _controller = TextEditingController();
  int updateIndex = -1;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  void _signOut(BuildContext context) async {
    await AuthService().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  Future<void> fetchTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .orderBy('createdAt', descending: false)
        .get();

    setState(() {
      todoList = snapshot.docs.map((doc) {
        return TodoItem(
          id: doc.id,
          title: doc['title'].toString(),
          isCompleted: doc.data().containsKey('isCompleted') ? doc['isCompleted'] : false,
        );
      }).toList();
    });
  }

  void addList(String task) async {
    if (task.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .add({
          'title': task,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

    setState(() {
      todoList.add(TodoItem(id: docRef.id, title: task, isCompleted: false));
      _controller.clear();
    });
  }

  void deleteItem(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .doc(todoList[index].id)
        .delete();

    setState(() {
      todoList.removeAt(index);
    });
  }

  void toggleTaskCompletion(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newStatus = !todoList[index].isCompleted;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .doc(todoList[index].id)
        .update({'isCompleted': newStatus});

    setState(() {
      todoList[index].isCompleted = newStatus;
    });
  }

  void updateListItem(String task, int index) async {
    if (task.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todos')
        .doc(todoList[index].id)
        .update({'title': task});

    setState(() {
      todoList[index].title = task;
      updateIndex = -1;
      _controller.clear();
    });
  }

  int get completedTasksCount => todoList.where((task) => task.isCompleted).length;
  int get totalTasks => todoList.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 251, 247),
      appBar: AppBar(
        title: const Text(
          "🗓️ Todo Application",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 119, 48),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 119, 48),
                    Color.fromARGB(255, 255, 159, 107),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 255, 119, 48).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Progress",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$completedTasksCount/$totalTasks",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: totalTasks > 0 ? completedTasksCount / totalTasks : 0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalTasks > 0 
                        ? "${((completedTasksCount / totalTasks) * 100).toInt()}% completed"
                        : "No tasks yet",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Section Header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Tasks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 66, 66, 66),
                    ),
                  ),
                  if (todoList.isNotEmpty)
                    Text(
                      "${todoList.length} tasks",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

            // Task List
            Expanded(
              child: todoList.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No tasks yet!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add your first task below",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: todoList.length,
                      itemBuilder: (context, index) {
                        final todo = todoList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: todo.isCompleted 
                                        ? Colors.green 
                                        : const Color.fromARGB(255, 255, 119, 48),
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Checkbox
                                    GestureDetector(
                                      onTap: () => toggleTaskCompletion(index),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: todo.isCompleted 
                                              ? Colors.green 
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: todo.isCompleted 
                                                ? Colors.green 
                                                : Colors.grey,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: todo.isCompleted
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Task Text
                                    Expanded(
                                      child: Text(
                                        todo.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: todo.isCompleted 
                                              ? Colors.grey[500] 
                                              : const Color.fromARGB(255, 66, 66, 66),
                                          decoration: todo.isCompleted 
                                              ? TextDecoration.lineThrough 
                                              : TextDecoration.none,
                                        ),
                                      ),
                                    ),

                                    // Action Buttons
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _controller.clear();
                                              _controller.text = todo.title;
                                              updateIndex = index;
                                            });
                                          },
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue[600],
                                            size: 20,
                                          ),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () => deleteItem(index),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red[600],
                                            size: 20,
                                          ),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Task Input Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: updateIndex != -1 ? 'Update task...' : 'Add new task...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 255, 119, 48),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(255, 250, 250, 250),
                      ),
                      style: const TextStyle(fontSize: 16),
                      onSubmitted: (value) {
                        updateIndex != -1
                            ? updateListItem(_controller.text, updateIndex)
                            : addList(_controller.text);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 255, 119, 48),
                          Color.fromARGB(255, 255, 159, 107),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 255, 119, 48).withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        updateIndex != -1
                            ? updateListItem(_controller.text, updateIndex)
                            : addList(_controller.text);
                      },
                      icon: Icon(
                        updateIndex != -1 ? Icons.check : Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}