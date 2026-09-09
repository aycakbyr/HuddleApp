import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'direct_chat_page.dart';

class NewMessagePage extends StatefulWidget {
    const NewMessagePage({super.key});

    @override
    State<NewMessagePage> createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
    final _userService = UserService();
    List<Map<String, dynamic>> _results = [];
    bool _isSearching = false;

    Future<void> _search(String query) async {
        if (query.trim().isEmpty) {
            setState(() => _results = []);
            return;
        }

        setState(() => _isSearching = true);
        final results = await _userService.searchUsers(query);
        if (!mounted) return;
        setState(() {
            _results = results;
            _isSearching = false;
        });
    }

    void _openChat(String otherUserId) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DirectChatPage(otherUserId: otherUserId)),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text('Yeni Mesaj', style: TextStyle(color: Color(0xFF1A237E))),
            ),
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        TextField(
                            autofocus: true,
                            onChanged: _search,
                            decoration: InputDecoration(
                                hintText: 'İsim veya kullanıcı adı ara...',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                ),
                            ),
                        ),
                        const SizedBox(height: 16),
                        if (_isSearching)
                            const Center(child: CircularProgressIndicator())
                        else
                            Expanded(
                                child: _results.isEmpty
                                    ? const Center(child: Text('Kullanıcı aramak için yukarıya yazmaya başla.', style: TextStyle(color: Colors.grey)))
                                    : ListView.builder(
                                        itemCount: _results.length,
                                        itemBuilder: (context, index) {
                                            final user = _results[index];
                                            return ListTile(
                                                leading: CircleAvatar(
                                                    backgroundColor: const Color(0xFF1A237E),
                                                    backgroundImage: user['profilePictureUrl'] != null
                                                        ? NetworkImage(user['profilePictureUrl'])
                                                        : null,
                                                    child: user['profilePictureUrl'] == null
                                                        ? const Icon(Icons.person, color: Colors.white)
                                                        : null,
                                                ),
                                                title: Text(user['displayName']),
                                                subtitle: Text('@${user['username']}'),
                                                onTap: () => _openChat(user['id']),
                                            );
                                        },
                                    ),
                            ),
                    ],
                ),
            ),
        );
    }
}
