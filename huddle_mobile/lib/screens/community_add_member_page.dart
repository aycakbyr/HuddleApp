import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../utils/snackbar_helper.dart';

class CommunityAddMemberPage extends StatefulWidget {
    final String communityId;

    const CommunityAddMemberPage({super.key, required this.communityId});

    @override
    State<CommunityAddMemberPage> createState() => _CommunityAddMemberPageState();
}

class _CommunityAddMemberPageState extends State<CommunityAddMemberPage> {
    final _communityService = CommunityService();
    final _searchController = TextEditingController();
    List<Map<String, dynamic>> _results = [];
    bool _isSearching = false;
    final Set<String> _addingIds = {}; // eklenmekte olan kullanıcıların id'leri (loading göstermek için)

    @override
    void dispose() {
        _searchController.dispose();
        super.dispose();
    }

    Future<void> _search(String query) async {
        if (query.trim().isEmpty) {
            setState(() => _results = []);
            return;
        }
        setState(() => _isSearching = true);
        final results = await _communityService.searchUsersToAdd(widget.communityId, query);
        if (!mounted) return;
        setState(() {
            _results = results;
            _isSearching = false;
        });
    }

    Future<void> _addUser(String userId) async {
        setState(() => _addingIds.add(userId));
        final result = await _communityService.addMember(widget.communityId, userId);
        if (!mounted) return;
        setState(() => _addingIds.remove(userId));

        if (result['success'] == true) {
            setState(() {
                _results.removeWhere((u) => u['id'] == userId);
            });
            showAppSnackBar(context, 'Üye eklendi.');
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                title: const Text('Üye Ekle', style: TextStyle(color: Color(0xFF1A237E))),
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
            ),
            body: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    children: [
                        TextField(
                            controller: _searchController,
                            onChanged: _search,
                            decoration: InputDecoration(
                                hintText: 'İsim veya kullanıcı adı ara...',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                ),
                            ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                            child: _isSearching
                                ? const Center(child: CircularProgressIndicator())
                                : _results.isEmpty
                                    ? Center(
                                        child: Text(
                                            _searchController.text.trim().isEmpty
                                                ? 'Eklemek istediğin kişiyi ara.'
                                                : 'Sonuç bulunamadı.',
                                            style: const TextStyle(color: Colors.grey),
                                        ),
                                    )
                                    : ListView.builder(
                                        itemCount: _results.length,
                                        itemBuilder: (context, i) {
                                            final user = _results[i];
                                            final isAdding = _addingIds.contains(user['id']);
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
                                                trailing: isAdding
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                    )
                                                    : IconButton(
                                                        icon: const Icon(Icons.person_add, color: Color(0xFF1A237E)),
                                                        onPressed: () => _addUser(user['id']),
                                                    ),
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
