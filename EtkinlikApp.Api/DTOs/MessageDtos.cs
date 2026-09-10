namespace EtkinlikApp.Api.DTOs;

public class SendMessageDto //sadece mesaj metni — gönderen kim, hangi topluluk gibi bilgileri zaten token'dan ve URL'den alıyoruz, client'ın söylemesine güvenmiyoruz
{
    public string Content { get; set; } = string.Empty;
    public bool IsAnnouncement { get; set; } = false;
}

public class MessageDto //listeleme yaparken bizim Flutter'a geri göndereceğimiz şekil Message entity'sini olduğu gibi göndermek yerine, gönderenin adını/fotoğrafını da düzleştirip (flatten) içine koyuyoruz ki Flutter ayrıca "bu SenderId'nin ismi ne" diye ayrı bir istek atmak zorunda kalmasın.
{
    public Guid Id { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }
    public Guid SenderId { get; set; }
    public string SenderDisplayName { get; set; } = string.Empty;
    public string? SenderProfilePictureUrl { get; set; }
    public bool IsAnnouncement { get; set; }
    public bool IsDeleted { get; set; }
    public bool IsRead { get; set; } //dm'de karşı taraf gördü mü (okundu tiki)
}

public class ConversationSummaryDto //sohbet sekmesindeki dm listesi
{
    public Guid OtherUserId { get; set; }
    public string OtherUserDisplayName { get; set; } = string.Empty;
    public string? OtherUserProfilePictureUrl { get; set; }
    public string LastMessageContent { get; set; } = string.Empty;
    public bool LastMessageIsDeleted { get; set; }
    public DateTime LastMessageSentAt { get; set; }
    public bool IsLastMessageMine { get; set; } //true ise son mesajı ben göndermişim
    public int UnreadCount { get; set; } // bu kullanıcıdan gelen okunmamış mesaj sayısı
}