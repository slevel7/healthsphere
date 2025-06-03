import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sidebarnavbar.dart';

class ManageArticlesPage extends StatefulWidget {
  const ManageArticlesPage({Key? key}) : super(key: key);

  @override
  State<ManageArticlesPage> createState() => _ManageArticlesPageState();
}

class _ManageArticlesPageState extends State<ManageArticlesPage> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _sourceController = TextEditingController();
  final _linkController = TextEditingController();
  final _datetimeController = TextEditingController();

  String? editingId;
  String _searchQuery = '';
  String _filter = 'all'; // all | approved | unapproved

  @override
  void initState() {
    super.initState();
    _datetimeController.text = _nowString();
  }

  String _nowString() {
    final now = DateTime.now();
    return '${now.year}-${_pad(now.month)}-${_pad(now.day)} ${_pad(now.hour)}:${_pad(now.minute)}';
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  Future<void> _saveArticle() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'topic': _topicController.text.trim(),
      'source': _sourceController.text.trim(),
      'link': _linkController.text.trim(),
      'datetime': _datetimeController.text.trim(),
      'approved': false,
      'createdAt': Timestamp.now(),
    };

    try {
      if (editingId == null) {
        await FirebaseFirestore.instance.collection('articles').add(data);
      } else {
        await FirebaseFirestore.instance.collection('articles').doc(editingId).update(data);
      }
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  void _clearForm() {
    _topicController.clear();
    _sourceController.clear();
    _linkController.clear();
    _datetimeController.text = _nowString();
    setState(() => editingId = null);
  }

  void _editArticle(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    _topicController.text = d['topic'] ?? '';
    _sourceController.text = d['source'] ?? '';
    _linkController.text = d['link'] ?? '';
    _datetimeController.text = d['datetime'] ?? _nowString();
    setState(() => editingId = doc.id);
  }

  Future<void> _deleteArticle(String id) async {
    await FirebaseFirestore.instance.collection('articles').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SidebarNavbar(currentRoute: '/manage_articles'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage Articles', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildForm(),
                  const SizedBox(height: 20),
                  _buildFilterRow(),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  SizedBox(height: 600, child: _buildArticleList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Wrap(
            runSpacing: 12,
            children: [
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(labelText: 'Topic'),
                validator: (v) => v == null || v.isEmpty ? 'Enter topic' : null,
              ),
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(labelText: 'Source'),
                validator: (v) => v == null || v.isEmpty ? 'Enter source' : null,
              ),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(labelText: 'Link'),
                validator: (v) => v == null || v.isEmpty ? 'Enter link' : null,
              ),
              TextFormField(
                controller: _datetimeController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date & Time (auto)'),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saveArticle,
                    child: Text(editingId == null ? 'Add' : 'Update'),
                  ),
                  const SizedBox(width: 8),
                  if (editingId != null)
                    OutlinedButton(onPressed: _clearForm, child: const Text('Cancel')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        _chip('All', 'all'),
        _chip('Approved', 'approved'),
        _chip('Unapproved', 'unapproved'),
        const Spacer(),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('articles').snapshots(),
          builder: (ctx, snap) {
            final total = snap.data?.docs.length ?? 0;
            return Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.w600));
          },
        )
      ],
    );
  }

  ChoiceChip _chip(String label, String value) => ChoiceChip(
    label: Text(label),
    selected: _filter == value,
    onSelected: (_) => setState(() => _filter = value),
  );

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search by topic or source…',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildArticleList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('articles')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final topic = (d['topic'] ?? '').toString().toLowerCase();
          final source = (d['source'] ?? '').toString().toLowerCase();
          final approved = d['approved'] ?? false;
          final matchesSearch = topic.contains(_searchQuery) || source.contains(_searchQuery);
          final matchesFilter = _filter == 'all' ||
              (_filter == 'approved' && approved) ||
              (_filter == 'unapproved' && !approved);
          return matchesSearch && matchesFilter;
        }).toList();

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.article_outlined, color: Colors.indigo),
              title: Text(d['topic'] ?? 'Untitled'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d['link'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.blue)),
                  Text(d['datetime'] ?? '', style: const TextStyle(fontSize: 11)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _editArticle(doc)),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteArticle(doc.id)),
                  Switch(
                    value: d['approved'] ?? false,
                    onChanged: (val) => FirebaseFirestore.instance
                        .collection('articles')
                        .doc(doc.id)
                        .update({'approved': val}),
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
