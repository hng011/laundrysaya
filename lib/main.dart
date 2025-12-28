import 'package:flutter/material.dart';
import 'laundry_item.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaundrySaya',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LaundryTrackerScreen(),
    );
  }
}

class LaundryTrackerScreen extends StatefulWidget {
  const LaundryTrackerScreen({super.key});

  @override
  State<LaundryTrackerScreen> createState() => _LaundryTrackerScreenState();
}

class _LaundryTrackerScreenState extends State<LaundryTrackerScreen> {
  // This list holds the data we fetch from the DB
  List<LaundryItem> laundryList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshLaundryList();
  }

  // Fetch data from SQLite
  Future<void> _refreshLaundryList() async {
    setState(() => isLoading = true);
    laundryList = await DatabaseHelper.instance.readAllItems();
    setState(() => isLoading = false);
  }

  // Add a new item to DB
  Future<void> _addItem(String name) async {
    final newItem = LaundryItem(name: name, count: 0);
    await DatabaseHelper.instance.create(newItem);
    _refreshLaundryList();
  }

  // Update item count in DB
Future<void> _updateCount(LaundryItem item, int change) async {
    // If count is 0 and user tries to decrease, ask to delete
    if (item.count == 0 && change == -1) {
      _showDeleteConfirmation(item);
      return; 
    }

    int newCount = item.count + change;
    if (newCount < 0) return; // Prevent negative numbers if logic slips through

    final updatedItem = LaundryItem(
      id: item.id,
      name: item.name,
      count: newCount,
    );
    await DatabaseHelper.instance.update(updatedItem);
    _refreshLaundryList();
  }

  void _showDeleteConfirmation(LaundryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${item.name}?'),
        content: const Text('The count is 0. Do you want to remove this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Just close dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // 1. Delete from DB
              // Note: item.id! is safe here because items from DB always have an ID
              await DatabaseHelper.instance.delete(item.id!); 
              
              // 2. Close the dialog
              Navigator.pop(context);
              
              // 3. Refresh the list to remove the item from the screen
              _refreshLaundryList();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Show a popup dialog to enter item name
  void _showAddDialog() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stuff'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: "e.g., Jeans"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                _addItem(_controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('laundrysaya'),
        backgroundColor: Colors.blue.shade100,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Row
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: const [
                      Expanded(
                          flex: 2,
                          child: Text('laundrian',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18))),
                      Expanded(
                          flex: 1,
                          child: Center(
                              child: Text('total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)))),
                      Expanded(flex: 1, child: SizedBox()), // Spacer for buttons
                    ],
                  ),
                ),
                const Divider(height: 1),

                // The List of Items
                Expanded(
                  child: laundryList.isEmpty
                      ? const Center(child: Text("No items yet. Add some!"))
                      : ListView.builder(
                          itemCount: laundryList.length,
                          itemBuilder: (context, index) {
                            final item = laundryList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Item Name
                                    Expanded(
                                      flex: 2,
                                      child: Text(item.name,
                                          style: const TextStyle(fontSize: 16)),
                                    ),
                                    // Count
                                    Expanded(
                                      flex: 1,
                                      child: Center(
                                          child: Text('${item.count}',
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold))),
                                    ),
                                    // + and - Buttons
                                    Expanded(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            onTap: () => _updateCount(item, -1),
                                            child: const Icon(Icons.remove_circle,
                                                color: Colors.red),
                                          ),
                                          const SizedBox(width: 15),
                                          InkWell(
                                            onTap: () => _updateCount(item, 1),
                                            child: const Icon(Icons.add_circle,
                                                color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // "Add Stuff" Button Area
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Stuff"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}