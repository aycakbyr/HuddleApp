import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'user_profile_page.dart';

class FollowListPage extends StatefulWidget {
    final String userId;
    final bool showFollowers; // true: takipçiler, false: takip edilenler
    final String title;

    const FollowListPage({
        super.key,
        required this.userId,
        required this.showFollowers,
        required this.title,
    });

    @override
    State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
    final _userService = UserService();
    List<Map<String, dynamic>> _users = [];
    bool _isLoading = true;
    String? _errorMessage;

    @override
    void initState() {
        super.initState();
        _load();
    }

    Future<void> _load() async {
        try {
            final users = widget.showFollowers
                ? await _userService.getFollowers(widget.userId)
                : await _userService.getFollowing(widget.userId);
            if (!mounted) return;
            setState(() {
                _users = users;
                _isLoading = false;
            });
        } catch (e) {
            if (!mounted) return;
            setState(() {
                _errorMessage = 'Liste yüklenemedi.';
                _isLoading = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: Text(
                    widget.title,
                    style: const TextStyle(color: Color(0xFF1A237E), fontSize: 18),
                ),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _users.isEmpty
                        ? Center(
                            child: Text(
                                widget.showFollowers ? 'Henüz takipçi yok.' : 'Henüz kimseyi takip etmiyor.',
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                        )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _users.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                                final u = _users[i];
                                final displayName = u['displayName'] ?? '?';
                                return Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                        leading: CircleAvatar(
                                            backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                            child: Text(
                                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                                style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold),
                                            ),
                                        ),
                                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: u['username'] != null ? Text('@${u['username']}') : null,
                                        onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) => UserProfilePage(userId: u['id']),
                                                ),
                                            );
                                        },
                                    ),
                                );
                            },
                        ),
        );
    }
}