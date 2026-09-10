using System.Collections.Concurrent;

namespace EtkinlikApp.Api.Services;

// dm'de "yazıyor..." göstergesi için - veritabanına yazmaya değmeyecek kadar geçici bir bilgi
// o yüzden migration/tablo açmak yerine hafızada (in-memory) tutuyoruz, singleton olarak kayıtlı
public class TypingIndicatorService
{
    // key: (yazan kullanıcı, kime yazdığı) -> son "yazıyorum" bildirimi ne zaman geldi
    private readonly ConcurrentDictionary<(Guid UserId, Guid OtherUserId), DateTime> _typingAt = new();

    // "yazıyor" sayılma süresi: polling aralığımız 4sn, bir tık pay bırakıyoruz
    private static readonly TimeSpan TypingTimeout = TimeSpan.FromSeconds(6);

    public void MarkTyping(Guid userId, Guid otherUserId)
    {
        _typingAt[(userId, otherUserId)] = DateTime.UtcNow;
    }

    public bool IsTyping(Guid userId, Guid otherUserId)
    {
        if (!_typingAt.TryGetValue((userId, otherUserId), out var lastTypedAt))
            return false;

        return DateTime.UtcNow - lastTypedAt < TypingTimeout;
    }
}
