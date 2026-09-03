namespace EtkinlikApp.Core.Entities;

public class Message
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? EventId { get; set; }
    public Event? Event { get; set; } = null!;
    public Guid? CommunityId { get; set; }
    public Community? Community { get; set; }
    public Guid SenderId { get; set; }
    public User Sender { get; set;} = null!;
    public string Content { get; set; } = string.Empty; //Content → mesajın kendisi (yazılan metin)
    public DateTime SentAt { get; set; } = DateTime.UtcNow; //SentAt → gönderilme zamanı, yine otomatik dolduruluyor, tıpkı diğer CreatedAt/RequestedAt alanlarında yaptığımız gibi
}