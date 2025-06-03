import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'sidebarnavbar.dart';

class ManageAIChatsPage extends StatefulWidget {
  const ManageAIChatsPage({super.key});

  @override
  State<ManageAIChatsPage> createState() => _ManageAIChatsPageState();
}

class _ManageAIChatsPageState extends State<ManageAIChatsPage> {
  String searchProfileId = '';
  DateTime? startDate;
  DateTime? endDate;
  int pageSize = 10;
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  List<DocumentSnapshot> loadedDocs = [];

  Future<void> fetchChats({bool reset = false}) async {
    setState(() => isLoading = true);
    Query query = FirebaseFirestore.instance.collection('ai_chats').orderBy('dateTime', descending: true);

    if (searchProfileId.isNotEmpty) {
      query = query.where('profileId', isEqualTo: searchProfileId);
    }

    if (startDate != null && endDate != null) {
      query = query
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate!));
    }

    if (!reset && lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    final snapshot = await query.limit(pageSize).get();
    if (reset) loadedDocs.clear();
    if (snapshot.docs.isNotEmpty) {
      lastDocument = snapshot.docs.last;
      loadedDocs.addAll(snapshot.docs);
    }
    setState(() => isLoading = false);
  }

  Future<void> pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      await fetchChats(reset: true);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchChats(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SidebarNavbar(currentRoute: '/manage_ai_chats'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage AI Chats', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Search by Profile ID'),
                          onChanged: (val) => setState(() => searchProfileId = val.trim()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: const Text('Pick Date Range'),
                        onPressed: pickDateRange,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => fetchChats(reset: true),
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isLoading) const LinearProgressIndicator(),
                  Expanded(
                    child: loadedDocs.isEmpty
                        ? const Center(child: Text('No chat entries found'))
                        : ListView.separated(
                      itemCount: loadedDocs.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final doc = loadedDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return ExpansionTile(
                          title: Text(data['chats'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Profile ID: ${data['profileId'] ?? ''}'),
                              Text('Role: ${data['role'] ?? 'user'}'),
                              Text('Date/Time: ${data['dateTime'] ?? ''}'),
                              Text('Chat ID: ${data['chatsID'] ?? ''}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.archive, color: Colors.blue),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('ai_chats').doc(doc.id).update({'archived': true});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('ai_chats').doc(doc.id).delete();
                                },
                              ),
                            ],
                          ),
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, bottom: 8),
                              child: Text('Responses / Threads view not implemented yet.'),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                  if (!isLoading && loadedDocs.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: fetchChats,
                        icon: const Icon(Icons.navigate_next),
                        label: const Text('Load More'),
                      ),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
