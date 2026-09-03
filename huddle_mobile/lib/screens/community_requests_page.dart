import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../utils/snackbar_helper.dart';

// bir topluluğun yöneticisi için bekleyen katılım istekleri
class CommunityRequestsPage extends StatefulWidget {
    final String communityId;

    const CommunityRequestsPage({super.key, required this.communityId});

    @override
    State<CommunityRequestsPage> createState() => _CommunityRequestsPageState();
}

class _CommunityRequestsPageState extends State<CommunityRequestsPage> {
    final _communityService = CommunityService();
    List<Map<String, dynamic>> _requests = [];
    bool _isLoading = true;
    String? _errorMessage;
    final Set<String> _processingIds = {}; // aynı anda birden fazla istek olunca hangi isteklerin şuan işlemde olduğunu ayrı ayrı takip eder 

    @override
    void initState() {
        super.initState();
        _loadRequests();
    }

    Future<void> _loadRequests() async {
        setState(() {
            _isLoading = true;
            _errorMessage = null;
        });
        try {
            final requests = await _communityService.getPendingJoinRequests(widget.communityId);
            if (!mounted) return;
            setState(() {
                _requests = requests;
                _isLoading = false;
            });
        } catch (e) {
            if (!mounted) return;
            setState(() {
                _errorMessage = 'İstekler yüklenemedi.';
                _isLoading = false;
            });
        }
    }

    Future<void> _respond(Map<String, dynamic> request, bool approve) async {
        final requestId = request['requestId'] as String;
        setState(() => _processingIds.add(requestId));

        final result = await _communityService.respondToJoinRequest(
            widget.communityId,
            requestId,
            approve,
        );

        if (!mounted) return;
        setState(() => _processingIds.remove(requestId));

        if (result['success'] == true) {
            setState(() => _requests.removeWhere((r) => r['requestId'] == requestId)); // _respond başarılı olunca bunun ile listeden o isteği anında çıkarıyoruz ki tekrar sormadan arayüz güncel tutulsun
            showAppSnackBar(
                context, approve ? 'İstek onaylandı.' : 'İstek reddedildi.',
                color: approve ? Colors.green : Colors.grey,
            );
        } else {
            showAppSnackBar(context, result['message'], color: Colors.red);
        }
    }

    String _formatDate(String? raw) {
        if (raw == null) return '';
        final date = DateTime.parse(raw).toLocal();
        return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFAF7F2),
            appBar: AppBar(
                backgroundColor: const Color(0xFFFAF7F2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF1A237E)),
                title: const Text(
                    'Katılım İstekleri',
                    style: TextStyle(color: Color(0xFF1A237E), fontSize: 18),
                ),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _requests.isEmpty
                        ? const Center(
                            child: Text(
                                'Bekleyen katılım isteği yok.',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                        )
                        : RefreshIndicator(
                            onRefresh: _loadRequests,
                            child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _requests.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                    final r = _requests[i];
                                    final requestId = r['requestId'] as String;
                                    final isProcessing = _processingIds.contains(requestId);
                                    final displayName = r['displayName'] ?? '?';

                                    return Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                            children: [
                                                CircleAvatar(
                                                    radius: 22,
                                                    backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                                    child: Text(
                                                        displayName.isNotEmpty ? displayName[0] : '?',
                                                        style: const TextStyle(
                                                            color: Color(0xFF1A237E),
                                                            fontWeight: FontWeight.bold,
                                                        ),
                                                    ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                            Text(
                                                                displayName,
                                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                                _formatDate(r['requestedAt']),
                                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                                if (isProcessing)
                                                    const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                    )
                                                else ...[
                                                    IconButton(
                                                        onPressed: () => _respond(r, false),
                                                        icon: const Icon(Icons.close, color: Colors.red),
                                                        tooltip: 'Reddet',
                                                    ),
                                                    IconButton(
                                                        onPressed: () => _respond(r, true),
                                                        icon: const Icon(Icons.check_circle, color: Colors.green),
                                                        tooltip: 'Onayla',
                                                    ),
                                                ],
                                            ],
                                        ),
                                    );
                                },
                            ),
                        ),
        );
    }
}