import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../utils/snackbar_helper.dart';

// Kullanıcının oluşturduğu tüm etkinlikler için bekleyen katılım istekleri
class RequestsPage extends StatefulWidget {
    const RequestsPage({super.key});

    @override
    State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
    final _eventService = EventService();
    List<Map<String, dynamic>> _requests = [];
    bool _isLoading = true;
    String? _errorMessage;
    final Set<String> _processingIds = {};

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
            final requests = await _eventService.getMyPendingRequests();
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
        final participantId = request['participantId'] as String;
        setState(() => _processingIds.add(participantId));

        final result = await _eventService.respondToRequest(participantId, approve);

        if (!mounted) return;
        setState(() => _processingIds.remove(participantId));

        if (result['success'] == true) {
            setState(() => _requests.removeWhere((r) => r['participantId'] == participantId));
            showAppSnackBar(
                context, approve ? 'İstek onaylandı.' : 'İstek reddedildi.',
                color: approve ? Colors.green : Colors.grey
            );
        } else {
            showAppSnackBar(
                context, result['message'],
                color: Colors.red
            );
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
                    'İstekler',
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
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                    final r = _requests[i];
                                    final participantId = r['participantId'] as String;
                                    final isProcessing = _processingIds.contains(participantId);
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
                                                                '${r['eventTitle'] ?? ''}',
                                                                style: const TextStyle(fontSize: 12, color: Color(0xFF1A237E)),
                                                                overflow: TextOverflow.ellipsis,
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
