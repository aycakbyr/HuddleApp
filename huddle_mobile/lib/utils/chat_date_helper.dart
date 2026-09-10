// sohbet ekranlarında (topluluk + dm) ortak kullanılan zaman/gün biçimlendirme yardımcıları
// DRY: aynı mantığı iki ayrı sohbet ekranında tekrar yazmak yerine tek yerden kullanıyoruz

String formatMessageTime(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
}

String formatDaySeparator(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(messageDay).inDays;

    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';

    const aylar = [
        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${dt.day} ${aylar[dt.month - 1]} ${dt.year}';
}

bool isSameDay(String isoA, String isoB) {
    final a = DateTime.parse(isoA).toLocal();
    final b = DateTime.parse(isoB).toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
}
