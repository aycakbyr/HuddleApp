namespace EtkinlikApp.Api.DTOs;

public class SendMessageDto //sadece mesaj metni — gönderen kim, hangi topluluk gibi bilgileri zaten token'dan ve URL'den alıyoruz, client'ın söylemesine güvenmiyoruz
{
    public string Content { get; set; } = string.Empty;
}

public class MessageDto //listeleme yaparken bizim Flutter'a geri göndereceğimiz şekil Message entity'sini olduğu gibi göndermek yerine, gönderenin adını/fotoğrafını da düzleştirip (flatten) içine koyuyoruz ki Flutter ayrıca "bu SenderId'nin ismi ne" diye ayrı bir istek atmak zorunda kalmasın.
{
    public Guid Id { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }
    public Guid SenderId { get; set; }
    public string SenderDisplayName { get; set; } = string.Empty;
    public string? SenderProfilePictureUrl { get; set; }
}